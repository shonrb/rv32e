#include "Common.hpp"
#include "Device.hpp"
#include "Memory.hpp"
#include "Design.hpp"
#include "Case.hpp"

#include <tuple>

constexpr u32 NOP = Opcodes::OPCODE_SOME_OP_IMM | (OpImmF3::OP_IMM_ADDI);

void test_fetch(MainDesign &sim, TestContext &test)
{
    test.name("Instruction fetching");

    auto expect = test.random_u32();
    sim.write_word(0, expect);
    sim.reset();
    sim.cycle(); // Begin transfer
    sim.cycle(); // Should have a reply
    u32 inst = sim.read_instruction();
    
    test.test_assert_eq(expect, inst, "wrong instruction fetched");
}

void test_lui(MainDesign &sim, TestContext &test)
{
    test.name("LUI instruction");
    auto value = test.random(0, 4096) << 12;
    auto dest = test.random_reg();
    auto inst = value | (dest << 7) | Opcodes::OPCODE_LUI;
    sim.write_word(0, inst);
    sim.reset();
    sim.cycle(); // begin transfer
    sim.cycle(); // Should have a reply
    sim.cycle(); // Begin decode
    sim.cycle(); // execute
    test.test_assert_eq(value, sim.read_register(dest));
}

void test_auipc(MainDesign &sim, TestContext &test)
{
    test.name("AUIPC instruction");
    auto value = test.random(0, 4096) << 12;
    auto dest = test.random_reg();
    auto inst = value | (dest << 7) | Opcodes::OPCODE_AUIPC;

    u32 noop_count = test.random(0, 8);

    for (int i = 0; i < noop_count; ++i) {
        sim.write_word(i * 4, NOP);
    }

    u32 inst_loc = noop_count * 4;
    sim.write_word(inst_loc, inst);

    sim.reset();
    sim.do_cycles(2 + noop_count * 2);
    sim.do_cycles(2);
    test.test_assert_eq(inst_loc + value, sim.read_register(dest));
}

void test_jal(MainDesign &sim, TestContext &test)
{
    test.name("JAL instruction");
    
    u32 imm = test.random_u32() << 12; 
    u32 dest = test.random_reg();
    u32 inst = imm | (dest << 7) | Opcodes::OPCODE_JAL;

    u32 jump_offset = 0;
    jump_offset |= (imm >> 21 & binary_ones(10)) << 1;  // inst[30:21]
    jump_offset |= (imm >> 20 & 1)               << 11; // inst[20]
    jump_offset |= (imm >> 12 & binary_ones(8))  << 12; // inst[19:12]
    jump_offset |= (imm >> 31) * binary_ones(12) << 20; // inst[31] sign extended

    u32 noop_count = test.random(0, 8);

    for (int i = 0; i < noop_count; ++i) {
        sim.write_word(i * 4, NOP);
    }

    u32 inst_loc = noop_count * 4;
    sim.write_word(inst_loc, inst);

    sim.reset();
    sim.do_cycles(2 + noop_count * 2);
    sim.do_cycles(4);

    test.test_assert_eq(inst_loc + jump_offset, sim.read_program_counter());
    test.test_assert_eq(inst_loc + 4, sim.read_register(dest));
}

void test_jalr(MainDesign &sim, TestContext &test)
{
    test.name("JALR instruction");
    
    u32 imm = test.random_u32() << 20;
    u32 dest = test.random_reg();
    u32 src = test.random_reg();
    u32 target = test.random_u32();
    
    u32 inst = imm | (src << 15) | (dest << 7) | Opcodes::OPCODE_JALR;

    u32 jump_offset = 0;
    jump_offset |= (imm >> 31) * binary_ones(21) << 11;
    jump_offset |= imm >> 20 & binary_ones(11);

    u32 noop_count = test.random(0, 8);

    for (int i = 0; i < noop_count; ++i) {
        sim.write_word(i * 4, NOP);
    }

    u32 inst_loc = noop_count * 4;
    sim.write_word(inst_loc, inst);

    sim.reset();
    sim.write_register(src, target);

    sim.do_cycles(2 + noop_count * 2);
    sim.do_cycles(4);

    test.test_assert_eq(sim.read_program_counter(), target + jump_offset);
    test.test_assert_eq(sim.read_register(dest), inst_loc + 4);
}

void test_op_imm(MainDesign &sim, TestContext &test)
{
    test.name("Register-immediate arithmetic instructions");

    auto imm = test.random_u32() << 20;
    
    auto reg     = test.random_reg();
    auto reg_val = test.random_u32();

    u32 dest;
    do {
        dest = test.random_reg();
    } while (reg == dest);

    u32 imm_val = 0;
    imm_val |= (imm >> 31) * binary_ones(21) << 11;
    imm_val |= imm >> 20 & binary_ones(11);
     
    std::tuple<std::string, u32> results[] = {
        { "ADDI",  reg_val + imm_val }, // ADD
        { "SLTIU", reg_val < imm_val }, // SLTU
        { "XORI",  reg_val ^ imm_val }, // XOR
        { "ORI",   reg_val | imm_val }, // OR
        { "ANDI",  reg_val & imm_val }, // AND
        { "SLTI",  static_cast<s32>(reg_val) < static_cast<s32>(imm_val) } // SLT
    };

    auto inst = [&](OpImmF3 f3) -> u32 {
        return imm | (reg << 15) | (f3 << 12) | (dest << 7) | Opcodes::OPCODE_SOME_OP_IMM;
    };

    sim.reset();
    sim.write_register(reg, reg_val);
    sim.write_word(0,  inst(OpImmF3::OP_IMM_ADDI));
    sim.write_word(4,  inst(OpImmF3::OP_IMM_SLTIU));
    sim.write_word(8,  inst(OpImmF3::OP_IMM_XORI));
    sim.write_word(12, inst(OpImmF3::OP_IMM_ORI));
    sim.write_word(16, inst(OpImmF3::OP_IMM_ANDI));
    sim.write_word(20, inst(OpImmF3::OP_IMM_SLTI));

    sim.do_cycles(2);

    for (auto [i, elem] : std::views::enumerate(results)) {
        auto [name, result] = elem;
        sim.do_cycles(2);
        test.test_assert_eq(sim.read_register(dest), result);
    }
}

void test_op_imm_shift(MainDesign &sim, TestContext &test)
{
    test.name("Register-immediate shift instructions");

    auto shamt = test.random(0, 31);
    
    auto reg     = test.random_reg();
    auto reg_val = test.random_u32();

    u32 dest = test.random_reg_exclude(reg);

    u32 arith_shift = reg_val >> shamt;
    arith_shift |= (reg_val >> 31) * (binary_ones(32) << (32 - shamt));

    std::tuple<std::string, u32> results[] = {
        { "SLLI",  reg_val << shamt }, 
        { "SRLI",  reg_val >> shamt },
        { "SRAI",  arith_shift} 
    };

    auto inst = [&](OpImmF3 f3, u32 f7) -> u32 {
        u32 res;
        res |= (f7 << 25) | (shamt << 20) | (reg << 15);
        res |= (f3 << 12) | (dest << 7) | Opcodes::OPCODE_SOME_OP_IMM;
        return res;
    };

    sim.reset();
    sim.write_register(reg, reg_val);
    sim.write_word(0,  inst(OpImmF3::OP_IMM_SLLI,         0));
    sim.write_word(4,  inst(OpImmF3::OP_IMM_SOME_SHIFT_R, RShiftF7::SHIFT_R_LOGIC));
    sim.write_word(8,  inst(OpImmF3::OP_IMM_SOME_SHIFT_R, RShiftF7::SHIFT_R_ARITH));

    sim.do_cycles(2);

    for (auto [i, elem] : std::views::enumerate(results)) {
        auto [name, result] = elem;
        sim.do_cycles(2);
        test.test_assert_eq(sim.read_register(dest), result);
    }
}

void test_op_reg(MainDesign &sim, TestContext &test)
{
    test.name("Register-register arithmetic instructions");

    auto reg_1     = test.random_reg();
    auto reg_1_val = test.random_u32();
    auto reg_2     = test.random_reg_exclude(reg_1);
    auto reg_2_val = test.random_u32();

    auto dest = test.random_reg_exclude(reg_1, reg_2);

    std::tuple<std::string, u32> results[] = {
        { "ADD",  reg_1_val + reg_2_val }, 
        { "SUB",  reg_1_val - reg_2_val }, 
        { "XOR",  reg_1_val ^ reg_2_val }, 
        { "OR",   reg_1_val | reg_2_val }, 
        { "AND",  reg_1_val & reg_2_val }, 
        { "SLTU", reg_1_val < reg_2_val }, 
        { "SLT",  static_cast<s32>(reg_1_val) < static_cast<s32>(reg_2_val) } 
    };

    auto inst = [&](OpRegF3 f3, u32 f7) -> u32 {
        u32 res;
        res |= (f7 << 25) | (reg_2 << 20) | (reg_1 << 15);
        res |= (f3 << 12) | (dest << 7) | Opcodes::OPCODE_SOME_OP_REG;
        return res;
    };

    sim.reset();
    sim.write_register(reg_1, reg_1_val);
    sim.write_register(reg_2, reg_2_val);

    sim.write_word(0,  inst(OpRegF3::OP_REG_SOME_ARITH, ArithF7::ARITH_REG_ADD));
    sim.write_word(4,  inst(OpRegF3::OP_REG_SOME_ARITH, ArithF7::ARITH_REG_SUB));
    sim.write_word(8,  inst(OpRegF3::OP_REG_XOR, 0));
    sim.write_word(12, inst(OpRegF3::OP_REG_OR, 0));
    sim.write_word(16, inst(OpRegF3::OP_REG_AND, 0));
    sim.write_word(20, inst(OpRegF3::OP_REG_SLTU, 0));
    sim.write_word(24, inst(OpRegF3::OP_REG_SLT, 0));

    sim.do_cycles(2);

    for (auto [i, elem] : std::views::enumerate(results)) {
        auto [name, result] = elem;
        sim.do_cycles(2);
        test.test_assert_eq(sim.read_register(dest), result);
    }
}

void test_op_reg_shift(MainDesign &sim, TestContext &test)
{
    test.name("Register-register arithmetic instructions");

    auto reg_1     = test.random_reg();
    auto reg_1_val = test.random_u32();
    auto reg_2     = test.random_reg_exclude(reg_1);
    auto reg_2_val = test.random(1, 31);

    auto dest = test.random_reg_exclude(reg_1, reg_2);

    std::tuple<std::string, u32> results[] = {
        { "SLL",  reg_1_val << reg_2_val }, 
        { "SRL",  reg_1_val >> reg_2_val }, 
        { "SRA",  shiftr_arithmetic(reg_1_val, reg_2_val) }, 
    };

    auto inst = [&](OpRegF3 f3, u32 f7) -> u32 {
        u32 res;
        res |= (f7 << 25) | (reg_2 << 20) | (reg_1 << 15);
        res |= (f3 << 12) | (dest << 7) | Opcodes::OPCODE_SOME_OP_REG;
        return res;
    };

    sim.reset();
    sim.write_register(reg_1, reg_1_val);
    sim.write_register(reg_2, reg_2_val);

    sim.write_word(0,  inst(OpRegF3::OP_REG_SLL, 0));
    sim.write_word(4,  inst(OpRegF3::OP_REG_SOME_SHIFT_R, RShiftF7::SHIFT_R_LOGIC));
    sim.write_word(8,  inst(OpRegF3::OP_REG_SOME_SHIFT_R, RShiftF7::SHIFT_R_ARITH));

    sim.do_cycles(2);

    for (auto [i, elem] : std::views::enumerate(results)) {
        auto [name, result] = elem;
        sim.do_cycles(2);
        test.test_assert_eq(sim.read_register(dest), result);
    }
}

int main(int argc, const char **argv)
{
    auto context = std::make_shared<VerilatedContext>();
    context->commandArgs(argc, argv);
    run_tests(
        context,
        test_fetch, 
        test_lui,
        test_auipc,
        test_jal,
        test_jalr,
        test_op_imm,
        test_op_imm_shift,
        test_op_reg,
        test_op_reg_shift
    );
}

