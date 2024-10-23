
typedef enum [6:0] {
    OPCODE_LUI           = 'b0110111,
    OPCODE_AUIPC         = 'b0010111,
    OPCODE_JAL           = 'b1101111,
    OPCODE_JALR          = 'b1100111,
    OPCODE_SOME_OP_IMM   = 'b0010011,
    OPCODE_SOME_OP_REG   = 'b0110011,
    OPCODE_SOME_BRANCH   = 'b1100011,
    OPCODE_SOME_LOAD     = 'b0000011,
    OPCODE_SOME_STORE    = 'b0100011,
    OPCODE_SOME_MISC_MEM = 'b0001111,
    OPCODE_SOME_SYSTEM   = 'b1110011
} opcode_field;

typedef enum [2:0] {
    OP_IMM_ADDI         = 'b000,
    OP_IMM_SLTI         = 'b010,
    OP_IMM_SLTIU        = 'b011,
    OP_IMM_XORI         = 'b100,
    OP_IMM_ORI          = 'b110,
    OP_IMM_ANDI         = 'b111,
    OP_IMM_SLLI         = 'b001,
    OP_IMM_SOME_SHIFT_R = 'b101
} funct3_op_imm;

typedef enum [2:0] {
    OP_REG_SOME_ARITH   = 'b000,
    OP_REG_SLL          = 'b001,
    OP_REG_SLT          = 'b010,
    OP_REG_SLTU         = 'b011,
    OP_REG_XOR          = 'b100,
    OP_REG_SOME_SHIFT_R = 'b101,
    OP_REG_OR           = 'b110,
    OP_REG_AND          = 'b111
} funct3_op_reg;

typedef enum [6:0] {
    SHIFT_R_LOGIC = 'b0000000,
    SHIFT_R_ARITH = 'b0100000
} funct7_r_shift_kind;

typedef enum [6:0] {
    ARITH_REG_ADD = 'b0000000,
    ARITH_REG_SUB = 'b0100000
} funct7_reg_arith;

typedef enum [2:0] {
    BRANCH_EQ                     = 'b000,
    BRANCH_NOT_EQ                 = 'b001,
    BRANCH_LESS_THAN_SIGNED       = 'b100,
    BRANCH_GREATER_OR_EQ_SIGNED   = 'b101,
    BRANCH_LESS_THAN_UNSIGNED     = 'b110,
    BRANCH_GREATER_OR_EQ_UNSIGNED = 'b111
} funct3_branch_kind;

typedef enum [2:0] {
    LOAD_BYTE           = 'b000,
    LOAD_HALFWORD       = 'b001,
    LOAD_WORD           = 'b010,
    LOAD_BYTE_UPPER     = 'b100,
    LOAD_HALFWORD_UPPER = 'b101
} funct3_load;

typedef enum [2:0] {
    STORE_BYTE     = 'b000,
    STORE_HALFWORD = 'b001,
    STORE_WORD     = 'b010
} funct3_store;

interface instruction_split;
    logic [31:0] encoded;
    logic [6:0]  opcode;
    logic [6:0]  funct7;
    logic [4:0]  rs2;
    logic [4:0]  rs1;
    logic [4:0]  rd;
    logic [2:0]  funct3;

    logic [31:0] i_immediate;
    logic [31:0] s_immediate;
    logic [31:0] b_immediate;
    logic [31:0] u_immediate;
    logic [31:0] j_immediate;
    logic [31:0] shamt;

    modport back (
        input encoded,
        output 
            opcode, funct7, rs2, rs1, rd, funct3, 
            i_immediate, s_immediate, b_immediate, 
            u_immediate, j_immediate, shamt
    );
endinterface

module Splitter (instruction_split.back split);
    assign split.opcode  = split.encoded[6:0]; 
    assign split.funct7  = split.encoded[31:25];
    assign split.rs2     = split.encoded[24:20];
    assign split.rs1     = split.encoded[19:15];
    assign split.funct3  = split.encoded[14:12];
    assign split.rd      = split.encoded[11:7];

    assign split.i_immediate[31:11] = {21{split.encoded[31]}};
    assign split.i_immediate[10:0]  = split.encoded[30:20];

    assign split.s_immediate[31:11] = {21{split.encoded[31]}};
    assign split.s_immediate[10:5]  = split.encoded[30:25];
    assign split.s_immediate[4:0]   = split.encoded[11:7];

    assign split.b_immediate[31:12] = {20{split.encoded[31]}};
    assign split.b_immediate[11]    = split.encoded[7];
    assign split.b_immediate[10:5]  = split.encoded[30:25];
    assign split.b_immediate[4:1]   = split.encoded[11:8];
    assign split.b_immediate[0]     = 0;

    assign split.u_immediate[31:12] = split.encoded[31:12];
    assign split.u_immediate[11:0]  = 0;

    assign split.j_immediate[31:20] = {12{split.encoded[31]}};
    assign split.j_immediate[19:12] = split.encoded[19:12];
    assign split.j_immediate[11]    = split.encoded[20];
    assign split.j_immediate[10:1]  = split.encoded[30:21];
    assign split.j_immediate[0]     = 0;

    assign split.shamt[4:0]         = split.encoded[24:20];
    assign split.shamt[31:5]        = 0;
endmodule

module DecodeUnit (
    input clock,
    input reset,
    skid_buffer_port.upstream to_fetch, 
    skid_buffer_port.downstream to_execute
);
    // Individual signal parts
    instruction_split split();
    Splitter splitter(.split(split));
    assign split.encoded = to_fetch.data;

    // Error signalling
    logic valid;

    // Decode only when either side is ready and there are no errors
    assign to_fetch.ready   = to_execute.ready && valid;
    assign to_execute.valid = to_fetch.valid && valid;
    logic can_decode        = to_fetch.ready && to_execute.valid;



    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            `LOG(("Resetting decoder"));
            valid <= 1;
        end else begin
            if (can_decode) begin
                `LOG(("Decoder can proceed"));
                decode(); 
            end else begin
                `LOG(("Decoder can not proceed..."));
                if (!valid)
                    `LOG(("...because of unhandled errors"));
                if (!to_fetch.valid)
                    `LOG(("...because nothing was received from fetch"));
                if (!to_execute.ready)
                    `LOG(("...because execute is busy"));
            end
        end
    end

    // Error helpers: deassert valid and log error msg
    `define ERROR(FMT) \
        begin          \
            error();   \
            `LOG(FMT); \
        end

    `define ERROR_BAD_FUNCT7() \
        `ERROR(("bad"))

    task decode; 
        case (split.opcode)
        OPCODE_LUI:           u_instruction(INST_LUI);
        OPCODE_AUIPC:         u_instruction(INST_AUIPC);
        OPCODE_JAL:           j_instruction(INST_JAL);
        OPCODE_JALR:          j_instruction(INST_JALR);
        OPCODE_SOME_OP_IMM:   decode_op_imm();
        OPCODE_SOME_OP_REG:   decode_op_reg();
        OPCODE_SOME_BRANCH:   decode_branch();
        OPCODE_SOME_LOAD:     decode_load();
        OPCODE_SOME_STORE:    decode_store();
        OPCODE_SOME_MISC_MEM: no_op();
        OPCODE_SOME_SYSTEM:   no_op();
        default:              `ERROR(("err: bad opcode: (0b%b)", split.opcode))
        endcase
    endtask

    task decode_op_imm;
        case (split.funct3)
        OP_IMM_SLTI:  i_instruction(INST_SLTI);
        OP_IMM_SLTIU: i_instruction(INST_SLTIU);
        OP_IMM_XORI:  i_instruction(INST_XORI);
        OP_IMM_ORI:   i_instruction(INST_ORI);
        OP_IMM_ANDI:  i_instruction(INST_ANDI);
        OP_IMM_ADDI:  i_instruction(INST_ADDI);
        OP_IMM_SLLI:  begin
            if (split.funct7 != 0) 
                `ERROR_BAD_FUNCT7()
            else
                shift_imm_instruction(INST_SLLI);
        end 
        OP_IMM_SOME_SHIFT_R: 
            case (split.funct7)
            SHIFT_R_LOGIC: shift_imm_instruction(INST_SRLI);
            SHIFT_R_ARITH: shift_imm_instruction(INST_SRAI);
            default:       `ERROR_BAD_FUNCT7()
            endcase
        endcase
    endtask

    task decode_op_reg;
    begin
        case (split.funct3)
        OP_REG_SLL:  r_instruction(INST_SLL);
        OP_REG_SLT:  r_instruction(INST_SLT);
        OP_REG_SLTU: r_instruction(INST_SLTU);
        OP_REG_XOR:  r_instruction(INST_XOR);
        OP_REG_OR:   r_instruction(INST_OR);
        OP_REG_AND:  r_instruction(INST_AND);
        OP_REG_SOME_ARITH: 
            case (split.funct7)
            ARITH_REG_ADD: r_instruction(INST_ADD);
            ARITH_REG_SUB: r_instruction(INST_SUB);
            default:       `ERROR_BAD_FUNCT7()
            endcase
        OP_REG_SOME_SHIFT_R: 
            case (split.funct7)
            SHIFT_R_LOGIC: r_instruction(INST_SRL);
            SHIFT_R_ARITH: r_instruction(INST_SRA);
            default:       `ERROR_BAD_FUNCT7()
            endcase
        endcase
    end
    endtask

    task decode_branch;
        case (split.funct3)
        BRANCH_EQ:                     b_instruction(INST_BEQ);
        BRANCH_NOT_EQ:                 b_instruction(INST_BNE);
        BRANCH_LESS_THAN_SIGNED:       b_instruction(INST_BLT);
        BRANCH_GREATER_OR_EQ_SIGNED:   b_instruction(INST_BGE);
        BRANCH_LESS_THAN_UNSIGNED:     b_instruction(INST_BLTU);
        BRANCH_GREATER_OR_EQ_UNSIGNED: b_instruction(INST_BGEU);
        default:                       error();
        endcase
    endtask

    task decode_load;
        case (split.funct3)
        LOAD_BYTE:           i_instruction(INST_LB);
        LOAD_HALFWORD:       i_instruction(INST_LH);
        LOAD_WORD:           i_instruction(INST_LW);
        LOAD_BYTE_UPPER:     i_instruction(INST_LBU);
        LOAD_HALFWORD_UPPER: i_instruction(INST_LHU);
        default:             error();
        endcase
    endtask

    task decode_store;
        case (split.funct3)
        STORE_BYTE:     s_instruction(INST_SB);
        STORE_HALFWORD: s_instruction(INST_SH);
        STORE_WORD:     s_instruction(INST_SW);
        default:        error();
        endcase
    endtask

    // Instruction formats
    task no_op;
        to_execute.data.instruction <= INST_NOP;
    endtask
    
    task r_instruction(input instruction_kind inst);
    begin
        to_execute.data.instruction <= inst;
        to_execute.data.destination <= split.rd;
        to_execute.data.operand_1   <= split.rs1;
        to_execute.data.operand_2   <= split.rs2;
        check_register(split.rd);
        check_register(split.rs1);
        check_register(split.rs2);
    end
    endtask

    task r_instruction_zeroed_funct7(input instruction_kind inst);
    begin
        if (split.funct7 == 0)
            r_instruction(inst);
        else 
            `ERROR_BAD_FUNCT7() 
    end
    endtask

    task i_instruction(input instruction_kind inst);
        immediate_with_rd_rs1(inst, split.i_immediate);
    endtask

    task s_instruction(input instruction_kind inst);
        immediate_with_rs1_rs2(inst, split.s_immediate);
    endtask

    task b_instruction(input instruction_kind inst);
        immediate_with_rs1_rs2(inst, split.b_immediate);
    endtask

    task u_instruction(input instruction_kind inst);
        immediate_with_rd(inst, split.u_immediate);
    endtask

    task j_instruction(input instruction_kind inst);
        immediate_with_rd(inst, split.j_immediate);
    endtask

    task shift_imm_instruction(input instruction_kind inst);
        immediate_with_rd_rs1(inst, split.shamt);
    endtask

    // General instruction formats for immediates

    task immediate_with_rd_rs1(input instruction_kind inst, input [31:0] imm);
    begin
        to_execute.data.instruction <= inst;
        to_execute.data.destination <= split.rd;
        to_execute.data.operand_1   <= split.rs1;
        to_execute.data.immediate   <= imm;
        check_register(split.rd);
        check_register(split.rs1);
    end
    endtask

    task immediate_with_rs1_rs2(input instruction_kind inst, input [31:0] imm);
    begin
        to_execute.data.instruction <= inst;
        to_execute.data.operand_1   <= split.rs1;
        to_execute.data.operand_2   <= split.rs2;
        to_execute.data.immediate   <= imm;
        check_register(split.rs1);
        check_register(split.rs2);
    end
    endtask

    task immediate_with_rd(input instruction_kind inst, input [31:0] imm);
    begin
        to_execute.data.instruction <= inst;
        to_execute.data.destination <= split.rd;
        to_execute.data.immediate   <= imm;
        check_register(split.rd);
    end
    endtask

    task check_register(input [4:0] num);
        if (num >= 16)
            error();
    endtask

    task error;
    begin
        valid <= 0;
    end
    endtask

    // assign to_fetch.ready = to_execute.ready;
    // assign to_execute.valid = to_fetch.valid;
endmodule

