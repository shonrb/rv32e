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

/*
Locked bus interactions : 
interface bus_control;
    // syncing
    wire try_lock;
    wire have_lock;
    // master
    wire write;
    wire [31:0] addr;
    transfer_size size;
    transfer_burst burst;
    transfer_kind trans;
    logic ready;
    wire [31:0] wdata;
    // slave
    logic [31:0] rdata;
    logic ready;
    transfer_response resp;

    modport front (
        output try_lock, write, addr, size, burst, trans, ready, wdata,
        input have_lock, rdata, ready, resp
    );

    modport back (
        input try_lock, write, addr, size, burst, trans, ready, wdata,
        output have_lock, rdata, ready, resp
    );
endinterface
 
module BusController2 #(parameter INPUT_COUNT) (
    input clock,
    input nreset,
    bus_control.back inputs[INPUT_COUNT],
    // master
    output wire write,
    output wire [31:0] addr,
    output transfer_size size,
    output transfer_burst burst,
    output transfer_kind trans,
    output logic ready,
    output wire [31:0] wdata,
    // slave
    input logic [31:0] rdata,
    input logic ready,
    input transfer_response resp
);
    logic locker_idx[$clog2(INPUT_COUNT)-1 : 0];
    logic locked;

    always_comb begin
        if (locked) begin
            write <= inputs[locker_idx].write;
            addr <= inputs[locker_idx].addr;
            transfer_size <= inputs[locker_idx].transfer_size;
            transfer_burst <= inputs[locker_idx].transfer_burst;
            transfer_kind <= inputs[locker_idx].transfer_kind;
            ready <= inputs[locker_idx].ready;
            wdata <= inputs[locker_idx].wdata;
            inputs[locker_idx].rdata <= rdata;
            inputs[locker_idx].ready <= ready;
            inputs[locker_idx].resp <= resp;
        end else begin
            write <= 0;
            addr <= 0;
            transfer_size <= 0;
            transfer_burst <= 0;
            transfer_kind <= 0;
            ready <= 0;
            wdata <= 0;
            inputs[locker_idx].rdata <= 0;
            inputs[locker_idx].ready <= 0;
            inputs[locker_idx].resp <= 0;
        end
    end

    always_ff @(negedge clock or negedge reset) begin
        if (!locked) begin
            for (int i = 0; i < INPUT_COUNT; ++i) begin
                if (inputs[i].try_lock) begin
                    locked = 1;
                    locker_idx = i;
                end
            end
        end else if (!inputs[locker_idx].try_lock) begin
            locked = 0;
        end
    end
endmodule
*/

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

module BusController (
    input clk,
    input rst,
    // Front facing
    bus_master.back bus,
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

    transfer_kind trans;
    assign trans = bus.start ? BUS_TRANSFER_NONSEQ : BUS_TRANSFER_IDLE;
    assign bus.available = trans == BUS_TRANSFER_IDLE;

    // TODO: Locked transfers, Sized transfers, bursts(?), protection(??)
    assign slv_in.ready    = bus.ready;
    assign slv_in.addr     = bus.address;
    assign slv_in.write    = bus.write;
    assign slv_in.trans    = trans;
    assign slv_in.size     = HSIZE_32;
    assign slv_in.burst    = SINGLE;
    assign slv_in.prot     = '{0, 0, 1, 1};
    assign slv_in.mastlock = 0;
    assign slv_in.wdata    = bus.write_data;

    // Ensure memory map is ordered

    always_ff @(posedge clk or negedge rst) begin
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
                    `LOG(("Multiplexed address 0x%h to device %0d", bus.address, i));
                    sel <= 1 << i;
                    mux <= i;
                end
            end
        end
    end
endmodule

