bit logging;

task set_logging(input bit b);
    /* verilator public */
    assign logging = b;
endtask

function string reset;
    reset = {8'h1b, "[0m"};
endfunction

function string colour_file(input string file);
    case (file)
    "Hardware/Control.sv" : colour_file = {8'h1b, "[31m"};
    "Hardware/Fetch.sv"   : colour_file = {8'h1b, "[32m"};
    "Hardware/Bus.sv"     : colour_file = {8'h1b, "[33m"};
    "Hardware/Skid.sv"    : colour_file = {8'h1b, "[34m"};
    "Hardware/Execute.sv" : colour_file = {8'h1b, "[35m"};
    default               : colour_file = reset();
    endcase
endfunction

task log_inner(input string ctx, input string str);
    if (logging) begin
        $display("%s  (%s) %s%s", colour_file(ctx), ctx, str, reset());
    end
endtask 

function string describe_instruction(input instruction_split split);
begin
    // TODO: add operands as well
    case (split.opcode)
    OPCODE_SOME_OP_IMM:
        case (split.funct3)
        OP_IMM_ADDI:  describe_instruction = "addi";
        OP_IMM_SLTI:  describe_instruction = "slti";
        OP_IMM_SLTIU: describe_instruction = "sltiu";
        OP_IMM_XORI:  describe_instruction = "xori";
        OP_IMM_ORI:   describe_instruction = "ori";
        OP_IMM_ANDI:  describe_instruction = "andi";
        OP_IMM_SLLI:  describe_instruction = "slli";
        OP_IMM_SOME_SHIFT_R: 
            case (split.funct7)
            SHIFT_R_LOGIC: describe_instruction = "srli";
            SHIFT_R_ARITH: describe_instruction = "srai";
            default:       describe_instruction 
                = "an invalid immediate-register right shift";
            endcase
        endcase
    OPCODE_SOME_OP_REG: begin
        if (split.funct3 != OP_REG_SOME_ARITH 
        &&  split.funct3 != OP_REG_SOME_SHIFT_R 
        &&  split.funct7 != 0)
            describe_instruction = "an invalid register-register operation";
        else
            case (split.funct3)
            OP_REG_SLL:  describe_instruction = "sll";
            OP_REG_SLT:  describe_instruction = "slt";
            OP_REG_SLTU: describe_instruction = "sltu";
            OP_REG_XOR:  describe_instruction = "xor";
            OP_REG_OR:   describe_instruction = "or";
            OP_REG_AND:  describe_instruction = "and";
            OP_REG_SOME_ARITH: 
                case (split.funct7)
                ARITH_REG_ADD: describe_instruction = "add";
                ARITH_REG_SUB: describe_instruction = "sub";
                default:       describe_instruction 
                    = "an invalid register-regsister operation";
                endcase
            OP_REG_SOME_SHIFT_R: 
                case (split.funct7)
                SHIFT_R_LOGIC: describe_instruction = "srl";
                SHIFT_R_ARITH: describe_instruction = "sra";
                default:       describe_instruction 
                    = "an invalid register-regsister right shift";
                endcase
            endcase
    end
    OPCODE_SOME_BRANCH:
        case (split.funct3)
        BRANCH_EQ:                     describe_instruction = "beq";
        BRANCH_NOT_EQ:                 describe_instruction = "bne";
        BRANCH_LESS_THAN_SIGNED:       describe_instruction = "blt";
        BRANCH_GREATER_OR_EQ_SIGNED:   describe_instruction = "bge";
        BRANCH_LESS_THAN_UNSIGNED:     describe_instruction = "bltu";
        BRANCH_GREATER_OR_EQ_UNSIGNED: describe_instruction = "bgeu";
        default:                       describe_instruction 
           = "an invalid branch instruction";
        endcase
    OPCODE_SOME_LOAD: 
        case (split.funct3)
        LOAD_BYTE:           describe_instruction = "lb";
        LOAD_HALFWORD:       describe_instruction = "lh";
        LOAD_WORD:           describe_instruction = "lw";
        LOAD_BYTE_UPPER:     describe_instruction = "lbu";
        LOAD_HALFWORD_UPPER: describe_instruction = "lhu";
        default:             describe_instruction 
            = "an invalid load instruction";
        endcase
    OPCODE_SOME_STORE:
        case (split.funct3)
        STORE_BYTE:     describe_instruction = "sb";
        STORE_HALFWORD: describe_instruction = "sh";
        STORE_WORD:     describe_instruction = "sw";
        default:        describe_instruction 
            = "an invalid store instruction";
        endcase
    OPCODE_SOME_MISC_MEM: describe_instruction = "not implemented";
    OPCODE_SOME_SYSTEM:   describe_instruction = "not implemented";
    default:              
        describe_instruction = $sformatf("an invalid opcode (%b)", split.opcode);
    endcase
end
endfunction

