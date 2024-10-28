#include "Common.hpp"
#include "Device.hpp"
#include "Memory.hpp"
#include "Design.hpp"

#include <concepts>
#include <fstream>

int main(int argc, const char **argv)
{
    auto context = std::make_shared<VerilatedContext>();
    context->commandArgs(argc, argv);

    auto sim = MainDesign(context);
    sim.set_logging(true);

    std::ifstream input("./Code/Build/All.bin", std::ios::binary);
    std::vector<u8> buffer(std::istreambuf_iterator<char>(input), {});

    u32 *program = reinterpret_cast<u32*>(buffer.data());
    usize program_size = buffer.size() / 4;

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

