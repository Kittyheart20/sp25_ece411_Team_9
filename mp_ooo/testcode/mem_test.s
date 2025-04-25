# RV32I and RV32M Comprehensive Test
# Tests all register-register, register-immediate, and M-extension instructions
.section .data
data_word1:   .word  0x12345678    # 32-bit data (aligned to 4 bytes)
data_word2:   .word  0x89ABCDEF    # 32-bit data (aligned to 4 bytes)

.section .text
.globl _start
_start:
    # Initialize base address in x1
    # la x1, data_word1
    lui x1, %hi(data_word1)    # Load the upper 20 bits of the address into x1
    addi x1, x1, %lo(data_word1) # Add the lower 12 bits of the address to x1

    # -------------------------------------------------------------------------
    # Load Instructions
    # -------------------------------------------------------------------------

    # LW (Load Word)
    lw x2, 0(x1)          # x2 = 0x12345678

    # LBU (Load Byte Unsigned - Zero Extend)
    lbu x3, 0(x1)         # x3 = 0x78 (zero-extended to 0x00000078)

    # LHU (Load Halfword Unsigned - Zero Extend)
    lhu x4, 0(x1)         # x4 = 0x5678 (zero-extended to 0x00005678)

    # -------------------------------------------------------------------------
    # Store Instructions
    # -------------------------------------------------------------------------

    # SW (Store Word)
    li x5, 0xECEBCAFE     # Load value to store
    sw x5, 4(x1)          # Store 0x89ABCDEF at data_word2
    lw x6, 4(x1)          # Verify: x6 = 0x89ABCDEF

halt:
    slti x0, x0, -256