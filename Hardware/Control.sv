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
    logic [31:0] instruction;
    logic [31:0] address;
} fetched;

typedef struct {
    instruction_kind instruction;
    logic [31:0] immediate;
    logic [3:0] destination;
    logic [31:0] address;
} decoded;

module ControlUnit (
    input clock,
    input nreset,
    bus_master.front bus
);
    logic [31:0] pc;
    logic flush;

    reg_access_decoder decode_to_reg();
    reg_access_executor execute_to_reg();
    RegisterFile register_file(
        .clock(clock), 
        .nreset(nreset),
        .decoder(decode_to_reg),
        .executor(execute_to_reg)
    );

    skid_buffer_port #(.T(fetched)) fetch_out(); 
    skid_buffer_port #(.T(fetched)) decode_in(); 
    SkidBuffer       #(.T(fetched), .NAME("fetch->decode")) fetch_to_decode(
        .clock(clock), .nreset(nreset), .flush(flush), .up(fetch_out), .down(decode_in)
    );

    skid_buffer_port #(.T(decoded)) decode_out(); 
    skid_buffer_port #(.T(decoded)) execute_in(); 
    SkidBuffer       #(.T(decoded), .NAME("decode->execute")) decode_to_execute(
        .clock(clock), .nreset(nreset), .flush(flush), .up(decode_out), .down(execute_in)
    );

    fetcher_port cu_to_fetch();
    FetchUnit fetch(
        .clock(clock),
        .nreset(nreset),
        .pc(pc),
        .control_unit(cu_to_fetch),
        .bus(bus),
        .decoder(fetch_out)
    );

    decoder_port cu_to_decode();
    DecodeUnit decode(
        .clock(clock),
        .nreset(nreset),
        .control_unit(cu_to_decode),
        .fetcher(decode_in),
        .executor(decode_out),
        .register_file(decode_to_reg)
    );

    executor_port cu_to_execute();
    ExecuteUnit execute(
        .clock(clock),
        .nreset(nreset),
        .decoder(execute_in),
        .register_file(execute_to_reg),
        .bus(bus),
        .control_unit(cu_to_execute)
    );

    always_comb begin 
        flush = cu_to_execute.set_pc;
        cu_to_execute.flush = flush;
        cu_to_fetch.flush = flush;
        cu_to_decode.flush = flush;
    end

    always_ff @(posedge clock or negedge nreset) begin
        if (!nreset) begin
            `LOG(("Resetting control unit"));
            pc <= 0;
        end else begin
            `LOG(("PC is %0d", pc));
            if (cu_to_execute.set_pc) begin
                `LOG(("Jumping pc to %0d", cu_to_execute.new_pc));
                pc <= cu_to_execute.new_pc;
            end else if (cu_to_fetch.increment) begin
                `LOG(("Incrementing pc to %0d", pc + 4));
                pc <= pc + 4;
            end
            if (flush) begin
                `LOG(("Pipeline flushed"));
            end
        end
    end
endmodule

