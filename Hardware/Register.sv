interface reg_access_decoder;
    logic [3:0] read_loc_1;
    logic [3:0] read_loc_2;

    modport back  (input  read_loc_1, read_loc_2);
    modport front (output read_loc_1, read_loc_2);
endinterface

interface reg_access_executor;
    logic [31:0] read_data_1;
    logic [31:0] read_data_2;

    logic [3:0] write_loc;
    logic [31:0] write_data;
    logic do_write;
    
    modport back (
        input  write_data, write_loc, do_write, 
        output read_data_1, read_data_2
    );
    modport front (
        output write_data, write_loc, do_write, 
        input  read_data_1, read_data_2
    );
endinterface

module RegisterFile (
    input clock, 
    input nreset, 
    reg_access_decoder.back decoder,
    reg_access_executor.back executor
);
    logic [31:0] x[16:1];

    always_comb begin
        executor.read_data_1 = read_register(decoder.read_loc_1);
        executor.read_data_2 = read_register(decoder.read_loc_2);
    end

    always_ff @(negedge clock or negedge nreset) begin
        if (!nreset) begin
            x <= '{default:0};
        end else begin
            if (executor.do_write) begin
                if (executor.write_loc == 0) begin
                    `LOG((
                        "Tried to write (%d) to x0", 
                        executor.write_data, 
                    ));
                end else begin
                    x[executor.write_loc] <= executor.write_data;
                    `LOG((
                        "Wrote (%d) to x%0d", 
                        executor.write_data, 
                        executor.write_loc
                    ));
                end
            end
            `LOG((
                "Reading from x%0d (%0d) and x%0d (%0d)", 
                decoder.read_loc_1, 
                executor.read_data_1,
                decoder.read_loc_2,
                executor.read_data_2
            ));
        end
    end

    function [31:0] read_register(input [3:0] loc);
    begin
        if (loc == 0) 
            return 0;
        else if (executor.do_write && executor.write_loc == loc) 
            return executor.write_data;
        else 
            return x[loc];
    end
    endfunction
endmodule

