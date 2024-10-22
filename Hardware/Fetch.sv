
module Fetch (
    input clock, 
    input reset, 
    input [31:0] pc,
    bus_master.out bus,
    skid_buffer_port.downstream decoder
);
    enum {
        IDLE,
        NEED, 
        WAITING
    } state;

    logic [31:0] reh;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            state <= NEED;
        end else begin
            // TODO: This initiates a new NONSEQ transfer for each instruction.
            // Should ideally use bursts with an i-cache
            $display("We have %d", decoder.data);
            case (state)
            IDLE: begin
                $display("No intruction needed");
                if (decoder.ready)
                    state <= NEED;
            end
            NEED: if (bus.ready) begin
                $display("We need an instruction");
                bus.address <= pc;
                bus.write <= 0;
                bus.start <= 1;
                state <= WAITING;
            end
            WAITING: begin 
                $display("We're waiting for an instruction");
                if (bus.ready && bus.active) begin
                    $display("... And got one");
                    if (bus.response == RESP_ERROR) begin
                        $error("Bus responded with error during instruction fetch");
                    end else begin 
                        $display("Bus contains %d", bus.read_data);
                        bus.start <= 0;
                        state <= IDLE;
                        decoder.valid <= 1;
                        decoder.data <= bus.read_data;
                        reh <= bus.read_data;
                    end
                end
            end
            endcase
        end
    end

 

endmodule

