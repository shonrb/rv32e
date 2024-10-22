#include "Common.hpp"
#include "Device.hpp"
#include "Memory.hpp"
#include "Design.hpp"

#include <print>
#include <optional>

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

template<TestFunction Func>
struct Test
{
    Func run_test;
    std::string name;
};

class TestContext
{
    usize passed = 0;
    usize out_of = 0;
    usize id;
    std::string name;

public:
    TestContext(std::string n, usize i)
    : id(i)
    , name(n)
    {}

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
                name, 
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
            name,
            good ? "passed" : "failed",
            passed,
            out_of
        );
        return good;
    }

    template<TestFunction ...Tfs>
    friend void run_tests(
        std::shared_ptr<VerilatedContext> ctx, 
        Test<Tfs> ...tests
    );
};

template<TestFunction ...Tfs>
void run_tests(std::shared_ptr<VerilatedContext> ctx, Test<Tfs> ...tests)
{
    usize tests_passed = 0;
    usize out_of       = sizeof...(Tfs);
    usize test_number  = 1;
    
    ([&] {
        auto sim = MainDesign(ctx);
        auto test_ctx = TestContext(tests.name, test_number);
        tests.run_test(sim, test_ctx);

        bool passed = test_ctx.finish();
        if (passed) {
            tests_passed++;
        }
        test_number++;
    }(), ...);

    print_coloured(tests_passed == out_of, "{} tests passed out of {}", tests_passed, out_of);
}

void test_fetch(MainDesign &sim, TestContext &test)
{
    constexpr u32 expect = 1234321;
    sim.write_word(0, expect);
    sim.reset();
    sim.cycle(); // Begin transfer
    sim.cycle(); // Should have a reply
    u32 inst = sim.read_instruction();
    
    test.test_assert_eq(expect, inst, "wrong instruction fetched");
}

int main(int argc, const char **argv)
{
    auto context = std::make_shared<VerilatedContext>();
    context->commandArgs(argc, argv);
    run_tests(
        context,
        Test{test_fetch, "Instruction fetch working"}
    );
}

