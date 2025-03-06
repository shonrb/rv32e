#ifndef ASM_ASM_H
#define ASM_ASM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

typedef size_t size;
typedef uint32_t word;

#ifndef __cplusplus
typedef uint8_t bool;
#define true 1
#define false 0
#endif

#define ASM_MAX_ERROR 255
#define ASM_MAX_LABELS 255
#define ASM_MAX_SAVED_POS 255

typedef enum
{
    ASM_ERROR = 0,
    ASM_OK = 1,
    ASM_DONE = 2
}
AsmResult;

typedef struct 
{  
    char *label;
    size len;
    word addr;
}
AsmLabel;

typedef struct
{
    char *src;
    size src_len;
    size src_pos;
    size saved_src_pos[ASM_MAX_SAVED_POS];
    size current_saved_pos;
    word current_addr;
    AsmLabel labels[ASM_MAX_LABELS];
    size label_count;
    char *backtrack_reason;
}
AsmState;

void asm_init(AsmState*, char*, size);
AsmResult asm_next(AsmState*, word*);

#ifdef __cplusplus
} // extern "C"
#endif

#endif

