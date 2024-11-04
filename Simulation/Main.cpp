#include "Common.hpp"
#include "Device.hpp"
#include "Memory.hpp"
#include "Design.hpp"

#include <concepts>
#include <fstream>

std::array prog {
#include "Code/All.inc"
};

int main(int argc, const char **argv)
{
    auto context = std::make_shared<VerilatedContext>();
    context->commandArgs(argc, argv);
  
    auto sim = MainDesign(context);
    sim.set_logging(true);

    std::println("Loading program: ");
    sim.write_words(0, prog);
    sim.reset();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
}

