#include "VTop.h"
#include "verilated.h"
#include <cstdint>
#include <iostream>
#include <cassert>
#include <array>

struct BusSlv 
{ 
    const uint8_t &sel;
    const uint8_t &write;
    const uint32_t &addr;
    const uint32_t &write_data; 
    const uint8_t &master_ready;
    const uint8_t &trans;
    uint32_t &read_data; 
    uint8_t &us_ready;
    uint8_t &response;
};

template<size_t Size, size_t AddrOffset>
class MemDevice 
{
    BusSlv bus;
    std::array<uint32_t, Size / 4> mem;

public:
    MemDevice(BusSlv b) : bus{b}, mem{0} 
    {
        bus.us_ready = 1;
    }

    void write(uint32_t addr, uint32_t value) 
    {
        // TODO: other transfer sizes
        mem[addr / 4] = value;
    }

    uint32_t read(uint32_t addr) const
    {
        // TODO: other transfer sizes
        printf("mem read %u %u\n", addr, mem[addr/4]);
        return mem[addr / 4];
    }

    void update() 
    {
        // TODO: delay on transfer to emulate real memory devices
        printf("mem: %d %d\n", bus.sel, bus.trans);
        if (bus.sel && bus.trans == 2) {
            auto addr = bus.addr - AddrOffset;
            if (bus.write) {
                write(addr, bus.write_data);
            } else {
                printf("here\n");
                bus.read_data = read(addr);
            }
        }
    }
};

int main(int argc, const char **argv)
{
    auto *context = new VerilatedContext;
    context->commandArgs(argc, argv);
    auto *top = new VTop{context};

    auto bus = BusSlv { 
        .sel = top->ext_1_sel,
        .write = top->ext_n_write,
        .addr = top->ext_n_addr,
        .write_data = top->ext_n_wdata, 
        .master_ready = top->ext_n_ready,
        .trans = top->ext_n_trans,
        .read_data = top->ext_1_rdata,
        .us_ready = top->ext_1_ready,
        .response = top->ext_1_resp
    };

    auto memory = MemDevice<1000, 0>(bus);

    memory.write(0, 1111);

    auto pulse = [&](){
        static int i = 1;
        printf("CLOCK PULSE %d\n", i++);
        top->clock = 1;
        top->eval();
        top->clock = 0;
        top->eval();
    };
    top->reset = 0;
    pulse();
    top->reset = 1;
    pulse();
    memory.update();
    pulse();
    memory.update();
    pulse();
    memory.update();
    pulse();
    memory.update();
    pulse();
}

