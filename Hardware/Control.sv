typedef enum {
    FETCH_IDLE,
    FETCH_NEED,
    FETCH_WAITING
} fetch_status;

typedef enum {
    EXECUTE_IDLE,
    EXECUTE_STARTING,
    EXECUTE_NEED
} execute_status;

module Control (
    input clock,
    input reset,
    bus_master.out bus
);

    logic [31:0] x [16];
    logic [31:0] pc;

    instruction_format inst();
    Decoder decoder(.inst(inst));

    skid_buffer_port #(.T(logic[31:0])) fetch_out(); 
    skid_buffer_port #(.T(logic[31:0])) decode_in(); 
    SkidBuffer       #(.T(logic[31:0])) fetch_to_decode(
        .clock(clock), .reset(reset), .up(fetch_out), .down(decode_in)
    );

    Fetch fetch(
        .clock(clock),
        .reset(reset),
        .pc(pc),
        .bus(bus),
        .decoder(fetch_out)
    );

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            x <= '{default: 0};
            pc <= 0;
        end else begin
            
        end
    end
endmodule

