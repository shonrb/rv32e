#include <vector>
#include <print>

class MemDevice : public BusDeviceBase
{
    u32 address_offset;
    // TODO: no more hacky division by 4 stuff
    std::vector<u32> memory;

public:
    MemDevice(AddressRange range) 
    : address_offset(range.begin)
    , memory(range.size / 4, 0)
    {
        std::println("init with {} {}", range.begin, range.size);
    }

    void write(u32 addr, u32 value) override
    {
        // TODO: other transfer sizes
        std::println("WRITE TO {} - {}", addr, address_offset);
        memory[(addr - address_offset) / 4] = value;
    }

    u32 read(u32 addr) override
    {
        // TODO: other transfer sizes
        return memory[(addr - address_offset) / 4];
    }

    void evaluate(BusDeviceSignals bus) override
    {
        bus.us_ready = 1;
        // TODO: delay on transfer to emulate real memory devices
        printf("mem: %d %d\n", bus.sel, bus.trans);
        if (bus.sel && bus.trans == 2) {
            if (bus.write) {
                write(bus.addr, bus.write_data);
            } else {
                printf("here\n");
                bus.read_data = read(bus.addr);
            }
        }
    }
};

