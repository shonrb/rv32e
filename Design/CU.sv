typedef enum {
    FETCH_NEED,
    FETCH_WAITING,
    FETCH_READING
} fetch_status;

module CU (
    input clock,
    input reset,
    bus_master.out bus
);
    fetch_status fetch;    
    
    logic[31:0] fetch_inst;

    logic[31:0] x [16];
    logic[31:0] pc;
    logic[31:0] instruction; 
    logic[6:0] opcode;
    logic[6:0] funct7;
    logic[4:0] rs2;
    logic[4:0] rs1;
    logic[4:0] rd;
    logic[2:0] funct3;
    logic[11:0] imm_11_0;
    logic[6:0] imm_11_5;
    logic[4:0] imm_4_0;

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

