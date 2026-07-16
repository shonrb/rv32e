`include "Common.svh"

typedef enum logic [1:0] {
    BUS_TRANSFER_IDLE   = 'b00,
    BUS_TRANSFER_BUSY   = 'b01,
    BUS_TRANSFER_NONSEQ = 'b10,
    BUS_TRANSFER_SEQ    = 'b11
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

interface ahb_lite_out;
    wire write;
    wire [31:0] addr;
    transfer_size size;
    transfer_burst burst;
    transfer_protection prot;
    transfer_kind trans;
    logic mastlock;
    logic ready;
    wire [31:0] wdata;
endinterface

interface ahb_lite_in;
    logic [31:0] rdata;
    logic ready;
    transfer_response resp;
endinterface

interface bus_control;
    logic start;
    logic available;
    logic write;
    logic [31:0] address;
    logic [31:0] write_data;
    wire [31:0] read_data;
    transfer_response response;
    logic ready;

    modport back (
        input write, address, write_data, start,
        output read_data, response, ready, available
    );

    modport front (
        output write, address, write_data, start,
        input read_data, response, ready, available
    );
endinterface

module BusController (
    input clk,
    input rst,
    // Internal
    bus_control.back bus,
    // External
    output ahb_lite_out ahb_o,
    input ahb_lite_in ahb_i
);
    transfer_kind trans;
    assign trans = bus.start ? BUS_TRANSFER_NONSEQ : BUS_TRANSFER_IDLE;
    assign bus.available = trans == BUS_TRANSFER_IDLE;

    // TODO: Locked transfers, Sized transfers, bursts(?), protection(??)
    assign ahb_o.ready    = bus.ready;
    assign ahb_o.addr     = bus.address;
    assign ahb_o.write    = bus.write;
    assign ahb_o.trans    = trans;
    assign ahb_o.size     = HSIZE_32;
    assign ahb_o.burst    = SINGLE;
    assign ahb_o.prot     = '{0, 0, 1, 1};
    assign ahb_o.mastlock = 0;
    assign ahb_o.wdata    = bus.write_data;

    assign bus.read_data = ahb_i.rdata;
    assign bus.ready     = ahb_i.ready;
    assign bus.response  = ahb_i.resp;

    // Ensure memory map is ordered

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            `LOG(("Resetting bus controller"));
        end else begin
            // TODO: probably some better state control
        end
    end
endmodule

