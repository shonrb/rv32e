#include "Common.hpp"
#include "Device.hpp"
#include "Memory.hpp"
#include "Design.hpp"

#include <concepts>
#include <iostream>

int main(int argc, const char **argv)
{
    auto context = std::make_shared<VerilatedContext>();
    context->commandArgs(argc, argv);

    auto sim = MainDesign(context);
    sim.set_logging(true);

    u32 program[] { 1111, 2222, 3333 };
    usize program_size = 3;

    std::println("Loading program: ");
    for (usize i = 0; i < program_size; ++i) {
        auto word = program[i];
        sim.write_word(i * 4, word);
        std::println("{}: {}", i, sim.disassemble(word));
    }

    sim.reset();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
}

