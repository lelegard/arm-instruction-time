//----------------------------------------------------------------------------
// Copyright (c) 2023, Thierry Lelegard
// BSD 2-Clause License, see LICENSE file.
//----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#if defined(__linux__)
#include <sys/auxv.h>
#endif

// Check if PAC is supported on the current CPU.
int has_pac()
{
#if defined(__APPLE__)
    // PAC is supported on all Apple Silicon chips.
    // But can disabled at application or system level (arch arm64 vs. arm64e).
    // Check if PAC instructions are muted (arch arm64).
    uint64_t in = 0x12345678;
    uint64_t out = in;
    asm("pacia %[reg], sp" : [reg] "+r" (out));
    return in != out;
#else
    return (getauxval(AT_HWCAP) & HWCAP_PACA) != 0;
#endif
}

// Declare and run one test.
#define TEST(name, iterations, bool_empty_loop)                                         \
    extern double xxx_##name(int64_t count, int64_t bel) asm("xxx_"#name);          \
    printf("%-20s %.3f ns/inst\n", #name, xxx_##name(iterations, bool_empty_loop))

// 100 million iterations as reference.
#define REFCOUNT 100000000

int main(int argc, char* argv[])
{
    for (int64_t bel = 0; bel < 2; bel++) {
        printf("--- Empty loop time %s\n", bel ? "removed" : "ignored");
        TEST(nop, REFCOUNT * 4, bel);
        TEST(add, REFCOUNT, bel);
        TEST(adc, REFCOUNT, bel);
        TEST(adds, REFCOUNT, bel);
        TEST(adcs, REFCOUNT, bel);
        TEST(mul, REFCOUNT, bel);
        TEST(umulh, REFCOUNT, bel);
        TEST(div, REFCOUNT, bel);
        TEST(mul_umulh, REFCOUNT, bel);
        TEST(mul_adcs_umulh_adcs, REFCOUNT, bel);
        TEST(mul_adcs, REFCOUNT, bel);
        TEST(umulh_adcs, REFCOUNT, bel);
        TEST(mul_add_umulh_add, REFCOUNT, bel);
        if (has_pac()) {
            TEST(pacia, REFCOUNT, bel);
            TEST(autia, REFCOUNT, bel);
            TEST(pacia_autia, REFCOUNT, bel);
            TEST(pacia_autia_2, REFCOUNT, bel);
        }
    }
    return EXIT_SUCCESS;
}
