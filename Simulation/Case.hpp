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
concept TestCase = requires(T t, MainDesign &s, TestContext &f)
{
    t(s, f);
};

class TestContext
{
    using RandU32 = std::uniform_int_distribution<u32>;
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

    u32 random_u32()
    {
        return RandU32()(prng); 
    }

    u32 random(u32 from, u32 to)
    {
        return RandU32(from, to)(prng); 
    }

    u32 random_reg()
    {
        return random(1, 15);
    }

    u32 random_reg_exclude(std::same_as<u32> auto ...notval)
    {
        u32 val;
        do {
            val = random_reg();
        } while (([&]{ return val == notval; }() || ...));
        return val;
    }

    void test_assert(bool cond, const std::string &msg)
    {
        ++out_of;
        if (cond) {
            ++passed;
        } else {
            print_coloured(
                false, 
                "Test {} ({}) : Assertion {} failed : {}", 
                id, 
                test_name, 
                out_of,
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

    template<TestCase ...Tfs>
    friend void run_tests(
        std::shared_ptr<VerilatedContext> ctx, 
        Tfs ...tests
    );
};

template<TestCase ...Tfs>
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

