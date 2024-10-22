#include <memory>
#include <optional>
#include <functional>
#include <ranges>

#include "verilated.h"
#include "VTop__Dpi.h"
#include "VTop.h"
#include "VTop___024unit.h"
#include "VTop_Top.h"

namespace params
{
    constexpr auto device_count = VTop___024unit::AHB_DEVICE_COUNT;
    constexpr auto address_map  = VTop___024unit::AHB_ADDR_MAP;
}

template<BusDevice ...Devices> 
requires (sizeof...(Devices) == params::device_count)
class Design
{
    using DeviceMap = std::array<
        std::unique_ptr<BusDeviceBase>, 
        params::device_count
    >;
    std::shared_ptr<VerilatedContext> context;
    std::unique_ptr<VTop> top;
    DeviceMap devices;

public:
    Design(std::shared_ptr<VerilatedContext> ctx)
    : context(ctx)
    , top(new VTop{context.get()})
    , devices(init_devices())
    {
        
        top->reset = 1;
        top->clock = 0;
        top->eval();
    }

    ~Design()
    {
        top->final();
    }

    void eval_devices()
    {
        for (auto [i, dev] : std::views::enumerate(devices)) {
            dev->evaluate( BusDeviceSignals { 
                .sel          = top->ext_sel[i],
                .write        = top->ext_write,
                .addr         = top->ext_addr,
                .write_data   = top->ext_wdata, 
                .master_ready = top->ext_ready_mst,
                .trans        = top->ext_trans,
                .read_data    = top->ext_rdata[i],
                .us_ready     = top->ext_ready_slv[i],
                .response     = top->ext_resp[i]
            });
        }
    }

    void pulse() 
    {
        top->clock = 1;
        top->eval();
        top->clock = 0;
        top->eval();
        eval_devices();
    }

    void reset()
    {
        top->reset = 0;
        pulse();
        top->reset = 1;
        pulse();
    }

    void write_word(u32 addr, u32 value)
    {
        mux_devices(addr)->write(addr, value);
    }

    u32 read_instruction() const
    {
        return top->Top->sig_instruction();
    }

private:
    std::unique_ptr<BusDeviceBase> &mux_devices(u32 addr)
    {
        usize current = 0;
        usize i = 0;
        for (i = 0; i < params::device_count - 1; ++i) {
            usize top = params::address_map[i];
            if (current < top) {
                break;
            }
            current = top;
        }
        return devices[i];
    }
    
    static DeviceMap init_devices()
    {
        usize i = 0;
        return DeviceMap{
            [&] {
                u32 addr_begin 
                    = i == 0 
                    ? 0 
                    : params::address_map[i-1];
                usize addr_end   
                    = i == params::device_count - 1 
                    ? 1lu << 32 
                    : params::address_map[i];
                auto range = AddressRange {
                    addr_begin,
                    addr_end - addr_begin
                };
                i++;
                return std::make_unique<Devices>(range);
            }()...
        };
    }
};

using MainDesign = Design<MemDevice, NCDevice>;

