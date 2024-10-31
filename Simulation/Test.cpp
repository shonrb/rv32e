#include "Common.hpp"
#include "Device.hpp"
#include "Memory.hpp"
#include "Design.hpp"

#include <print>
#include <random>

template<typename ...Ts>
void print_coloured(bool success, std::format_string<Ts...> fmt, Ts &&...args)
{
    constexpr auto green = "\x1b[32m";
    constexpr auto red   = "\x1b[31m";
    constexpr auto reset = "\x1b[0m";
    std::print("{}", success ? green : red);
    std::println(fmt, args...);
    std::print("{}", reset);
}

class TestContext;

template<typename T>
concept TestFunction = requires (T t, MainDesign &s, TestContext &f)
{
    t(s, f);
};

class TestContext
{
    std::mt19937 prng;

    usize passed = 0;
    usize out_of = 0;
    std::string test_name = "Untitled test";
    usize id;

public:
    TestContext(usize i)
    : id(i)
    , prng(std::random_device{}())
    {}

    void name(std::string s)
    {
        test_name = s;
    }

    u32 random_u32(u32 from, u32 to)
    {
        auto dist = std::uniform_int_distribution<u32>(from, to); 
        return dist(prng);
    }

    u32 random_u32()
    {
        auto dist = std::uniform_int_distribution<u32>(); 
        return dist(prng);
    }

    void test_assert(bool cond, const std::string &msg)
    {
        ++out_of;
        if (cond) {
            ++passed;
        } else {
            print_coloured(
                false, 
                "Test {} ({}) : Assertion failed : {}", 
                id, 
                test_name, 
                msg
            );
        }
    }

    template<typename T, typename U> 
    requires std::equality_comparable_with<T, U>
    void test_assert_eq(
        T a,
        U b, 
        std::optional<std::string> extra_info = std::nullopt)
    {
        auto prefix 
            = extra_info.has_value()
            ? std::format("{}, ", *extra_info)
            : "";
        auto msg = std::format("{}expected {} but got {}", prefix, a, b);
        test_assert(a == b, msg);
    }

private:
    bool finish()
    {   
        bool good = passed == out_of;
        print_coloured(
            good,
            "Test {} ({}) {} : {} / {} assertions held",
            id, 
            test_name,
            good ? "passed" : "failed",
            passed,
            out_of
        );
        return good;
    }

    template<TestFunction ...Tfs>
    friend void run_tests(
        std::shared_ptr<VerilatedContext> ctx, 
        Tfs ...tests
    );
};

template<TestFunction ...Tfs>
void run_tests(std::shared_ptr<VerilatedContext> ctx, Tfs ...tests)
{
    usize tests_passed = 0;
    usize out_of       = sizeof...(Tfs);
    usize test_number  = 1;
    
    ([&] {
        auto sim = MainDesign(ctx);
        auto test_ctx = TestContext(test_number);
        tests(sim, test_ctx);

        bool passed = test_ctx.finish();
        if (passed) {
            tests_passed++;
        }
        test_number++;
    }(), ...);

    print_coloured(
        tests_passed == out_of, 
        "{} tests passed out of {}", 
        tests_passed, 
        out_of
    );
}

void test_fetch(MainDesign &sim, TestContext &test)
{
    test.name("Instruction fetch working");

    auto expect = test.random_u32();
    sim.write_word(0, expect);
    sim.reset();
    sim.cycle(); // Begin transfer
    sim.cycle(); // Should have a reply
    u32 inst = sim.read_instruction();
    
    test.test_assert_eq(expect, inst, "wrong instruction fetched");
}

void test_lui(MainDesign &sim, TestContext &test)
{
    test.name("LUI instruction working");
    auto value = test.random_u32(0, 4096) << 12;
    auto dest = 1 << 7;
    auto inst = value | dest | Opcodes::OPCODE_LUI;
    sim.write_word(0, inst);
    sim.reset();
    sim.cycle(); // begin transfer
    sim.cycle(); // Should have a reply
    sim.cycle(); // Begin decode
    sim.cycle(); // execute
    test.test_assert_eq(value, sim.read_register<1>());
}

int main(int argc, const char **argv)
{
    auto context = std::make_shared<VerilatedContext>();
    context->commandArgs(argc, argv);
    run_tests(
        context,
        test_fetch, 
        test_lui
    );
}

