typedef enum {
    EXECUTE_IDLE
} execute_state;

interface execute_port;
    logic [31:0] pc;
    logic set_pc;
    logic [31:0] new_pc;

    modport back  (input  pc, output set_pc, new_pc);
    modport front (output pc, input  set_pc, new_pc);
endinterface

module ExecuteUnit (
    input clock, 
    input reset, 
    skid_buffer_port.upstream to_decode,
    reg_access_execute.out registers,
    bus_master.out bus,
    execute_port.back to_cu
);
    decoded inst;
    assign inst = to_decode.data;

    execute_state state;
    assign to_decode.ready = state == EXECUTE_IDLE;

    assign registers.write_loc = inst.destination;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            `LOG(("Resetting execute unit"));
        end else begin
            if (to_decode.valid) begin
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
            registers.do_write <= 1;
            registers.write_data <= inst.immediate;
        end
        INST_AUIPC: begin
            registers.do_write <= 1;
            registers.write_data <= to_cu.pc + inst.immediate;
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
           registers.do_write <= 0; 
        end
        endcase 
    endtask
endmodule

