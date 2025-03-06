#include "Parse.h"

// Character classifiers

static bool is_space(char c)
{
    return isspace(c) && c != '\n';
}

static bool is_word(char c)
{
    return isalnum(c) || c == '_';
}

// Number parsing

static bool parse_digit(char c, AsmBase base, word *out)
{
    switch (base) {
    case BASE_2:
        if (c == '0' || c == '1')
            *out = c - '0' ;
        else
            return false; 
        break;
    case BASE_10:
        if (c >= '0' && c <= '9')
            *out = c - '0';
        else
            return false; 
        break;
    case BASE_16:
        if (c >= '0' && c <= '9')
            *out = c - '0';
        else if (c >= 'a' && c <= 'f')
            *out = 9 + c - 'a';
        else
            return false;
        break;
    }

    return true;
}

// State handling

void asm_panic(const char *reason)
{
    puts(reason);
    exit(1);
}

void asm_backtrack(AsmState *s, char *reason)
{
    s->src_pos = s->saved_src_pos[s->current_saved_pos];
    s->backtrack_reason = reason;
}

void asm_advance(AsmState *s)
{
    s->saved_src_pos[s->current_saved_pos] = s->src_pos;
}

void asm_push_pos(AsmState *s)
{
    s->current_saved_pos++;
    if (s->current_saved_pos == ASM_MAX_SAVED_POS) {
        asm_panic("Position stack overflow");
    }
    s->saved_src_pos[s->current_saved_pos] = s->src_pos;
}

void asm_pop_pos(AsmState *s)
{
    if (s->current_saved_pos == 0) { 
        asm_panic("Position stack underflow");
    }
    s->current_saved_pos--;
}

// Source parsing

bool eat_any(AsmState *s, char *out)
{
    if (s->src_pos == s->src_len) {
        asm_backtrack(s, "Unexpected EOF");
        return false;
    }
    *out = s->src[s->src_pos++];
    return true;
}

bool eat_matching(AsmState *s, const char *cs)
{
    for (int i = 0; i < strlen(cs); ++i) {
        char c;
        if (!eat_any(s, &c)) {
            return false;
        }
        char need = cs[i];
        if (c != need) {
            asm_backtrack(s, "1");
            return false;
        }
    }
    return true;
}

bool eat_predicate(AsmState *s, bool (*pred)(char), char *out)
{
    if (!eat_any(s, out))
        return false;
    if (!pred(*out)) {
        asm_backtrack(s, "TODO");
        return false;
    }
}

bool eat_while(AsmState *s, bool (*pred)(char), AsmView *out)
{
    char *str = s->src + s->src_pos;
    size len = 0;
    asm_push_pos(s);

    for (;;) {
        char c;
        if (!eat_predicate(s, pred, &c))
            break;
        asm_advance(s);
        len++;
    }

    asm_pop_pos(s);
    if (out) {
        out->str = str;
        out->len = len;
    }
    return true;
}

bool eat_space(AsmState *s)
{
    return eat_while(s, is_space, NULL);
}

bool eat_identifier(AsmState *s, AsmView *out)
{
    AsmView word;
    eat_space(s);
    eat_while(s, is_word, &word);
    if (word.len == 0) {
        asm_backtrack(s, "2");
        return false;
    }
    eat_space(s);
    *out = word;
    return true;
}

bool eat_identifier_matching(AsmState *s, const char *id) 
{
    AsmView word;
    if (!eat_identifier(s, &word))
        return false;
    if (word.len != strlen(id) || memcmp(word.str, id, word.len) != 0) {
        asm_backtrack(s, "3");
        return false;
    }
    return true;
}

bool eat_number(AsmState *s, AsmBase base, word *out)
{   
    AsmView view;
    if (!eat_identifier(s, &view)) 
        return false;

    word num = 0u;

    for (word i = 1; i <= view.len; ++i) {
        char c = view.str[view.len - i];
        word val;
        
        if (!parse_digit(c, base, &val)) {
            asm_backtrack(s, "TODO");
            return false;
        }

        word place = lround(pow(base, i - 1));
        num += val * place;
    }
    *out = num;
    return true;
}

bool eat_endline(AsmState *s)
{
    eat_space(s);
    if (s->src_pos == s->src_len 
    ||  s->src[s->src_pos++] == '\n') {
        return true;
    }
    asm_backtrack(s, "4");
    return false;
}

