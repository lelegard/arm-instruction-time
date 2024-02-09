//----------------------------------------------------------------------------
// Copyright (c) 2023, Thierry Lelegard
// BSD 2-Clause License, see LICENSE file.
//----------------------------------------------------------------------------

        // Declare a function.
        .macro  func symbol
        .text
        .align  2
        .globl  \symbol
\symbol:
        .endm

        // Declare the start of a structure (typically a stack frame).
        .macro  struct_begin
        .struct_offset = 0
        .endm

        // Declare a field in the current structure. Size in bytes.
        .macro  struct_field name, size
        \name = .struct_offset
        .struct_offset = .struct_offset + \size
        .endm

        // Realign inside current structure. Alignment in bytes.
        .macro  struct_align align
        .struct_offset = .struct_offset + (\align - (.struct_offset % \align)) % \align
        .endm

        // End of current structure. Define alignment in bytes and name for structure size.
        .macro  struct_end size_name, align=16
        struct_align \align
        \size_name = .struct_offset
        .endm

        // Prolog of all functions in this module.
        // Profile: double func(int64_t iterations, int64_t bool_empty_loop);
        // bool_empty_loop: if non-zero, substract empty loop time.
        // Return: average time of one instruction in iteration body in nanoseconds.
        //
        // Available registers in tested instruction loop:
        // - x0 : iteration count in x0
        // - x1-x2: generic operands, fixed values
        // - x3-x15: free to use without breaking the ABI.
        // - x16-x18: temporary registers.
        // - x19-x28: saved registers, initially contains same fixed values as x1, x2 (by pairs)
        .macro  xxx_begin symbol
        func    \symbol
        // Stack frame layout.
        struct_begin
        struct_field xxx.call_frame, 16     // call frame (x29, x30)
        struct_field xxx.saved_x19_x20, 16  // saved registers x19, x20
        struct_field xxx.saved_x21_x22, 16  // saved registers x21, x22
        struct_field xxx.saved_x23_x24, 16  // saved registers x23, x24
        struct_field xxx.saved_x25_x26, 16  // saved registers x25, x26
        struct_field xxx.saved_x27_x28, 16  // saved registers x27, x28
        struct_field xxx.iter, 8            // iteration count
        struct_field xxx.bel, 8             // bool_empty_loop (if non-zero, substract empty loop time)
        struct_field xxx.time1, 8           // start / duration of main instruction loop
        struct_field xxx.time2, 8           // start of empty loop
        struct_end   xxx.stack_size
        // Function prolog.
        stp     x29, x30, [sp, -xxx.stack_size]!
        mov     x29, sp
        stp     x19, x20, [sp, xxx.saved_x19_x20]
        stp     x21, x22, [sp, xxx.saved_x21_x22]
        stp     x23, x24, [sp, xxx.saved_x23_x24]
        stp     x25, x26, [sp, xxx.saved_x25_x26]
        stp     x27, x28, [sp, xxx.saved_x27_x28]
        // Start of function.
        str     x0, [sp, xxx.iter]
        str     x1, [sp, xxx.bel]
        mov     x1, #0xCDEF             // x1 = 0x0123456789ABCDEF
        movk    x1, #0x89AB, lsl 16
        movk    x1, #0x4567, lsl 32
        movk    x1, #0x0123, lsl 48
        mov     x19, x1                 // x19 = x21 = x23 = x25 = x27 = x1
        mov     x21, x1
        mov     x23, x1
        mov     x25, x1
        mov     x27, x1
        mov     x2, #0x3210             // x2 = 0xFEDCBA9876543210
        movk    x2, #0x7654, lsl 16
        movk    x2, #0xBA98, lsl 32
        movk    x2, #0xFEDC, lsl 48
        mov     x20, x2                 // x20 = x22 = x24 = x26 = x28 = x2
        mov     x22, x2
        mov     x24, x2
        mov     x26, x2
        mov     x28, x2
        isb                             // instruction barrier before getting timer counter
        mrs     x3, cntvct_el0          // virtual timer counter
        str     x3, [sp, xxx.time1]
        // Start of main instruction loop.
1:      cbz     x0, 5f
        sub     x0, x0, #1
3:
        .endm

#define ALL_REGS 3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
        
        // End of all functions.
        .macro  xxx_end
4:      b       1b                      // Loop back to instruction sequence.
5:      // End of main instruction loop.
        isb
        mrs     x0, cntvct_el0
        str     x0, [sp, xxx.time2]     // time2 = start of second loop
        ldr     x1, [sp, xxx.time1]
        sub     x0, x0, x1              // x0 = duration of the instruction loop, in virtual timer units
        ldr     x1, [sp, xxx.bel]       // x1 = bool_empty_loop
        cbz     x1, 8f                  // branch if don't substract empty loop time
        str     x0, [sp, xxx.time1]     // time1 = duration of the instruction loop
        ldr     x0, [sp, xxx.iter]
        // Start of empty instruction loop.
6:      cbz     x0, 7f
        sub     x0, x0, #1
        b       6b
7:      // End of empty instruction loop.
        isb
        mrs     x0, cntvct_el0
        ldr     x1, [sp, xxx.time2]
        sub     x2, x0, x1              // x2 = duration of empty loop
        ldr     x1, [sp, xxx.time1]     // x1 = duration of the instruction loop
        sub     x0, x1, x2              // x0 = instructions duration, in virtual timer units
8:      ucvtf   d0, x0
        mov     x1, #0xCA00             // x1 = 0x3B9ACA00 = 1 billion = nano-sec / sec
        movk    x1, #0x3B9A, lsl 16
        ucvtf   d1, x1
        fmul    d2, d0, d1              // d2 = instructions duration * 1 billion
        mrs     x1, cntfrq_el0          // x1 = frequency in Hz of virtual timer
        ucvtf   d1, x1
        fdiv    d3, d2, d1              // d3 = instructions duration in nanoseconds
        mov     x1, #(4b - 3b) / 4      // x1 = number in instructions in main loop
        ldr     x0, [sp, xxx.iter]
        mul     x2, x1, x0              // x2 = total number of executed instructions
        ucvtf   d2, x2
        fdiv    d0, d3, d2              // d0 (result) = average duration of one instruction in nanoseconds
        // Function epilog
        ldp     x19, x20, [sp, xxx.saved_x19_x20]
        ldp     x21, x22, [sp, xxx.saved_x21_x22]
        ldp     x23, x24, [sp, xxx.saved_x23_x24]
        ldp     x25, x26, [sp, xxx.saved_x25_x26]
        ldp     x27, x28, [sp, xxx.saved_x27_x28]
        ldp     x29, x30, [sp], xxx.stack_size
        ret
        .endm

//----------------------------------------------------------------------------

        // To keep a fair comparison between all sequences, try to keep all
        // loops to the same number of instructions. Otherwise, distinct usages of
        // cache may introduce some bias. Currently, use 32 instructions per loop.

        xxx_begin xxx_nop
        .rept   32
        nop
        .endr
        xxx_end

        xxx_begin xxx_mul
        .rept   2
        .irp    reg,ALL_REGS
        mul     x\reg, x1, x2
        .endr
        .endr
        xxx_end

        xxx_begin xxx_umulh
        .rept   2
        .irp    reg,ALL_REGS
        umulh   x\reg, x1, x2
        .endr
        .endr
        xxx_end

        xxx_begin xxx_div
        .rept   2
        .irp    reg,ALL_REGS
        udiv    x\reg, x2, x1
        .endr
        .endr
        xxx_end

        xxx_begin xxx_add
        .rept   2
        .irp    reg,ALL_REGS
        add     x\reg, x1, x2
        .endr
        .endr
        xxx_end

        xxx_begin xxx_adcs
        .rept   2
        .irp    reg,ALL_REGS
        adcs    x\reg, x1, x2
        .endr
        .endr
        xxx_end

        xxx_begin xxx_adds
        .rept   2
        .irp    reg,ALL_REGS
        adds    x\reg, x1, x2
        .endr
        .endr
        xxx_end

        xxx_begin xxx_adc
        .rept   2
        .irp    reg,ALL_REGS
        adc     x\reg, x1, x2
        .endr
        .endr
        xxx_end

        xxx_begin xxx_mul_umulh
        .rept   2
        mul     x3, x1, x2
        umulh   x4, x1, x2
        mul     x5, x1, x2
        umulh   x6, x1, x2
        mul     x7, x1, x2
        umulh   x8, x1, x2
        mul     x9, x1, x2
        umulh   x10, x1, x2
        mul     x11, x1, x2
        umulh   x12, x1, x2
        mul     x13, x1, x2
        umulh   x14, x1, x2
        mul     x15, x1, x2
        umulh   x16, x1, x2
        mul     x17, x1, x2
        umulh   x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_mul_add_umulh_add
        .rept   2
        mul     x3, x1, x2
        add     x4, x1, x2
        umulh   x5, x1, x2
        add     x6, x1, x2
        mul     x7, x1, x2
        add     x8, x1, x2
        umulh   x9, x1, x2
        add     x10, x1, x2
        mul     x11, x1, x2
        add     x12, x1, x2
        umulh   x13, x1, x2
        add     x14, x1, x2
        mul     x15, x1, x2
        add     x16, x1, x2
        umulh   x17, x1, x2
        add     x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_mul_add
        .rept   2
        mul     x3, x1, x2
        add     x4, x1, x2
        mul     x5, x1, x2
        add     x6, x1, x2
        mul     x7, x1, x2
        add     x8, x1, x2
        mul     x9, x1, x2
        add     x10, x1, x2
        mul     x11, x1, x2
        add     x12, x1, x2
        mul     x13, x1, x2
        add     x14, x1, x2
        mul     x15, x1, x2
        add     x16, x1, x2
        mul     x17, x1, x2
        add     x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_mul_adc
        .rept   2
        mul     x3, x1, x2
        adc     x4, x1, x2
        mul     x5, x1, x2
        adc     x6, x1, x2
        mul     x7, x1, x2
        adc     x8, x1, x2
        mul     x9, x1, x2
        adc     x10, x1, x2
        mul     x11, x1, x2
        adc     x12, x1, x2
        mul     x13, x1, x2
        adc     x14, x1, x2
        mul     x15, x1, x2
        adc     x16, x1, x2
        mul     x17, x1, x2
        adc     x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_mul_adds
        .rept   2
        mul     x3, x1, x2
        adds    x4, x1, x2
        mul     x5, x1, x2
        adds    x6, x1, x2
        mul     x7, x1, x2
        adds    x8, x1, x2
        mul     x9, x1, x2
        adds    x10, x1, x2
        mul     x11, x1, x2
        adds    x12, x1, x2
        mul     x13, x1, x2
        adds    x14, x1, x2
        mul     x15, x1, x2
        adds    x16, x1, x2
        mul     x17, x1, x2
        adds    x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_mul_adcs
        .rept   2
        mul     x3, x1, x2
        adcs    x4, x1, x2
        mul     x5, x1, x2
        adcs    x6, x1, x2
        mul     x7, x1, x2
        adcs    x8, x1, x2
        mul     x9, x1, x2
        adcs    x10, x1, x2
        mul     x11, x1, x2
        adcs    x12, x1, x2
        mul     x13, x1, x2
        adcs    x14, x1, x2
        mul     x15, x1, x2
        adcs    x16, x1, x2
        mul     x17, x1, x2
        adcs    x18, x1, x2
        .endr
        xxx_end

        // same as xxx_mul_adcs but alternate 4 pairs of input registers
        xxx_begin xxx_mul_adcs_alt
        .rept   2
        mul     x3, x1, x2
        adcs    x4, x19, x20
        mul     x5, x21, x22
        adcs    x6, x23, x24
        mul     x7, x1, x2
        adcs    x8, x19, x20
        mul     x9, x21, x22
        adcs    x10, x23, x24
        mul     x11, x1, x2
        adcs    x12, x19, x20
        mul     x13, x21, x22
        adcs    x14, x23, x24
        mul     x15, x1, x2
        adcs    x16, x19, x20
        mul     x17, x21, x22
        adcs    x18, x23, x24
        .endr
        xxx_end

        xxx_begin xxx_umulh_add
        .rept   2
        umulh   x3, x1, x2
        add     x4, x1, x2
        umulh   x5, x1, x2
        add     x6, x1, x2
        umulh   x7, x1, x2
        add     x8, x1, x2
        umulh   x9, x1, x2
        add     x10, x1, x2
        umulh   x11, x1, x2
        add     x12, x1, x2
        umulh   x13, x1, x2
        add     x14, x1, x2
        umulh   x15, x1, x2
        add     x16, x1, x2
        umulh   x17, x1, x2
        add     x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_umulh_adc
        .rept   2
        umulh   x3, x1, x2
        adc     x4, x1, x2
        umulh   x5, x1, x2
        adc     x6, x1, x2
        umulh   x7, x1, x2
        adc     x8, x1, x2
        umulh   x9, x1, x2
        adc     x10, x1, x2
        umulh   x11, x1, x2
        adc     x12, x1, x2
        umulh   x13, x1, x2
        adc     x14, x1, x2
        umulh   x15, x1, x2
        adc     x16, x1, x2
        umulh   x17, x1, x2
        adc     x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_umulh_adds
        .rept   2
        umulh   x3, x1, x2
        adds    x4, x1, x2
        umulh   x5, x1, x2
        adds    x6, x1, x2
        umulh   x7, x1, x2
        adds    x8, x1, x2
        umulh   x9, x1, x2
        adds    x10, x1, x2
        umulh   x11, x1, x2
        adds    x12, x1, x2
        umulh   x13, x1, x2
        adds    x14, x1, x2
        umulh   x15, x1, x2
        adds    x16, x1, x2
        umulh   x17, x1, x2
        adds    x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_umulh_adcs
        .rept   2
        umulh   x3, x1, x2
        adcs    x4, x1, x2
        umulh   x5, x1, x2
        adcs    x6, x1, x2
        umulh   x7, x1, x2
        adcs    x8, x1, x2
        umulh   x9, x1, x2
        adcs    x10, x1, x2
        umulh   x11, x1, x2
        adcs    x12, x1, x2
        umulh   x13, x1, x2
        adcs    x14, x1, x2
        umulh   x15, x1, x2
        adcs    x16, x1, x2
        umulh   x17, x1, x2
        adcs    x18, x1, x2
        .endr
        xxx_end

        // same as xxx_umulh_adcs but alternate 4 pairs of input registers
        xxx_begin xxx_umulh_adcs_alt
        .rept   2
        umulh   x3, x1, x2
        adcs    x4, x19, x20
        umulh   x5, x21, x22
        adcs    x6, x23, x24
        umulh   x7, x1, x2
        adcs    x8, x19, x20
        umulh   x9, x21, x22
        adcs    x10, x23, x24
        umulh   x11, x1, x2
        adcs    x12, x19, x20
        umulh   x13, x21, x22
        adcs    x14, x23, x24
        umulh   x15, x1, x2
        adcs    x16, x19, x20
        umulh   x17, x21, x22
        adcs    x18, x23, x24
        .endr
        xxx_end

        xxx_begin xxx_umulh_nop_adcs
        umulh   x3, x1, x2
        nop
        adcs    x5, x1, x2
        umulh   x6, x1, x2
        nop
        adcs    x8, x1, x2
        umulh   x9, x1, x2
        nop
        adcs    x11, x1, x2
        umulh   x12, x1, x2
        nop
        adcs    x14, x1, x2
        umulh   x15, x1, x2
        nop
        adcs    x17, x1, x2
        umulh   x18, x1, x2
        nop
        adcs    x4, x1, x2
        umulh   x5, x1, x2
        nop
        adcs    x7, x1, x2
        umulh   x8, x1, x2
        nop
        adcs    x10, x1, x2
        umulh   x11, x1, x2
        nop
        adcs    x13, x1, x2
        umulh   x14, x1, x2
        nop
        adcs    x16, x1, x2
        umulh   x17, x1, x2
        nop
        adcs    x10, x1, x2
        xxx_end

        xxx_begin xxx_umulh_adds_adcs
        umulh   x3, x1, x2
        adds    x4, x1, x2
        adcs    x5, x1, x2
        umulh   x6, x1, x2
        adds    x7, x1, x2
        adcs    x8, x1, x2
        umulh   x9, x1, x2
        adds    x10, x1, x2
        adcs    x11, x1, x2
        umulh   x12, x1, x2
        adds    x13, x1, x2
        adcs    x14, x1, x2
        umulh   x15, x1, x2
        adds    x16, x1, x2
        adcs    x17, x1, x2
        umulh   x18, x1, x2
        adds    x3, x1, x2
        adcs    x4, x1, x2
        umulh   x5, x1, x2
        adds    x6, x1, x2
        adcs    x7, x1, x2
        umulh   x8, x1, x2
        adds    x9, x1, x2
        adcs    x10, x1, x2
        umulh   x11, x1, x2
        adds    x12, x1, x2
        adcs    x13, x1, x2
        umulh   x14, x1, x2
        adds    x15, x1, x2
        adcs    x16, x1, x2
        umulh   x17, x1, x2
        adds    x18, x1, x2
        adcs    x10, x1, x2
        xxx_end

        xxx_begin xxx_umulh_add_adcs
        umulh   x3, x1, x2
        add     x4, x1, x2
        adcs    x5, x1, x2
        umulh   x6, x1, x2
        add     x7, x1, x2
        adcs    x8, x1, x2
        umulh   x9, x1, x2
        add     x10, x1, x2
        adcs    x11, x1, x2
        umulh   x12, x1, x2
        add     x13, x1, x2
        adcs    x14, x1, x2
        umulh   x15, x1, x2
        add     x16, x1, x2
        adcs    x17, x1, x2
        umulh   x18, x1, x2
        add     x3, x1, x2
        adcs    x4, x1, x2
        umulh   x5, x1, x2
        add     x6, x1, x2
        adcs    x7, x1, x2
        umulh   x8, x1, x2
        add     x9, x1, x2
        adcs    x10, x1, x2
        umulh   x11, x1, x2
        add     x12, x1, x2
        adcs    x13, x1, x2
        umulh   x14, x1, x2
        add     x15, x1, x2
        adcs    x16, x1, x2
        umulh   x17, x1, x2
        add     x18, x1, x2
        adcs    x10, x1, x2
        xxx_end

        xxx_begin xxx_umulh_adcs_adcs
        umulh   x3, x1, x2
        adcs    x4, x1, x2
        adcs    x5, x1, x2
        umulh   x6, x1, x2
        adcs    x7, x1, x2
        adcs    x8, x1, x2
        umulh   x9, x1, x2
        adcs    x10, x1, x2
        adcs    x11, x1, x2
        umulh   x12, x1, x2
        adcs    x13, x1, x2
        adcs    x14, x1, x2
        umulh   x15, x1, x2
        adcs    x16, x1, x2
        adcs    x17, x1, x2
        umulh   x18, x1, x2
        adcs    x3, x1, x2
        adcs    x4, x1, x2
        umulh   x5, x1, x2
        adcs    x6, x1, x2
        adcs    x7, x1, x2
        umulh   x8, x1, x2
        adcs    x9, x1, x2
        adcs    x10, x1, x2
        umulh   x11, x1, x2
        adcs    x12, x1, x2
        adcs    x13, x1, x2
        umulh   x14, x1, x2
        adcs    x15, x1, x2
        adcs    x16, x1, x2
        umulh   x17, x1, x2
        adcs    x18, x1, x2
        adcs    x10, x1, x2
        xxx_end

        xxx_begin xxx_umulh_adc_adds
        umulh   x3, x1, x2
        adc     x4, x1, x2
        adds    x5, x1, x2
        umulh   x6, x1, x2
        adc     x7, x1, x2
        adds    x8, x1, x2
        umulh   x9, x1, x2
        adc     x10, x1, x2
        adds    x11, x1, x2
        umulh   x12, x1, x2
        adc     x13, x1, x2
        adds    x14, x1, x2
        umulh   x15, x1, x2
        adc     x16, x1, x2
        adds    x17, x1, x2
        umulh   x18, x1, x2
        adc     x3, x1, x2
        adds    x4, x1, x2
        umulh   x5, x1, x2
        adc     x6, x1, x2
        adds    x7, x1, x2
        umulh   x8, x1, x2
        adc     x9, x1, x2
        adds    x10, x1, x2
        umulh   x11, x1, x2
        adc     x12, x1, x2
        adds    x13, x1, x2
        umulh   x14, x1, x2
        adc     x15, x1, x2
        adds    x16, x1, x2
        umulh   x17, x1, x2
        adc     x18, x1, x2
        adds    x10, x1, x2
        xxx_end

        xxx_begin xxx_umulh_adc_adds_depreg
        umulh   x3, x1, x2
        adc     x4, x1, x2
        adds    x5, x4, x2
        umulh   x6, x1, x2
        adc     x7, x1, x2
        adds    x8, x7, x2
        umulh   x9, x1, x2
        adc     x10, x1, x2
        adds    x11, x10, x2
        umulh   x12, x1, x2
        adc     x13, x1, x2
        adds    x14, x13, x2
        umulh   x15, x1, x2
        adc     x16, x1, x2
        adds    x17, x16, x2
        umulh   x18, x1, x2
        adc     x3, x1, x2
        adds    x4, x3, x2
        umulh   x5, x1, x2
        adc     x6, x1, x2
        adds    x7, x6, x2
        umulh   x8, x1, x2
        adc     x9, x1, x2
        adds    x10, x9, x2
        umulh   x11, x1, x2
        adc     x12, x1, x2
        adds    x13, x12, x2
        umulh   x14, x1, x2
        adc     x15, x1, x2
        adds    x16, x15, x2
        umulh   x17, x1, x2
        adc     x18, x1, x2
        adds    x10, x18, x2
        xxx_end

        xxx_begin xxx_mul_adcs_umulh_adcs
        .rept   2
        mul     x3, x1, x2
        adcs    x4, x1, x2
        umulh   x5, x1, x2
        adcs    x6, x1, x2
        mul     x7, x1, x2
        adcs    x8, x1, x2
        umulh   x9, x1, x2
        adcs    x10, x1, x2
        mul     x11, x1, x2
        adcs    x12, x1, x2
        umulh   x13, x1, x2
        adcs    x14, x1, x2
        mul     x15, x1, x2
        adcs    x16, x1, x2
        umulh   x17, x1, x2
        adcs    x18, x1, x2
        .endr
        xxx_end

        xxx_begin xxx_pacia
        .rept   2
        .irp    reg,ALL_REGS
        pacia   x\reg, sp
        .endr
        .endr
        xxx_end

        xxx_begin xxx_autia
        .rept   2
        .irp    reg,ALL_REGS
        autia   x\reg, sp
        .endr
        .endr
        xxx_end

        xxx_begin xxx_pacia_autia
        .irp    reg,ALL_REGS
        pacia   x\reg, sp
        autia   x\reg, sp
        .endr
        xxx_end

        xxx_begin xxx_pacia_autia_2
        .irp    reg,ALL_REGS
        pacia   x\reg, sp
        .endr
        .irp    reg,ALL_REGS
        autia   x\reg, sp
        .endr
        xxx_end
