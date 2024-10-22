typedef enum {
    FETCH_IDLE,
    FETCH_NEED,
    FETCH_WAITING
} fetch_status;

typedef enum {
    EXECUTE_IDLE,
    EXECUTE_STARTING,
    EXECUTE_NEED
} execute_status;

typedef struct {
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
} instruction_signals;

module Control (
    input clock,
    input reset,
    bus_master.out bus
);

    logic [31:0] x [16];
    logic [31:0] pc;

    skid_buffer_port #(.T(logic[31:0])) fetch_out(); 
    skid_buffer_port #(.T(logic[31:0])) decode_in(); 
    SkidBuffer       #(.T(logic[31:0])) fetch_to_decode(
        .clock(clock), .reset(reset), .up(fetch_out), .down(decode_in)
    );

    skid_buffer_port #(.T(instruction_signals)) decode_out(); 
    skid_buffer_port #(.T(instruction_signals)) execute_in(); 
    SkidBuffer       #(.T(instruction_signals)) decode_to_execute(
        .clock(clock), .reset(reset), .up(decode_out), .down(execute_in)
    );

    Fetch fetch(
        .clock(clock),
        .reset(reset),
        .pc(pc),
        .bus(bus),
        .decoder(fetch_out)
    );

    Decode decode(
        .fetch(decode_in),
        .execute(decode_out)
    );

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            x <= '{default: 0};
            pc <= 0;
        end else begin
            
        end
    end
endmodule

