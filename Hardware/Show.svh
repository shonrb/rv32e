function string show_reg(input [4:0] reg_no);
    show_reg 
        = reg_no < 16 
        ? $sformatf("x%d", reg_no)
        : $sformatf("(invalid register %0d)", reg_no);
endfunction

function string show_lui(input instruction_split split);
begin
    string rd;
    rd = show_reg(split.rd);
    return $sformatf("lui %s, %0d", rd, split.u_immediate);
end
endfunction

function string show_auipc(input instruction_split split);
begin
    string rd;
    rd = show_reg(split.rd);
    return $sformatf("auipc %s, %0d", rd, split.u_immediate);
end
endfunction

function string show_jal(input instruction_split split);
begin
    string rd;
    rd = show_reg(split.rd);
    return $sformatf("jal %s, %0d", rd, split.j_immediate);
end
endfunction

function string show_jalr(input instruction_split split);
begin
    string rd, r1;
    rd = show_reg(split.rd);
    r1 = show_reg(split.rs1);
    return $sformatf("jalr %s, %s, %0d", rd, r1, split.j_immediate);
end
endfunction


function string show_op_imm(input instruction_split split);
    string opcode;
    integer imm;
    string rd; 
    string rs; 

    case (split.funct3)
    OP_IMM_ADDI:  {imm, opcode} = {split.i_immediate, "addi" };
    OP_IMM_SLTI:  {imm, opcode} = {split.i_immediate, "slti" };
    OP_IMM_SLTIU: {imm, opcode} = {split.i_immediate, "sltiu"};
    OP_IMM_XORI:  {imm, opcode} = {split.i_immediate, "xori" };
    OP_IMM_ORI:   {imm, opcode} = {split.i_immediate, "ori"  };
    OP_IMM_ANDI:  {imm, opcode} = {split.i_immediate, "andi" };
    OP_IMM_SLLI:  {imm, opcode} = {split.i_immediate, "slli" };
    OP_IMM_SOME_SHIFT_R: 
        case (split.funct7)
        SHIFT_R_LOGIC: {imm, opcode} = {split.shamt, "srli"};
        SHIFT_R_ARITH: {imm, opcode} = {split.shamt, "srai"};
        default: return $sformatf(
            "an invalid register-immediate right shift, funct7=(%b)", 
            split.funct7
        );
        endcase
    endcase

    rd = show_reg(split.rd);
    rs = show_reg(split.rs1);

    return $sformatf("%s %s, %s, %0d", opcode, rd, rs, imm);
endfunction

function string show_op_reg(input instruction_split split);
begin
    string opcode;
    string rd;
    string r1;
    string r2;    

    if (split.funct3 != OP_REG_SOME_ARITH 
    &&  split.funct3 != OP_REG_SOME_SHIFT_R 
    &&  split.funct7 != 0)
        return $sformatf(
            "an invalid register-regsister operation, funct7=(%b)", 
            split.funct7
        );
    
    case (split.funct3)
    OP_REG_SLL:  opcode = "sll";
    OP_REG_SLT:  opcode = "slt";
    OP_REG_SLTU: opcode = "sltu";
    OP_REG_XOR:  opcode = "xor";
    OP_REG_OR:   opcode = "or";
    OP_REG_AND:  opcode = "and";
    OP_REG_SOME_ARITH: 
        case (split.funct7)
        ARITH_REG_ADD: opcode = "add";
        ARITH_REG_SUB: opcode = "sub";
        default: return $sformatf(
            "an invalid register-regsister operation, funct7=(%b)", 
            split.funct7
        );
        endcase
    OP_REG_SOME_SHIFT_R: 
        case (split.funct7)
        SHIFT_R_LOGIC: opcode = "srl";
        SHIFT_R_ARITH: opcode = "sra";
        default: return $sformatf(
            "an invalid register-regsister right shift, funct7=(%b)", 
            split.funct7
        );
        endcase
    endcase

    rd = show_reg(split.rd);
    r1 = show_reg(split.rs1);
    r2 = show_reg(split.rs2);

    return $sformatf("%s %s, %s, %s", opcode, rd, r1, r2);
end
endfunction

function string show_branch(input instruction_split split);
begin
    string opcode;
    string r1;
    string r2;

    case (split.funct3)
    BRANCH_EQ:                     opcode = "beq";
    BRANCH_NOT_EQ:                 opcode = "bne";
    BRANCH_LESS_THAN_SIGNED:       opcode = "blt";
    BRANCH_GREATER_OR_EQ_SIGNED:   opcode = "bge";
    BRANCH_LESS_THAN_UNSIGNED:     opcode = "bltu";
    BRANCH_GREATER_OR_EQ_UNSIGNED: opcode = "bgeu";
    default: return $sformatf(
        "an invalid branch instruction, funct3=(%b)", 
        split.funct3
    );
    endcase

    r1 = show_reg(split.rs1);
    r2 = show_reg(split.rs2);

    return $sformatf("%s %s, %s, {0x%h}", opcode, r1, r2, split.b_immediate);
end
endfunction

function string show_load(input instruction_split split);
begin
    string opcode;
    string rd;
    string r1;

    case (split.funct3)
    LOAD_BYTE:           opcode = "lb";
    LOAD_HALFWORD:       opcode = "lh";
    LOAD_WORD:           opcode = "lw";
    LOAD_BYTE_UPPER:     opcode = "lbu";
    LOAD_HALFWORD_UPPER: opcode = "lhu";
    default: return $sformatf(
        "an invalid load instruction, funct3=(%b)", 
        split.funct3
    );
    endcase

    rd = show_reg(split.rd);
    r1 = show_reg(split.rs1);

    return $sformatf("%s %s, %0d(%s)", opcode, rd, split.b_immediate, r1);
end
endfunction

function string show_store(input instruction_split split);
begin
    string opcode;
    string r1;
    string r2;

    case (split.funct3)
    STORE_BYTE:           opcode = "sb";
    STORE_HALFWORD:       opcode = "sh";
    STORE_WORD:           opcode = "sw";
    default: return $sformatf(
        "an invalid store instruction, funct3=(%b)", 
        split.funct3
    );
    endcase

    r1 = show_reg(split.rs1);
    r2 = show_reg(split.rs2);

    return $sformatf("%s %s, %0d(%s)", opcode, r2, split.b_immediate, r1);
end
endfunction

function string show_instruction(input instruction_split split);
begin
    case (split.opcode)
    OPCODE_LUI:           return show_lui(split);
    OPCODE_AUIPC:         return show_auipc(split);
    OPCODE_JAL:           return show_jal(split);
    OPCODE_JALR:          return show_jalr(split);
    OPCODE_SOME_OP_IMM:   return show_op_imm(split);
    OPCODE_SOME_OP_REG:   return show_op_reg(split);    
    OPCODE_SOME_BRANCH:   return show_branch(split);
    OPCODE_SOME_LOAD:     return show_load(split);
    OPCODE_SOME_STORE:    return show_store(split);
    OPCODE_SOME_MISC_MEM: return "not implemented";
    OPCODE_SOME_SYSTEM:   return "not implemented";
    default:              return $sformatf("an invalid instruction: opcode=(%b)", split.opcode);
    endcase
end
endfunction

