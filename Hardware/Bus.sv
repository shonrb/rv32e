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

interface bus_slv_in;
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

interface bus_slv_out;
    logic [31:0] rdata;
    logic ready;
    transfer_response resp;
endinterface

interface bus_master;
    transfer_kind trans;
    logic available;
    logic write;
    logic [31:0] address;
    logic [31:0] write_data;
    wire [31:0] read_data;
    transfer_response response;
    logic ready;

    modport in (
        input write, address, write_data, trans,
        output read_data, response, ready, available
    );

    modport out (
        output write, address, write_data, trans,
        input read_data, response, ready, available
    );
endinterface

module BusMux (
    input bus_slv_out out[AHB_DEVICE_COUNT],
    input logic [31:0] mux,
    output logic [31:0] rdata,
    output logic ready,
    output transfer_response resp
);
    logic [31:0] out_rdata[AHB_DEVICE_COUNT];
    logic out_ready[AHB_DEVICE_COUNT];
    transfer_response out_resp[AHB_DEVICE_COUNT];

    assign rdata = out_rdata[mux];
    assign ready = out_ready[mux];
    assign resp  = out_resp[mux];

    generate 
        genvar i;
        for (i = 0; i < AHB_DEVICE_COUNT; ++i) begin
            assign out_rdata[i] = out[i].rdata;
            assign out_ready[i] = out[i].ready;
            assign out_resp[i]  = out[i].resp;
        end
    endgenerate
endmodule

module BusControl (
    input clk,
    input rst,
    // Front facing
    bus_master.in bus,
    // Slaves
    output logic [AHB_DEVICE_COUNT-1:0] sel,
    output bus_slv_in slv_in,
    input bus_slv_out slv_out[AHB_DEVICE_COUNT]
);
    logic [31:0] mux;
    BusMux bus_mux (
        .out(slv_out),
        .mux(mux),
        .rdata(bus.read_data),
        .ready(bus.ready),
        .resp(bus.response)
    );

    // TODO: Locked transfers, Sized transfers, bursts(?), protection(??)
    assign slv_in.ready    = bus.ready;
    assign slv_in.addr     = bus.address;
    assign slv_in.write    = bus.write;
    assign slv_in.trans    = bus.trans;
    assign slv_in.size     = HSIZE_32;
    assign slv_in.burst    = SINGLE;
    assign slv_in.prot     = '{0, 0, 1, 1};
    assign slv_in.mastlock = 0;
    assign slv_in.wdata    = bus.write_data;

    assign bus.available = bus.trans == BUS_TRANSFER_IDLE;

    // Ensure memory map is ordered
    generate 
        localparam [31:0] prev = 0;
        for (genvar i = 0; i < AHB_DEVICE_COUNT-1; i++) begin
            localparam [31:0] bnd = AHB_ADDR_MAP[i];
            if (prev > bnd)
                $error("Memory map is not ordered");
            assign prev = bnd;
        end
    endgenerate

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            `LOG(("Resetting bus controller"));
            sel <= 1;
        end else begin
            // Address Decoding
            for (int i = 0; i < AHB_DEVICE_COUNT; i++) begin
                automatic int from 
                    = (i == 0)              
                    ? 32'b0
                    : 32'(AHB_ADDR_MAP[i-1]);
                automatic int to   
                    = (i == AHB_DEVICE_COUNT-1) 
                    ? 32'hFFFFFFFF 
                    : 32'(AHB_ADDR_MAP[i]) - 1;
                if (bus.address >= from && bus.address <= to) begin
                    `LOG(("Multiplexed address (%d) to device (%d)", bus.address, i));
                    sel <= 1 << i;
                    mux <= i;
                end
            end
        end
    end
endmodule

