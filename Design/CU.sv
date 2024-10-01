typedef enum logic {
    FETCH_NEED,
    FETCH_WAITING
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

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            x <= '{default: 0};
            pc <= 0;
            instruction <= 0;
        end else begin
            case (fetch)
            FETCH_NEED: if (bus.ready) begin
                bus.address <= pc;
                bus.write <= 0;
                bus.start <= 1;
                fetch <= FETCH_WAITING;
                pc <= pc + 4;
            end
            FETCH_WAITING: if (bus.ready) begin
                $display("waiting");
                if (bus.response == RESP_ERROR) begin
                    $error("Bus responded with error during instruction fetch");
                end else begin
                    fetch_inst <= bus.read_data; 
                    fetch <= FETCH_WAITING;
                end
            end
            endcase
        end
        $display("%d", instruction);
    end
endmodule

