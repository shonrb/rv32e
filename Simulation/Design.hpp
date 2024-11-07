#include <memory>
#include <optional>
#include <functional>
#include <ranges>
#include <iterator>

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

using Opcodes  = VTop___024unit::opcode_field;
using OpImmF3  = VTop___024unit::funct3_op_imm;
using OpRegF3  = VTop___024unit::funct3_op_reg;
using RShiftF7 = VTop___024unit::funct7_r_shift_kind;
using ArithF7  = VTop___024unit::funct7_reg_arith;
using BranchF3 = VTop___024unit::funct3_branch;
using LoadF3   = VTop___024unit::funct3_load;
using StoreF3  = VTop___024unit::funct3_store;

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
    bool logging = false;
    usize cycle_count = 0;

public:
    Design(std::shared_ptr<VerilatedContext> ctx)
    : context(ctx)
    , top(new VTop{context.get()})
    , devices(init_devices())
    {
        top->nreset = 1;
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

    void cycle() 
    {
        log("Doing clock cycle {}", ++cycle_count);
        log("Positive edge");
        top->clock = 1;
        top->eval();
        log("Negative edge");
        top->clock = 0;
        top->eval();
        log("Evaluating devices");
        eval_devices();
    }

    void do_cycles(usize count)
    {
        while (count--) {
            cycle();
        }
    }

    void reset()
    {
        log("Resetting core");
        top->nreset = 0;
        cycle();
        top->nreset = 1;
    }

    void write_word(u32 addr, u32 value)
    {
        mux_devices(addr)->write(addr, value);
    }

    template<typename T>
    requires std::ranges::range<T> 
    && std::is_same_v<std::ranges::range_value_t<T>, u32>
    void write_words(u32 addr, T vals) 
    {
        for (auto [i, v] : std::ranges::views::enumerate(vals)) {
            write_word(addr + i * 4, v);
        }
    }

    std::string disassemble(u32 instruction) 
    {
        return top->__024unit->disassemble(instruction);
    }

    void set_logging(bool l)
    {
        logging = l;
        top->__024unit->set_logging(l);
    }

    u32 read_register(usize i) 
    {
        return top->Top->sig_register(i);
    }

    void write_register(usize i, u32 value) 
    {
        top->Top->write_sig_register(i, value);
    }

    u32 read_instruction() const
    {
        return top->Top->sig_instruction();
    }

    u32 read_program_counter() const
    {
        return top->Top->sig_pc();
    }

private:
    template<typename ...Ts>
    void log(std::format_string<Ts...> fmt, Ts &&...args)
    {
        if (logging) {
            std::println(fmt, args...);
        }
    }

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

