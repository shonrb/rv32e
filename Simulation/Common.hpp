#include <cstdint>
#include <cstdlib>
#include <cstdio>

using s8    = int8_t;
using s16   = int16_t;
using s32   = int32_t;
using s64   = int64_t;
using u8    = uint8_t;
using u16   = uint16_t;
using u32   = uint32_t;
using u64   = uint64_t;
using usize = size_t;
using f32   = float;
using f64   = double;

u32 binary_ones(usize n)
{
    return (1 << n) - 1;
}

u32 shiftr_arithmetic(u32 a, u32 b)
{
    return (a >> b) | ((a >> 31) * (binary_ones(32) << (32 - b)));
}

