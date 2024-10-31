`include "Common.svh"

typedef enum {
    INST_LUI,
    INST_AUIPC,
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
    INST_NOP
} instruction_kind;

typedef struct {
    instruction_kind instruction;
    logic [31:0] immediate;
    logic [3:0] destination;
} decoded;

module ControlUnit (
    input clock,
    input reset,
    bus_master.out bus
);
    logic [31:0] pc;

    logic increment;

    reg_access_decode decode_to_reg();
    reg_access_execute execute_to_reg();

    RegisterFile register_file(
        .clock(clock), 
        .reset(reset),
        .decode(decode_to_reg),
        .execute(execute_to_reg)
    );

    skid_buffer_port #(.T(logic[31:0])) fetch_out(); 
    skid_buffer_port #(.T(logic[31:0])) decode_in(); 
    SkidBuffer       #(.T(logic[31:0]), .NAME("fetch->decode")) fetch_to_decode(
        .clock(clock), .reset(reset), .up(fetch_out), .down(decode_in)
    );

    skid_buffer_port #(.T(decoded)) decode_out(); 
    skid_buffer_port #(.T(decoded)) execute_in(); 
    SkidBuffer       #(.T(decoded), .NAME("decode->execute")) decode_to_execute(
        .clock(clock), .reset(reset), .up(decode_out), .down(execute_in)
    );

    FetchUnit fetch(
        .clock(clock),
        .reset(reset),
        .pc(pc),
        .increment(increment),
        .bus(bus),
        .to_decode(fetch_out)
    );

    DecodeUnit decode(
        .clock(clock),
        .reset(reset),
        .to_fetch(decode_in),
        .to_execute(decode_out),
        .registers(decode_to_reg)
    );

    ExecuteUnit execute(
        .clock(clock),
        .reset(reset),
        .to_decode(execute_in),
        .registers(execute_to_reg),
        .bus(bus)
    );

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            `LOG(("Resetting control unit"));
            pc <= 0;
        end else begin
            if (increment) begin
                `LOG(("Incrementing pc to (%d)", pc + 4));
                pc <= pc + 4;
            end
        end
    end
endmodule

