typedef struct {
    logic [6:0]  opcode;
    logic [6:0]  funct7;
    logic [4:0]  rs2;
    logic [4:0]  rs1;
    logic [4:0]  rd;
    logic [2:0]  funct3;
logic [31:0] immediate;
} instruction_split;

function [6:0] split_opcode(input [31:0] encoded);
    return encoded[6:0];
endfunction

function [6:0] split_funct7(input [31:0] encoded);
    return encoded[31:25];
endfunction

function [2:0] split_funct3(input [31:0] encoded);
    return encoded[14:12];
endfunction

function [4:0] split_rs1(input [31:0] encoded);
    return encoded[19:15];
endfunction

function [4:0] split_rs2(input [31:0] encoded);
    return encoded[24:20];
endfunction

function [4:0] split_rd(input [31:0] encoded);
    return encoded[11:7];
endfunction

function instruction_split split_r_type(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    split.funct3 = split_funct3(encoded);
    split.funct7 = split_funct7(encoded);
    split.rs1    = split_rs1(encoded);
    split.rs2    = split_rs2(encoded);
    split.rd     = split_rd(encoded);

    return split;
end
endfunction

function instruction_split split_shift_imm(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    split.funct3 = split_funct3(encoded);
    split.funct7 = split_funct7(encoded);
    split.rs1    = split_rs1(encoded);
    split.rd     = split_rd(encoded);

    split.immediate[4:0] = split_rs2(encoded);

    return split;
end
endfunction

function instruction_split split_i_type(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    split.funct3 = split_funct3(encoded);
    split.rs1    = split_rs1(encoded);
    split.rd     = split_rd(encoded);

    split.immediate[31:11] = {21{encoded[31]}};
    split.immediate[10:0]  = encoded[30:20];

    return split;
end
endfunction

function instruction_split split_s_type(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    split.funct3 = split_funct3(encoded);
    split.rs1    = split_rs1(encoded);
    split.rs2    = split_rs2(encoded);

    split.immediate[31:11] = {21{encoded[31]}};
    split.immediate[10:5]  = encoded[30:25];
    split.immediate[4:0]   = encoded[11:7];

    return split;
end
endfunction

function instruction_split split_b_type(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    split.funct3 = split_funct3(encoded);
    split.rs1    = split_rs1(encoded);
    split.rs2    = split_rs2(encoded);

    split.immediate[31:12] = {20{encoded[31]}};
    split.immediate[11]    = encoded[7];
    split.immediate[10:5]  = encoded[30:25];
    split.immediate[4:1]   = encoded[11:8];
    split.immediate[0]     = 0;

    return split;
end
endfunction

function instruction_split split_u_type(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    split.rd     = split_rd(encoded);

    split.immediate[31:12] = encoded[31:12];
    split.immediate[11:0]  = 0;

    return split;
end
endfunction

function instruction_split split_j_type(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    split.rd     = split_rd(encoded);

    split.immediate[31:20] = {12{encoded[31]}};
    split.immediate[19:12] = encoded[19:12];
    split.immediate[11]    = encoded[20];
    split.immediate[10:1]  = encoded[30:21];
    split.immediate[0]     = 0;

    return split;
end
endfunction

function instruction_split split_noop(input [31:0] encoded);
begin
    instruction_split split;
    split.opcode = split_opcode(encoded);
    return split;
end
endfunction

function instruction_split split_instruction(input [31:0] encoded);
begin
    logic [6:0] opcode;
    logic [2:0] funct3;

    opcode = split_opcode(encoded);
    funct3 = split_funct3(encoded);

    case (opcode)
    OPCODE_LUI,           
    OPCODE_AUIPC:      
        return split_u_type(encoded);
    OPCODE_JAL:           
        return split_j_type(encoded);
    OPCODE_JALR:          
        return split_i_type(encoded);
    OPCODE_SOME_OP_IMM:   
        case (funct3)
        OP_IMM_SLLI,
        OP_IMM_SOME_SHIFT_R:
            return split_shift_imm(encoded);
        default:
            return split_i_type(encoded);
        endcase 
    OPCODE_SOME_OP_REG:
        return split_r_type(encoded);
    OPCODE_SOME_BRANCH: 
        return split_b_type(encoded);
    OPCODE_SOME_LOAD:
        return split_i_type(encoded);
    OPCODE_SOME_STORE:    
        return split_s_type(encoded);
    OPCODE_SOME_MISC_MEM, 
    OPCODE_SOME_SYSTEM:
        return split_noop(encoded);
    default:            
        return split_noop(encoded); 
    endcase 
end
endfunction

interface decoder_port;
    logic flush;
    
    modport front (output flush);
    modport back  (output flush);
endinterface 

module DecodeUnit (
    input clock,
    input nreset,
    skid_buffer_port.upstream fetcher, 
    skid_buffer_port.downstream executor,
    reg_access_decoder.front register_file,
    decoder_port.back control_unit
);
    decoded out;
    assign out = executor.data;

    // Individual signal parts
    instruction_split split;
    assign split = split_instruction(fetcher.data.instruction);

    // Error signalling
    logic error;
    logic has_decoded;
    logic can_decode;

    always_comb begin
        // Decode only when both sides are ready and there are no unhandled errors
        fetcher.ready  = !error && executor.ready;
        executor.valid = !error && fetcher.valid && has_decoded;
        can_decode     = !error && fetcher.valid && executor.ready;

        executor.data.pc          = fetcher.data.address;
        executor.data.destination = split.rd[3:0];
        executor.data.immediate   = split.immediate;
        executor.data.opcode      = split.opcode;
        executor.data.funct3      = split.funct3;
        executor.data.funct7      = split.funct7;

        register_file.read_loc_1 = split.rs1[3:0];
        register_file.read_loc_2 = split.rs2[3:0];
    end

    always_ff @(posedge clock or negedge nreset) begin
        if (!nreset || control_unit.flush) begin
            `LOG(("Resetting decoder"));
            error <= 0;
            has_decoded <= 0;
        end else begin
            if (can_decode) begin
                has_decoded <= 1;
                `LOG((
                    "Decoder can proceed, got %s at 0x%h", 
                    show_instruction(split),
                    fetcher.data.address
                ));
                if (split.rs1 > 15)
                    error <= 1;
                if (split.rs2 > 15)
                    error <= 1;
                if (split.rd > 15)
                    error <= 1;
                if (split.opcode == OPCODE_JALR && split.funct3 != 'b000)
                    error <= 1;
            end else begin
                has_decoded <= 0;
                `LOG(("Decoder can not proceed..."));
                if (error)
                    `LOG(("...because of unhandled errors"));
                if (!fetcher.valid)
                    `LOG(("...because nothing was received from fetch"));
                if (!executor.ready)
                    `LOG(("...because execute is busy"));
            end
        end
    end
endmodule

