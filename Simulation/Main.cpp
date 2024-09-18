#include "VTop.h"
#include "verilated.h"

auto main(int argc, const char **argv) -> int 
{
    auto *context = new VerilatedContext;
    context->commandArgs(argc, argv);
    auto *top = new VTop{context};

    for (int i = 0; i < 10; ++i) {
        top->clock = !top->clock;
        top->eval();
    }
}

