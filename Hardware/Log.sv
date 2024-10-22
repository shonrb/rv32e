bit logging;

task set_logging(input bit b);
    /* verilator public */
    assign logging = b;
endtask

task log_inner(input string ctx, input string str);
    if (logging) begin
        $display("  (%s) %s", ctx, str);
    end
endtask 

