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
    auto top = std::make_unique<VTop>(context.get());

    Design<MemDevice, NCDevice> sim(context);

    auto bus = BusDeviceSignals { 
        .sel          = top->ext_sel[0],
        .write        = top->ext_write,
        .addr         = top->ext_addr,
        .write_data   = top->ext_wdata, 
        .master_ready = top->ext_ready_mst,
        .trans        = top->ext_trans,
        .read_data    = top->ext_rdata[0],
        .us_ready     = top->ext_ready_slv[0],
        .response     = top->ext_resp[0]
    };

    auto memory = MemDevice({0, 2048});

    memory.write(0, 1111); 

    auto pulse = [&](){
        static int i = 1;
        printf("CLOCK PULSE %d\n", i++);
        top->clock = 1;
        top->eval();
        top->clock = 0;
        top->eval();
    };
    top->eval();
    top->reset = 0;
    pulse();
    top->reset = 1;
    pulse();
    memory.evaluate(bus);
    pulse();
    memory.evaluate(bus);
    pulse();
    memory.evaluate(bus);
    pulse();
    memory.evaluate(bus);
    pulse();
}

