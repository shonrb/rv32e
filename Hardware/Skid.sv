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
    input nreset,
    skid_buffer_port.upstream   up,
    skid_buffer_port.downstream down
);
    enum {
        STALLED,
        ACTIVE
    } state;

    T buffer;

    always_ff @(negedge clock or negedge nreset) begin
        if (!nreset) begin
            `LOG(("(%s) Resetting skid buffer", NAME));
            state <= ACTIVE;
            down.valid <= 0;
            up.ready <= 1;
        end else begin
            case (state) 
            ACTIVE: begin 
                `LOG(("(%s) Skid buffer is active...", NAME));
                if (down.ready) begin
                    // Pass the data down
                    down.data <= up.data;
                    down.valid <= up.valid;
                    up.ready <= 1;
                    if (up.valid)
                        `LOG(("(%s) ...passing value to downstream", NAME));
                    else 
                        `LOG(("(%s) ...downstream ready but upstream is not", NAME));
                end else if (up.valid) begin
                    // We have data from upstream, but downstream 
                    // isn't ready for it. Store the data and stall.
                    `LOG((
                        "(%s) ...%s, %s", 
                        NAME,
                        "upstream ready but downstream is not",
                        "buffering value and stalling"
                    ));
                    up.ready <= 0;
                    down.valid <= 0;
                    buffer <= up.data;
                    state <= STALLED;
                end else begin
                    `LOG(("(%s) ...neither side is ready", NAME));
                end
            end
            STALLED: begin
                `LOG(("(%s) skid buffer is stalled with value...", NAME));
                `LOG(("(%s) ...%p", NAME, buffer));
                if (down.ready) begin
                    // Down is ready again, pass the 
                    // buffered data and resume.
                    `LOG((
                        "(%s) ...%s, %s", 
                        NAME,
                        "downstream became ready",
                        "passing buffered value and ending stall"
                    ));
                    down.data <= buffer;
                    down.valid <= 1;
                    up.ready <= 1;
                    state <= ACTIVE;
                end
            end
            endcase
        end
    end
endmodule

