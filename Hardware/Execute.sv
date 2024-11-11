typedef enum {
    EXECUTE_IDLE
} execute_state;

interface executor_port;
    logic set_pc;
    logic [31:0] new_pc;
    logic flush;

    modport back  (output set_pc, new_pc, input  flush);
    modport front (input  set_pc, new_pc, output flush);
endinterface

module ExecuteUnit (
    input clock, 
    input nreset, 
    skid_buffer_port.upstream decoder,
    reg_access_executor.front register_file,
    bus_master.front bus,
    executor_port.back control_unit
);
    decoded inst;
    assign inst = decoder.data;

    execute_state state;
    assign decoder.ready = state == EXECUTE_IDLE;

    assign register_file.write_loc = inst.destination;

    executor_to_alu alu_port();
    ArithmeticLogicUnit alu(.executor(alu_port));

    assign alu_port.a = register_file.read_data_1;

    always_comb begin
        
    end

    always_ff @(posedge clock or negedge nreset) begin
        if (!nreset || control_unit.flush) begin
            `LOG(("Resetting executor"));
            register_file.do_write <= 0;
            control_unit.set_pc <= 0;
        end else begin
            if (decoder.valid) begin
                `LOG(("Got a decoded instruction..."));
                execute();
                `LOG(("%p", decoder.data));
            end else begin
                `LOG(("Didn't get anything from decoder"));
                register_file.do_write <= 0;
                control_unit.set_pc <= 0;
            end
        end
    end

    task execute;
        case (inst.opcode)
        OPCODE_LUI: begin
            register_file.do_write <= 1;
            register_file.write_data <= inst.immediate;
            `LOG(("LUI"));
        end
        OPCODE_AUIPC: begin
            register_file.do_write <= 1;
            register_file.write_data <= inst.pc + inst.immediate;
            `LOG(("AUIPC"));
        end
        OPCODE_JAL: begin
            register_file.do_write <= 1;
            register_file.write_data <= inst.pc + 4;
            control_unit.set_pc <= 1;
            control_unit.new_pc <= inst.pc + inst.immediate;
            `LOG(("JAL"));
        end
        OPCODE_JALR: begin
            register_file.do_write <= 1;
            register_file.write_data <= inst.pc + 4;
            control_unit.set_pc <= 1;
            control_unit.new_pc <= register_file.read_data_1 + inst.immediate;
            `LOG(("JALR"));
        end
        //OPCODE_SOME_OP_IMM:
        //OPCODE_SOME_OP_REG:
        //OPCODE_SOME_BRANCH:
        //OPCODE_SOME_LOAD:
        //OPCODE_SOME_STORE:
        //OPCODE_SOME_MISC_MEM:
        //OPCODE_SOME_SYSTEM:
        default: begin end
        endcase 
    endtask
endmodule

