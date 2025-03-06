#include "Parse.h"
#include "Build.h"
#include "Syntax.h"

void asm_init(AsmState *s, char *src, size src_len)
{
    memset(s, 0, sizeof(AsmState));
    s->src = src;
    s->src_len = src_len;
}

AsmResult asm_next(AsmState *s, word *out)
{
retry:
    if (s->src_pos == s->src_len) {
        return ASM_DONE;
    }
    if (eat_empty_line(s) || eat_label(s)) {
        asm_advance(s);
        goto retry;
    }
    return eat_instruction(s, out) ? ASM_OK : ASM_ERROR;
}

