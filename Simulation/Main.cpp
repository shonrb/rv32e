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
    sim.write_word(0, 1111); 
    sim.reset();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
    sim.cycle();
}

