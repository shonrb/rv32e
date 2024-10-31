interface reg_access_decode;
    logic [3:0] read_loc_1;
    logic [3:0] read_loc_2;

    modport file (input  read_loc_1, read_loc_2);
    modport out  (output read_loc_1, read_loc_2);
endinterface

interface reg_access_execute;
    logic [31:0] read_data_1;
    logic [31:0] read_data_2;

    logic [3:0] write_loc;
    logic [31:0] write_data;
    logic do_write;
    
    modport file (
        input  write_data, write_loc, do_write, 
        output read_data_1, read_data_2
    );
    modport out (
        output write_data, write_loc, do_write, 
        input  read_data_1, read_data_2
    );
endinterface

module RegisterFile (
    input clock, 
    input reset, 
    reg_access_decode.file decode,
    reg_access_execute.file execute
);
    logic [31:0] x[16];

    assign execute.read_data_1 = x[decode.read_loc_1];
    assign execute.read_data_2 = x[decode.read_loc_2];

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            x <= '{default:0};
        end else begin
            if (execute.do_write) begin
                x[execute.write_loc] <= execute.write_data;
                `LOG((
                    "Wrote (%d) to x%0d", 
                    execute.write_data, 
                    execute.write_loc
                ));
            end
            `LOG((
                "Reading from x%0d and x%0d", 
                decode.read_loc_1, 
                decode.read_loc_2
            ));
        end
    end
endmodule

