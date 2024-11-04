`include "Common.svh"

interface fetcher_port;
    logic increment;
    logic flush;

    modport front (output flush, input  increment);
    modport back  (input  flush, output increment);
endinterface

module FetchUnit (
    input clock, 
    input nreset, 
    input [31:0] pc,
    fetcher_port.back control_unit,
    bus_master.front bus,
    skid_buffer_port.downstream decoder
);
    enum {
        IDLE, 
        WAITING
    } state;

    always_ff @(posedge clock or negedge nreset) begin
        if (!nreset || control_unit.flush) begin
            `LOG(("Resetting fetch"));
            state <= IDLE;
            control_unit.increment <= 0;
            decoder.valid <= 0;
        end else begin
            // TODO: This initiates a new NONSEQ transfer for each instruction.
            // Should ideally use bursts with an i-cache
            case (state)
            IDLE: begin 
                `LOG(("No fetch in progress..."));
                decoder.valid <= 0;
                if (bus.available && bus.ready && decoder.ready) begin
                    `LOG(("...Starting fetch at address 0x%h", pc));
                    bus.address <= pc;
                    decoder.data.address <= pc;
                    bus.write <= 0;
                    bus.start <= 1;
                    control_unit.increment <= 1;
                    state <= WAITING;
                end else if (!bus.available) begin
                    `LOG(("...Bus already has a transaction in progress"));
                end else if (!bus.ready) begin
                    `LOG(("...Device on bus is busy"));
                end else begin
                    `LOG(("...Decoder is busy"));
                end
            end
            WAITING: begin 
                control_unit.increment <= 0;
                `LOG(("Fetch in progress..."));
                if (bus.ready) begin
                    `LOG(("...Got a reply from bus..."));
                    if (bus.response == RESP_ERROR) begin
                        `LOG(("...Bus responded with error"));
                        decoder.valid <= 0;
                    end else begin 
                        `LOG(("...Bus replied with 0x%h", bus.read_data));
                        bus.start <= 0;
                        decoder.valid <= 1;
                        decoder.data.instruction <= bus.read_data;
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

