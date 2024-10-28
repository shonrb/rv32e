`include "Show.svh"

bit logging;

task set_logging(input bit b);
    /* verilator public */
    assign logging = b;
endtask

function string reset;
    reset = {8'h1b, "[0m"};
endfunction

function string colour_file(input string file);
    case (file)
    "Hardware/Control.sv" : colour_file = {8'h1b, "[31m"};
    "Hardware/Fetch.sv"   : colour_file = {8'h1b, "[32m"};
    "Hardware/Bus.sv"     : colour_file = {8'h1b, "[33m"};
    "Hardware/Skid.sv"    : colour_file = {8'h1b, "[34m"};
    "Hardware/Execute.sv" : colour_file = {8'h1b, "[35m"};
    "Hardware/Decode.sv"  : colour_file = {8'h1b, "[36m"};
    default               : colour_file = reset();
    endcase
endfunction

task log_inner(input string ctx, input string str);
    if (logging) begin
        $display("%s  (%s) %s%s", colour_file(ctx), ctx, str, reset());
    end
endtask 

function string disassemble(input [31:0] inst);
/* verilator public */
    return show_instruction(split_instruction(inst));
endfunction

