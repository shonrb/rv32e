/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */

// TODO: Reduce clock cycles by doing some work on negative edges
// TODO: Error signal for malformed instructions from executor rather
//       than decoder

// Global parameters
parameter AHB_DEVICE_COUNT /* verilator public */ = 2;
parameter [31:0] AHB_ADDR_MAP[AHB_DEVICE_COUNT-1] /* verilator public */ = '{
    2048
};

module Top (
    input clock,
    input reset,
    output wire                ext_write,
    output wire [31:0]         ext_addr,
    output transfer_size       ext_size,
    output transfer_burst      ext_burst,
    output transfer_protection ext_prot,
    output transfer_kind       ext_trans,
    output logic               ext_mastlock,
    output logic               ext_ready_mst,
    output wire [31:0]         ext_wdata,
    output wire                ext_sel       [AHB_DEVICE_COUNT],
    input logic [31:0]         ext_rdata     [AHB_DEVICE_COUNT],
    input logic                ext_ready_slv [AHB_DEVICE_COUNT],
    input transfer_response    ext_resp      [AHB_DEVICE_COUNT]
);
    logic [AHB_DEVICE_COUNT-1:0] sel;
    bus_slv_in conn_in();
    bus_slv_out conn_out[AHB_DEVICE_COUNT]();
    bus_master master();

    // External bus common signals
    assign ext_write     = conn_in.write;
    assign ext_addr      = conn_in.addr; 
    assign ext_size      = conn_in.size;
    assign ext_burst     = conn_in.burst;
    assign ext_prot      = conn_in.prot;
    assign ext_trans     = conn_in.trans;
    assign ext_mastlock  = conn_in.mastlock;
    assign ext_ready_mst = conn_in.ready;
    assign ext_wdata     = conn_in.wdata;

    // External bus per device signals
    for (genvar i = 0; i < AHB_DEVICE_COUNT; i++) begin
        assign ext_sel[i]        = sel[i];
        assign conn_out[i].rdata = ext_rdata[i]; 
        assign conn_out[i].ready = ext_ready_slv[i]; 
        assign conn_out[i].resp  = ext_resp[i]; 
    end

    ControlUnit cu (
        .clock(clock),
        .reset(reset),
        .bus(master)
    );

    BusController bus_control(
        .clk(clock),
        .rst(reset),
        .bus(master),
        .sel(sel),
        .slv_in(conn_in),
        .slv_out(conn_out)
    );

    // Allow the simulation to access specific internal signals
    `define EXPOSE_SIGNAL(ARGS, VALUE, NAME, TYPE) \
        function TYPE NAME ARGS;                   \
            /* verilator public */                 \
            begin                                  \
                NAME = VALUE;                      \
            end                                    \
        endfunction                         
    
    `EXPOSE_SIGNAL((), cu.fetch_out.data, sig_instruction, bit[31:0]);
    `EXPOSE_SIGNAL(
        (input [3:0] i), cu.register_file.x[i], sig_register, bit[31:0]
    );
endmodule

