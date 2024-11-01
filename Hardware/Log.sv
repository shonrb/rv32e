`include "Disasm.svh"

bit logging;

task set_logging(input bit b);
    /* verilator public */
    assign logging = b;
endtask

task log_inner(input string file, input string str);
    if (logging) begin
        string code, name, colour, reset;
        case (file)
        "Hardware/Control.sv"  : begin code = "[31m"; name = "control unit";  end
        "Hardware/Fetch.sv"    : begin code = "[32m"; name = "fetcher";       end
        "Hardware/Bus.sv"      : begin code = "[33m"; name = "bus";           end
        "Hardware/Skid.sv"     : begin code = "[34m"; name = "skid buffer";   end
        "Hardware/Execute.sv"  : begin code = "[35m"; name = "executor";      end
        "Hardware/Decode.sv"   : begin code = "[36m"; name = "decoder";       end
        "Hardware/Register.sv" : begin code = "[91m"; name = "register file"; end
        default                : begin code = "[0m";  name = "?";             end
        endcase

        colour = {8'h1b, code};
        reset  = {8'h1b, "[0m"};

        $display("  %s(%s) %s%s", colour, name, str, reset);
    end
endtask 

function string disassemble(input [31:0] inst);
    /* verilator public */
    return show_instruction(split_instruction(inst));
endfunction

