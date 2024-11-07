#include "Common.hpp"
#include "Device.hpp"
#include "Memory.hpp"
#include "Design.hpp"
#include "Case.hpp"

constexpr u32 NOP = Opcodes::OPCODE_SOME_OP_IMM | (OpImmF3::OP_IMM_ADDI);

void test_fetch(MainDesign &sim, TestContext &test)
{
    test.name("Instruction fetch working");

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
    test.name("LUI instruction working");
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
    test.name("AUIPC instruction working");
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
    test.name("JAL instruction working");
    
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
    test.name("JALR instruction working");
    
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
        test_jalr
    );
}

