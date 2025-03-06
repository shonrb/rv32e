#include "Build.h"

typedef enum 
{
    FIELD_RD = 7,
    FIELD_FUNCT3 = 12,
    FIELD_RS1 = 15,
    FIELD_RS2 = 20,
    FIELD_FUNCT7 = 25,
    FIELD_IMM_I_11_0 = 20,
    FIELD_IMM_S_11_5 = 25,
    FIELD_IMM_S_4_0 = 7,
    FIELD_IMM_B_12 = 31,
    FIELD_IMM_B_10_5 = 25,
    FIELD_IMM_B_4_1 = 8,
    FIELD_IMM_B_11 = 7,
    FIELD_IMM_U_31_12 = 12,
    FIELD_IMM_J_20 = 31,
    FIELD_IMM_J_10_1 = 21,
    FIELD_IMM_J_11 = 20,
    FIELD_IMM_J_19_12 = 12
}
InstFieldOffset;

#define BITS(from, to) ((1 << (to - from + 1) - 1) << from)

static word 
get_immediate_part(word imm, InstFieldOffset field, word from, word to)
{
    word bits = imm & BITS(from, to);
    return bits << (field - from);
}

void build_r_type(AsmInstFields fields, word *out)
{
    word res = fields.opcode;
    res |= fields.rd << FIELD_RD;
    res |= fields.funct3 << FIELD_FUNCT3;
    res |= fields.rs1 << FIELD_RS1;
    res |= fields.rs2 << FIELD_RS2;
    res |= fields.funct7 << FIELD_FUNCT7;
    *out = res;
}

bool build_i_type(AsmInstFields fields, word *out)
{
    if (fields.imm & BITS(12, 31)) 
        return false;
    word res = fields.opcode;
    res |= fields.rd << FIELD_RD;
    res |= fields.funct3 << FIELD_FUNCT3;
    res |= fields.rs1 << FIELD_RS1;
    res |= fields.imm << FIELD_IMM_I_11_0;
    *out = res;
    return true;
}

bool build_s_type(AsmInstFields fields, word *out)
{
    if (fields.imm & BITS(12, 31)) 
        return false;
    word res = fields.opcode;
    res |= fields.funct3 << FIELD_FUNCT3;
    res |= fields.rs1 << FIELD_RS1;
    res |= fields.rs2 << FIELD_RS2;
    res |= get_immediate_part(fields.imm, FIELD_IMM_S_11_5, 5, 11);
    res |= get_immediate_part(fields.imm, FIELD_IMM_S_4_0, 0, 4);
    return true;
}

bool build_b_type(AsmInstFields fields, word *out)
{
    if (fields.imm & 1 || fields.imm & BITS(13, 31)) 
        return false;
    word res = fields.opcode;
    res |= fields.funct3 << FIELD_FUNCT3;
    res |= fields.rs1 << FIELD_RS1;
    res |= fields.rs2 << FIELD_RS2;
    res |= get_immediate_part(fields.imm, FIELD_IMM_B_12, 12, 12);
    res |= get_immediate_part(fields.imm, FIELD_IMM_B_10_5, 5, 10);
    res |= get_immediate_part(fields.imm, FIELD_IMM_B_4_1, 4, 1);
    res |= get_immediate_part(fields.imm, FIELD_IMM_B_11, 11, 11);
    return true;
}

