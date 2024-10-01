/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */
parameter AHB_SLAVE_COUNT = 2;
parameter [31:0] AHB_ADDR_MAP[AHB_SLAVE_COUNT-1] = '{
    2048
};

module Top (
    input clock,
    input reset,
    output wire                ext_n_write,
    output wire [31:0]         ext_n_addr,
    output transfer_size       ext_n_size,
    output transfer_burst      ext_n_burst,
    output transfer_protection ext_n_prot,
    output transfer_kind       ext_n_trans,
    output logic               ext_n_mastlock,
    output logic               ext_n_ready,
    output wire [31:0]         ext_n_wdata,
    output wire                ext_1_sel,
    input logic [31:0]         ext_1_rdata,
    input logic                ext_1_ready,
    input transfer_response    ext_1_resp
);
    logic [AHB_SLAVE_COUNT-1:0] sel;
    bus_slv_in conn_in();
    bus_slv_out conn_out[AHB_SLAVE_COUNT]();
    bus_master master();

    assign ext_n_write    = conn_in.write;
    assign ext_n_addr     = conn_in.addr; 
    assign ext_n_size     = conn_in.size;
    assign ext_n_burst    = conn_in.burst;
    assign ext_n_prot     = conn_in.prot;
    assign ext_n_trans    = conn_in.trans;
    assign ext_n_mastlock = conn_in.mastlock;
    assign ext_n_ready    = conn_in.ready;
    assign ext_n_wdata    = conn_in.wdata;
    
    assign ext_1_sel         = sel[0];
    assign conn_out[0].rdata = ext_1_rdata; 
    assign conn_out[0].ready = ext_1_ready; 
    assign conn_out[0].resp  = ext_1_resp; 

    CU cu (
        .clock(clock),
        .reset(reset),
        .bus(master)
    );

    BusControl bus_control(
        .clk(clock),
        .rst(reset),
        .bus(master),
        .sel(sel),
        .slv_in(conn_in),
        .slv_out(conn_out)
    );

    BusNoSlave no_slave(
        .clk(clock),
        .rst(reset),
        .sel(sel[1]),
        .in(conn_in),
        .out(conn_out[1])
    );

    always @(posedge clock) begin
        $display("Test");
    end
endmodule

