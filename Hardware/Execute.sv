typedef enum {
    EXECUTE_IDLE
} execute_state;

interface execute_port;
    logic set_pc;
    logic [31:0] new_pc;

    modport back  (output set_pc, new_pc);
    modport front (input  set_pc, new_pc);
endinterface

module ExecuteUnit (
    input clock, 
    input nreset, 
    skid_buffer_port.upstream decoder,
    reg_access_executor.front register_file,
    bus_master.front bus,
    execute_port.back control_unit
);
    decoded inst;
    assign inst = decoder.data;

    execute_state state;
    assign decoder.ready = state == EXECUTE_IDLE;

    assign register_file.write_loc = inst.destination;

    always_ff @(posedge clock or negedge nreset) begin
        if (!nreset) begin
            `LOG(("Resetting execute unit"));
        end else begin
            if (decoder.valid) begin
                `LOG(("Got a decoded instruction"));
                execute();
            end else begin
                `LOG(("Didn't get anything from decoder"));
            end
        end
    end

    task execute;
        case (inst.instruction)
        INST_LUI: begin
            register_file.do_write <= 1;
            register_file.write_data <= inst.immediate;
        end
        INST_AUIPC: begin
            register_file.do_write <= 1;
            register_file.write_data <= inst.address + inst.immediate;
        end
        INST_JAL,
        INST_JALR,
        INST_ADDI,
        INST_SLTI,
        INST_SLTIU,
        INST_XORI,
        INST_ORI,
        INST_ANDI,
        INST_SLLI,
        INST_SRLI,
        INST_SRAI,
        INST_ADD,
        INST_SUB,
        INST_SLL,
        INST_SLT,
        INST_SLTU,
        INST_XOR,
        INST_SRL,
        INST_SRA,
        INST_OR,
        INST_AND,
        INST_BEQ,
        INST_BNE,
        INST_BLT,
        INST_BGE,
        INST_BLTU,
        INST_BGEU,
        INST_LB,
        INST_LH,
        INST_LW,
        INST_LBU,
        INST_LHU,
        INST_SB,
        INST_SH,
        INST_SW, 
        INST_NOP: begin 
           register_file.do_write <= 0; 
        end
        endcase 
    endtask
endmodule

