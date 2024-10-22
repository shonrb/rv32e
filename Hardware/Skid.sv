`include "Common.svh"

interface skid_buffer_port #(type T);
    logic ready;
    logic valid;
    T data;

    modport upstream   (output ready, input  valid, data);
    modport downstream (input  ready, output valid, data);
endinterface

module SkidBuffer #(type T, string NAME) (
    input clock, 
    input reset,
    skid_buffer_port.upstream   up,
    skid_buffer_port.downstream down
);
    enum {
        STALLED,
        ACTIVE
    } state;

    T buffer;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            `LOG(("Resetting skid buffer \"%s\"", NAME));
            state <= ACTIVE;
            down.valid <= 0;
            up.ready <= 1;
        end else begin
            case (state) 
            ACTIVE: begin 
                if (down.ready) begin
                    // Pass the data down
                    down.data <= up.data;
                    down.valid <= up.valid;
                    up.ready <= 1;
                end else if (up.valid) begin
                    // We have data from upstream, but downstream 
                    // isn't ready for it. Store the data and stall.
                    up.ready <= 0;
                    down.valid <= 0;
                    buffer <= up.data;
                    state <= STALLED;
                end
            end
            STALLED: if (down.ready) begin
                // Down is ready again, pass the 
                // buffered data and resume.
                down.data <= buffer;
                down.valid <= 1;
                up.ready <= 1;
                state <= ACTIVE;
            end
            endcase
        end
    end
endmodule

