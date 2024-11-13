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

    always_comb begin
        // ALU operands
        if (inst.opcode == OPCODE_SOME_OP_IMM) begin
            alu_port.a = register_file.read_data_1;
            alu_port.b = inst.immediate;
            alu_port.operation = alu_op_imm();
        end else if (inst.opcode == OPCODE_SOME_OP_REG) begin
            alu_port.a = register_file.read_data_1;
            alu_port.b = register_file.read_data_2;
            alu_port.operation = alu_op_reg();
        end else begin
            alu_port.a = 0;
            alu_port.b = 0;
            alu_port.operation = ALU_NONE;
        end
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
        OPCODE_SOME_OP_IMM,
        OPCODE_SOME_OP_REG: begin
            `LOG((
                "Doing op (%0d) with (0x%h and 0x%h) = 0x%h",
                alu_port.operation,
                alu_port.a,
                alu_port.b,
                alu_port.result
            ));
            register_file.do_write <= 1;
            register_file.write_data <= alu_port.result;
        end
        //OPCODE_SOME_BRANCH:
        //OPCODE_SOME_LOAD:
        //OPCODE_SOME_STORE:
        //OPCODE_SOME_MISC_MEM:
        //OPCODE_SOME_SYSTEM:
        default: begin end
        endcase 
    endtask

    function alu_operation alu_op_reg();
        case (inst.funct3)
        OP_REG_SLT:  return ALU_LESS_THAN;
        OP_REG_SLTU: return ALU_LESS_THAN_UNSIGNED;
        OP_REG_XOR:  return ALU_XOR;
        OP_REG_OR:   return ALU_OR;
        OP_REG_AND:  return ALU_AND;
        OP_REG_SLL:  return ALU_SHIFT_L_LOGIC;
        OP_REG_SOME_SHIFT_R: begin
            case (inst.funct7)
            SHIFT_R_LOGIC: return ALU_SHIFT_R_LOGIC;
            SHIFT_R_ARITH: return ALU_SHIFT_R_ARITH;
            default:       `LOG(("???"));
            endcase
        end
        OP_REG_SOME_ARITH: begin
            case (inst.funct7)
            ARITH_REG_ADD: return ALU_ADD;
            ARITH_REG_SUB: return ALU_SUBTRACT;
            default:       `LOG(("???"));
            endcase
        end
        endcase
    endfunction

    function alu_operation alu_op_imm();
        case (inst.funct3)
        OP_IMM_ADDI:  return ALU_ADD;
        OP_IMM_SLTI:  return ALU_LESS_THAN;
        OP_IMM_SLTIU: return ALU_LESS_THAN_UNSIGNED;
        OP_IMM_XORI:  return ALU_XOR;
        OP_IMM_ORI:   return ALU_OR;
        OP_IMM_ANDI:  return ALU_AND;
        OP_IMM_SLLI:  return ALU_SHIFT_L_LOGIC;
        OP_IMM_SOME_SHIFT_R: begin
            case (inst.funct7)
            SHIFT_R_LOGIC: return ALU_SHIFT_R_LOGIC;
            SHIFT_R_ARITH: return ALU_SHIFT_R_ARITH;
            default:       `LOG(("???"));
            endcase
        end
        endcase
    endfunction
endmodule

