#ifndef ASM_BUILD_H
#define ASM_BUILD_H

#include "Asm.h"

typedef enum 
{
#include "../Common/Opcodes.inc"
}
AsmOpcode;

typedef enum
{
#include "../Common/Funct3RegImm.inc"
}
AsmFunct3RegImm;

typedef enum
{
#include "../Common/Funct7RegArith.inc"
}
AsmFunct7RegArith;

typedef struct 
{
    word opcode;
    word rd; 
    word rs1;
    word rs2;
    word funct3;
    word funct7;
    word imm;
}
AsmInstFields;

void build_r_type(AsmInstFields fields, word *out);
bool build_i_type(AsmInstFields fields, word *out);
bool build_s_type(AsmInstFields fields, word *out);
bool build_b_type(AsmInstFields fields, word *out);

#endif 

