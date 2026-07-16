/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNDRIVEN */

// TODO: Error signal for malformed instructions from executor rather
//       than decoder
// FIXME: JALR requires that funct3 is zero'd

module Top (
    input i_clock,
    input i_nreset,
    output wire                o_ahb_write,
    output wire [31:0]         o_ahb_addr,
    output transfer_size       o_ahb_size,
    output transfer_burst      o_ahb_burst,
    output transfer_protection o_ahb_prot,
    output transfer_kind       o_ahb_trans,
    output logic               o_ahb_mastlock,
    output logic               o_ahb_ready_mst,
    output wire [31:0]         o_ahb_wdata,
    input logic [31:0]         i_ahb_rdata,
    input logic                i_ahb_ready_slv,
    input transfer_response    i_ahb_resp
);
    ahb_lite_out ahb_o();
    ahb_lite_in ahb_i();
    bus_control master();

    // External bus common signals
    assign o_ahb_write     = ahb_o.write;
    assign o_ahb_addr      = ahb_o.addr; 
    assign o_ahb_size      = ahb_o.size;
    assign o_ahb_burst     = ahb_o.burst;
    assign o_ahb_prot      = ahb_o.prot;
    assign o_ahb_trans     = ahb_o.trans;
    assign o_ahb_mastlock  = ahb_o.mastlock;
    assign o_ahb_ready_mst = ahb_o.ready;
    assign o_ahb_wdata     = ahb_o.wdata;

    assign ahb_i.rdata = i_ahb_rdata;
    assign ahb_i.ready = i_ahb_ready_slv; 
    assign ahb_i.resp  = i_ahb_resp; 

    ControlUnit cu (
        .clock(i_clock),
        .nreset(i_nreset),
        .bus(master)
    );

    BusController bus_control(
        .clk(i_clock),
        .rst(i_nreset),
        .bus(master),
        .ahb_o(ahb_o),
        .ahb_i(ahb_i)
    );

    // Allow the simulation to access specific internal signals
    `define EXPOSE_SIGNAL(ARGS, VALUE, NAME, TYPE) \
        function TYPE NAME ARGS;                   \
            /* verilator public */                 \
            begin                                  \
                NAME = VALUE;                      \
            end                                    \
        endfunction                         
    
    `EXPOSE_SIGNAL(
        (), cu.fetch_out.data.instruction, sig_instruction, bit[31:0]
    );
    `EXPOSE_SIGNAL(
        (), cu.pc, sig_pc, bit[31:0]
    );
    `EXPOSE_SIGNAL(
        (input [3:0] i), cu.register_file.x[i], sig_register, bit[31:0]
    );

    task write_sig_register (input [3:0] i, input [31:0] value); 
        /* verilator public */
        if (i > 0)
            cu.register_file.x[i] = value;
    endtask
endmodule

