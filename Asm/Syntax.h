#ifndef ASM_SYNTAX_H
#define ASM_SYNTAX_H

#include "Asm.h"

bool eat_label(AsmState *s);
bool eat_instruction(AsmState *s, word *out);
bool eat_empty_line(AsmState *s);

#endif

