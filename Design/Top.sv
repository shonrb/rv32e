/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */
module Top (
    input clock,
    input reset,
    output[31:0] in_addr,
    input[31:0] in_read
);

logic start;
logic write;
logic [31:0] addr;
logic [31:0] write_data;
logic [31:0] read_data;
transfer_response response;
logic ready;

logic [AHB_SLAVE_COUNT-1:0] sel;
bus_slv_in conn_in;
bus_slv_out conn_out[AHB_SLAVE_COUNT];

BusControl bus_control(
    .clk(clock),
    .rst(reset),
    .start(start),
    .write(write),
    .addr(addr),
    .write_data(write_data),
    .read_data(read_data),
    .response(response),
    .ready(ready),
    .sel(sel),
    .slv_in(conn_in),
    .slv_out(conn_out)
);

BusNoSlave bus_nonexistent(
    .sel(sel[0]),
    .in(conn_in),
    .out(conn_out[0])
);

logic[31:0] x [16] = '{default: '0};
logic[31:0] pc = 0;
logic[31:0] instruction = 0;

logic[6:0] opcode;
logic[6:0] funct7;
logic[4:0] rs2;
logic[4:0] rs1;
logic[4:0] rd;
logic[2:0] funct3;
logic[11:0] imm_11_0;
logic[6:0] imm_11_5;
logic[4:0] imm_4_0;

assign opcode = instruction[6:0];

always @(posedge clock) begin
    $display("Test");
end

endmodule

