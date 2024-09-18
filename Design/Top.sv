/* verilator lint_off UNUSEDSIGNAL */
module Top (
    input clock,
    input reset
);

always @(posedge clock) begin
    $display("Test");
end

endmodule
