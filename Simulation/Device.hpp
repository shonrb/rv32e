#include <concepts>

struct BusDeviceSignals
{ 
    const u8 &sel;
    const u8 &write;
    const u32 &addr;
    const u32 &write_data; 
    const u8 &master_ready;
    const u8 &trans;
    u32 &read_data; 
    u8 &us_ready;
    u8 &response;
};

struct AddressRange
{
    u32 begin;
    usize size; // 64 bits needed as size may be the entire address range
};

struct BusDeviceBase
{
    virtual void write(u32, u32) = 0;
    virtual u32 read(u32) = 0;
    virtual void evaluate(BusDeviceSignals) = 0;
};

template<typename T>
concept BusDevice
    =  std::derived_from<T, BusDeviceBase>
    && std::constructible_from<T, AddressRange>;

struct NCDevice : public BusDeviceBase
{
    NCDevice(AddressRange) 
    {}

    void write(u32, u32) override 
    {}

    u32 read(u32) override
    {
        return 0;
    }

    void evaluate(BusDeviceSignals bus) override
    {
        bus.us_ready = 1; 
        bus.response = 1;
    }
};

