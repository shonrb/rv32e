`include "Common.svh"

module FetchUnit (
    input clock, 
    input reset, 
    input [31:0] pc,
    output logic increment,
    bus_master.out bus,
    skid_buffer_port.downstream to_decode
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
                if (bus.available && bus.ready && to_decode.ready) begin
                    `LOG(("...Starting fetch at address (%d)", pc));
                    bus.address <= pc;
                    bus.write <= 0;
                    bus.trans <= BUS_TRANSFER_NONSEQ;
                    state <= WAITING;
                    increment <= 1;
                end else if (!bus.available) begin
                    `LOG(("...Bus already has a transaction in progress"));
                end else if (!bus.ready) begin
                    `LOG(("...Device on bus is busy"));
                end else begin
                    `LOG(("...Decoder is busy"));
                end
            end
            WAITING: begin 
                increment <= 0;
                `LOG(("Fetch in progress..."));
                if (bus.ready) begin
                    `LOG(("...Got a reply from bus..."));
                    if (bus.response == RESP_ERROR) begin
                        `LOG(("...Bus responded with error"));
                        to_decode.valid <= 0;
                    end else begin 
                        `LOG(("...Bus replied with (%d)", bus.read_data));
                        bus.trans <= BUS_TRANSFER_IDLE;
                        to_decode.valid <= 1;
                        to_decode.data <= bus.read_data;
                        state <= IDLE;
                    end
                end else begin
                    `LOG(("...No reply yet"));
                end 
            end
            endcase
        end
    end
endmodule

