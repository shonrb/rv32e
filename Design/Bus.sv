
typedef enum logic [1:0] {
    IDLE   = 'b00,
    BUSY   = 'b01,
    NONSEQ = 'b10,
    SEQ    = 'b11
} transfer_kind;

typedef enum logic [1:0] {
    HSIZE_8   = 'b000,
    HSIZE_16  = 'b001,
    HSIZE_32  = 'b010
} transfer_size;

typedef struct packed {
    logic cacheable;
    logic bufferable;
    logic privileged;
    logic data_or_opcode;
} transfer_protection;

typedef enum logic [2:0] {
    SINGLE = 'b000,
    INCR   = 'b001,
    WRAP4  = 'b010,
    INCR4  = 'b011,
    WRAP8  = 'b100,
    INCR8  = 'b101,
    WRAP16 = 'b110,
    INCR16 = 'b111
} transfer_burst;

typedef enum logic {
    RESP_OKAY = 0,
    RESP_ERROR = 1
} transfer_response;

typedef struct packed {
    logic [31:0] addr;
    logic write;
    transfer_size size;
    transfer_burst burst;
    transfer_protection prot;
    transfer_kind trans;
    logic mastlock;
    logic ready;
    logic [31:0] wdata;
} bus_slv_in;

typedef struct packed {
    logic [31:0] rdata;
    logic ready;
    transfer_response resp;
} bus_slv_out;

module BusControl (
    input clk,
    input rst,
    // Front facing
    input logic start,
    input logic write,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    output logic [31:0] read_data,
    output transfer_response response,
    output logic ready,
    // Slaves
    output logic [AHB_SLAVE_COUNT-1:0] sel,
    output bus_slv_in slv_in,
    input bus_slv_out slv_out[AHB_SLAVE_COUNT]
);
    logic[31:0] index;
    bus_slv_out mux_out;

    // TODO: Locked transfers, Sized transfers, bursts(?), protection(?)
    assign mux_out         = slv_out[index];
    assign ready           = mux_out.ready;
    assign response        = mux_out.resp;
    assign slv_in.addr     = addr;
    assign slv_in.write    = write;
    assign slv_in.size     = HSIZE_32;
    assign slv_in.burst    = SINGLE;
    assign slv_in.prot     = '{0, 0, 1, 1};
    assign slv_in.mastlock = 0;
    assign slv_in.wdata    = write_data;

    // Ensure memory map is ordered
    generate 
        localparam prev = 0;
        for (genvar i = 0; i < AHB_SLAVE_COUNT-1; i++) begin
            localparam bnd = AHB_ADDR_MAP[i];
            assert property (prev <= bnd);
            assign prev = bnd;
        end
    endgenerate

    always @(negedge rst) begin
        slv_in.trans <= IDLE;
        slv_in.ready <= 1;
        index <= 0;
        sel <= 1;
    end 

    always @(posedge clk) begin
        // Transfer states
        if (mux_out.ready) begin
            case (slv_in.trans)
            IDLE: begin
                if (start)
                    slv_in.trans <= NONSEQ;
            end
            BUSY: begin end
            NONSEQ: begin 
            if (!start)
                slv_in.trans <= IDLE;
            end
            SEQ: begin end
            endcase
        end

        // Address Decoding
        for (int i = 0; i < AHB_SLAVE_COUNT; i++) begin
            automatic int from 
                = (i == 0)              
                ? 32'b0       
                : 32'(AHB_ADDR_MAP[i-1]);
            automatic int to   
                = (i == AHB_SLAVE_COUNT-1) 
                ? 32'b1 << 32 
                : 32'(AHB_ADDR_MAP[i]);
            if (addr >= from && addr < to) begin
                sel <= 1 << i;
                index <= i;
            end
        end
    end
endmodule

module BusNoSlave (
    input sel,
    input bus_slv_in in,
    output bus_slv_out out
);
    assign out.resp = RESP_ERROR;
    assign out.ready = 1;
endmodule

