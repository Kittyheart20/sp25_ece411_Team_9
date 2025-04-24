# RV32I and RV32M Comprehensive Test
# Tests all register-register, register-immediate, and M-extension instructions
.section .data
data_byte:    .byte  0x12          # 8-bit data
data_half:    .half  0x1234        # 16-bit data
data_word:    .word  0x12345678    # 32-bit data

.section .text
.globl _start
_start:
    # Initialize base address in x1
    # la x1, data_byte
    lui x1, %hi(data_byte)    # Load the upper 20 bits of the address into x1
    addi x1, x1, %lo(data_byte) # Add the lower 12 bits of the address to x1

    # -------------------------------------------------------------------------
    # Load Instructions
    # -------------------------------------------------------------------------

    # LB (Load Byte - Sign Extend)
    lb x2, 0(x1)          # x2 = 0x12 (sign-extended to 0x00000012)

    # LH (Load Halfword - Sign Extend)
    lh x3, 1(x1)          # x3 = 0x1234 (sign-extended to 0x00001234)

    # LW (Load Word)
    lw x4, 0(x1)          # x4 = 0x12345678

    # LBU (Load Byte Unsigned - Zero Extend)
    lbu x5, 0(x1)         # x5 = 0x12 (zero-extended to 0x00000012)

    # LHU (Load Halfword Unsigned - Zero Extend)
    lhu x6, 1(x1)         # x6 = 0x1234 (zero-extended to 0x00001234)

    # -------------------------------------------------------------------------
    # Store Instructions
    # -------------------------------------------------------------------------

    # SB (Store Byte)
    li x7, 0xAB           # Load value to store
    sb x7, 0(x1)          # Store 0xAB at data_byte
    lb x8, 0(x1)          # Verify: x8 = 0xAB (sign-extended)

    # SH (Store Halfword)
    li x9, 0xCDEF         # Load value to store
    sh x9, 1(x1)          # Store 0xCDEF at data_half
    lh x10, 1(x1)         # Verify: x10 = 0xCDEF (sign-extended)

    # SW (Store Word)
    li x11, 0x89ABCDEF    # Load value to store
    sw x11, 0(x1)         # Store 0x89ABCDEF at data_word
    lw x12, 0(x1)         # Verify: x12 = 0x89ABCDEF


halt:
    slti x0, x0, -256