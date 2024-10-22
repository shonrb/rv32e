`include "Common.svh"

module Fetch (
    input clock, 
    input reset, 
    input [31:0] pc,
    bus_master.out bus,
    skid_buffer_port.downstream decoder
);
    enum {
        IDLE, 
        WAITING
    } state;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            `LOG(("Resetting fetch"));
            state <= IDLE;
        end else begin
            // TODO: This initiates a new NONSEQ transfer for each instruction.
            // Should ideally use bursts with an i-cache
            case (state)
            IDLE: begin 
                `LOG(("No fetch in progress..."));
                if (bus.ready && decoder.ready) begin
                    `LOG(("Starting a fetch..."));
                    bus.address <= pc;
                    bus.write <= 0;
                    bus.start <= 1;
                    state <= WAITING;
                end else if (!bus.ready) begin
                    `LOG(("...Bus is busy"));
                end else begin
                    `LOG(("...Decoder is busy"));
                end
            end
            WAITING: begin 
                `LOG(("Fetch in progress..."));
                if (bus.ready && bus.active) begin
                    `LOG(("...Got a reply from bus..."));
                    if (bus.response == RESP_ERROR) begin
                        `LOG(("...Bus responded with error"));
                        decoder.valid <= 0;
                    end else begin 
                        `LOG(("...Bus replied with %d", bus.read_data));
                        bus.start <= 0;
                        state <= IDLE;
                        decoder.valid <= 1;
                        decoder.data <= bus.read_data;
                    end
                end else if (!bus.ready) begin
                    `LOG(("...Bus isn't ready yet"));
                end else begin
                    `LOG(("...Bus hasn't started transaction yet"));
                end
            end
            endcase
        end
    end
endmodule

