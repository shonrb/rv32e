#include "Syntax.h"
#include "Parse.h"
#include "Build.h"

#define ARRAY_SIZE(A) (sizeof(A) / sizeof(*A))

typedef struct
{
    const char *name;
    word value;
}
AsmRegMapping;

AsmRegMapping register_mappings[] = {
    { "x0",  0  }, { "zero", 0  },
    { "x1",  1  }, { "ra",   1  },
    { "x2",  2  }, { "sp",   2  },
    { "x3",  3  }, { "gp",   3  },
    { "x4",  4  }, { "tp",   4  },
    { "x5",  5  }, { "t0",   5  },
    { "x6",  6  }, { "t1",   6  },
    { "x7",  7  }, { "t2",   7  },
    { "x8",  8  }, { "s0",   8  }, { "fp", 8 },   
    { "x9",  9  }, { "s1",   9  },
    { "x10", 10 }, { "a0",   10 },
};

bool eat_immediate(AsmState *s, word *out)
{
    eat_space(s);
    asm_push_pos(s);

    bool negate = eat_matching(s, "-");

    bool got 
    =  eat_matching(s, "0b") && eat_number(s, BASE_2, out)
    || eat_matching(s, "0x") && eat_number(s, BASE_16, out)
    || eat_number(s, BASE_10, out);

    asm_pop_pos(s);

    if (!got)
        return false;
    if (negate)
        *out *= -1;
    return true;
}

bool eat_register(AsmState *s, word *reg)
{
    eat_space(s);
    asm_push_pos(s);
    for (size i = 0; i < ARRAY_SIZE(register_mappings); ++i) {
        AsmRegMapping mapping = register_mappings[i];
        if (eat_identifier_matching(s, mapping.name)) {
            asm_pop_pos(s);
            *reg = mapping.value;
            return true;
        }
    }
    asm_pop_pos(s);
    asm_backtrack(s, "5");
    return false;
}

bool eat_separator(AsmState *s, char *sep)
{
    return eat_space(s) && eat_matching(s, sep);
}

bool eat_label(AsmState *s)
{
    eat_space(s);
    AsmView view;
    
    bool parsed  
        =  eat_space(s)
        && eat_identifier(s, &view)
        && eat_separator(s, ":")
        && eat_endline(s)
        ;

    if (parsed) {
        // add label
        return true;
    }

    return false;
}

// Assembler Syntax //

bool eat_empty_line(AsmState *s)
{
    return eat_space(s) && eat_endline(s);
}

bool eat_opcode(AsmState *s, const char *opcode)
{
    return eat_space(s) && eat_identifier_matching(s, opcode) && eat_space(s);
}

typedef enum 
{
    ASM_OP_IMM
}
AsmInstFormat;

typedef struct
{
    AsmFunct3RegImm f3;
}
AsmInstInfo;

typedef struct 
{
    const char *opcode;
    AsmInstFormat format;
    AsmInstInfo info;
}
AsmInstruction;

typedef bool (*Parser)(AsmState*, AsmInstInfo, word*);

bool eat_op_imm(AsmState *s, AsmInstInfo info, word *out);

Parser parsers[] = {
    [ASM_OP_IMM] = eat_op_imm
};

AsmInstruction all_instructions[] = {
    { "addi", ASM_OP_IMM, { .f3 = F3_OP_IMM_ADDI }}
};

bool eat_op_imm(AsmState *s, AsmInstInfo info, word *out)
{
    word rd, rs1, imm;

    bool valid
        =  eat_register(s, &rd)
        && eat_separator(s, ",")
        && eat_register(s, &rs1)
        && eat_separator(s, ",")
        && eat_immediate(s, &imm);
    
    if (!valid) {
        asm_backtrack(s, "6");
        return false;
    }

    AsmInstFields fields = {
        .opcode = OPCODE_SOME_OP_IMM,
        .rd = rd,
        .rs1 = rs1,
        .funct3 = info.f3,
        .imm = imm
    };

    if (!build_i_type(fields, out)) {
        asm_backtrack(s, "7");
        return false;
    }

    return true;
}

bool eat_instruction(AsmState *s, word *out)
{
    for (size i = 0; i < ARRAY_SIZE(all_instructions); ++i) {
        AsmInstruction *inst = all_instructions + i;
        if (eat_identifier_matching(s, inst->opcode)) {
            Parser p = parsers[inst->format];
            return p(s, inst->info, out);
        }
    }
    return false;
}

