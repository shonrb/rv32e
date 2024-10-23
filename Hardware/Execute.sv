module ExecuteUnit (
    input clock, 
    input reset, 
    skid_buffer_port.upstream to_decode, 
    bus_master.out bus
);
    decoded inst;
    assign inst = to_decode.data;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            `LOG(("Resetting execute unit"));
            to_decode.ready <= 1;
        end else begin
            if (to_decode.valid) begin
                `LOG(("Got a decoded instruction"));
                to_decode.ready <= 0; // While instruction is executing
            end else begin
                `LOG(("Didn't get anything from decoder"));
            end
        end
    end
endmodule
