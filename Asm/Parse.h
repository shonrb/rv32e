#ifndef ASM_PARSE_H
#define ASM_PARSE_H

#include "Asm.h"

typedef struct
{
    char *str;
    size len;
}
AsmView;

typedef enum
{
    BASE_2 = 2,
    BASE_10 = 10,
    BASE_16 = 16
}
AsmBase;

void asm_panic(const char *reason);
void asm_backtrack(AsmState *s, char *reason);
void asm_advance(AsmState *s);
void asm_push_pos(AsmState *s);
void asm_pop_pos(AsmState *s);

bool eat_matching(AsmState *s, const char *cs);
bool eat_predicate(AsmState *s, bool (*pred)(char), char *out);
bool eat_while(AsmState *s, bool (*pred)(char), AsmView *out);
bool eat_space(AsmState *s);
bool eat_identifier(AsmState *s, AsmView *out);
bool eat_identifier_matching(AsmState *s, const char *id);
bool eat_number(AsmState *s, AsmBase base, word *out);
bool eat_endline(AsmState *s);

#endif

