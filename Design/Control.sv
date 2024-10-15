typedef enum {
    FETCH_NEED,
    FETCH_WAITING,
    FETCH_READING
} fetch_status;

module Control (
    input clock,
    input reset,
    bus_master.out bus
);
    fetch_status fetch;    
    
    logic[31:0] fetch_inst;
    logic [31:0] x [16];
    logic [31:0] pc;
    logic [31:0] instruction; 

    instruction i();

    Splitter splitter(.inst(i));

    always_ff @(posedge clock or negedge reset) begin
        if (!reset) begin
            x <= '{default: 0};
            pc <= 0;
        end else begin
            $display("Checking if an instruction is needed");
            case (fetch)
            FETCH_NEED: if (bus.ready) begin
                $display("We need an instruction");
                bus.address <= pc;
                bus.write <= 0;
                bus.start <= 1;
                fetch <= FETCH_WAITING;
            end
            FETCH_WAITING: begin 
                bus.start <= 0;
                $display("We're waiting for an instruction");
                if (bus.ready) begin
                    $display("... And got one");
                    if (bus.response == RESP_ERROR) begin
                        $error("Bus responded with error during instruction fetch");
                    end else begin 
                        fetch <= FETCH_READING;
                    end
                end
            end
            FETCH_READING: begin
                $display("We're reading an instruction");
                fetch <= FETCH_NEED;
                instruction <= bus.read_data;
            end
            endcase
            $display("we have the instruction %d", instruction);
        end
    end
endmodule

