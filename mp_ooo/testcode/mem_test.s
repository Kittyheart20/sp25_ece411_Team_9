# RV32I and RV32M Comprehensive Test
# Tests all register-register, register-immediate, and M-extension instructions
.section .data
data_byte:    .byte  0x12          # 8-bit data
data_half:    .half  0x1234        # 16-bit data
data_word:    .word  0x12345678    # 32-bit data

.section .text
.globl _start
_start:
    # Initialize registers with distinct values
    li x1, 0x00000001
    li x2, 0x00000002
    li x3, 0x00000003
    li x4, 0xFFFFFFFF    # -1 in two's complement
    li x5, 0x80000000    # Most negative number
    li x6, 0x7FFFFFFF    # Most positive number
    li x7, 0x0000000A    # 10
    li x8, 0x00000000    # 0 for div-by-zero test
    li x9, 0xAAAAAAAA    # Pattern for bitwise operations
    li x10, 0x55555555   # Alternate pattern for bitwise operations
    li x11, 0x00000100   # Small power of 2
    li x12, 0x00010000   # Larger power of 2
    li x13, 0x00000007   # Small prime
    li x14, 0x00000008   # Power of 2     - ORDER E
    
    # -------------------------------------------------------------------------
    # RV32I Register-Immediate Instructions
    # -------------------------------------------------------------------------
    
    # ADDI
    addi x15, x1, 10      # x15 = 1 + 10 = 11
    addi x16, x4, -5      # x16 = -1 + (-5) = -6    - ORDER 10
    
    # SLTI
    slti x17, x1, 2       # x17 = (1 < 2) ? 1 : 0 = 1
    slti x18, x2, 1       # x18 = (2 < 1) ? 1 : 0 = 0
    slti x19, x4, 0       # x19 = (-1 < 0) ? 1 : 0 = 1  - ORDER 13
    
    # SLTIU
    sltiu x20, x1, 2      # x20 = (1 < 2) ? 1 : 0 = 1
    sltiu x21, x4, 1      # x21 = (0xFFFFFFFF < 1) ? 1 : 0 = 0 (unsigned comparison)
    
    # XORI
    xori x22, x9, 0xFF    # x22 = 0xAAAAAAAA ^ 0x000000FF = 0xAAAAA955
    
    # ORI
    ori x23, x1, 0x100    # x23 = 0x00000001 | 0x00000100 = 0x00000101
    
    # ANDI
    andi x24, x9, 0xFF    # x24 = 0xAAAAAAAA & 0x000000FF = 0x000000AA
    
    # SLLI
    slli x25, x1, 4       # x25 = 1 << 4 = 16
    slli x26, x9, 8       # x26 = 0xAAAAAAAA << 8 = 0xAAAAAA00
    
    # SRLI
    srli x27, x11, 4      # Hex: 0x0045DDB3, x27 = 0x00000100 >> 4 = 0x00000010
    srli x28, x9, 8       # Hex: 0x0084DE13, x28 = 0xAAAAAAAA >> 8 = 0x00AAAAAA
    
    # SRAI
    srai x29, x11, 4      # Hex: 0x4045DE93, x29 = 0x00000100 >> 4 = 0x00000010
    srai x30, x4, 4       # Hex: 0x40425F13, x30 = 0xFFFFFFFF >> 4 = 0xFFFFFFFF (sign extension)
    srai x31, x5, 4       # Hex: 0x4042DF93, x31 = 0x80000000 >> 4 = 0xF8000000 (sign extension)
    
    # -------------------------------------------------------------------------
    # RV32I Register-Register Instructions
    # -------------------------------------------------------------------------
    
    # ADD
    add x15, x1, x2       # Hex: 0x002087B3, x15 = 1 + 2 = 3
    add x16, x4, x1       # Hex: 0x00120833,, x16 = -1 + 1 = 0
    
    # SUB
    sub x17, x2, x1       # x17 = 2 - 1 = 1
    sub x18, x1, x2       # x18 = 1 - 2 = -1
    
    # SLL
    sll x19, x1, x2       # x19 = 1 << 2 = 4
    
    # SLT
    slt x20, x1, x2       # x20 = (1 < 2) ? 1 : 0 = 1
    slt x21, x2, x1       # x21 = (2 < 1) ? 1 : 0 = 0
    slt x22, x4, x1       # x22 = (-1 < 1) ? 1 : 0 = 1
    
    # SLTU
    sltu x23, x1, x2      # x23 = (1 < 2) ? 1 : 0 = 1
    sltu x24, x4, x1      # x24 = (0xFFFFFFFF < 1) ? 1 : 0 = 0 (unsigned comparison)
    
    # XOR
    xor x25, x9, x10      # x25 = 0xAAAAAAAA ^ 0x55555555 = 0xFFFFFFFF
    
    # SRL
    srl x26, x11, x1      # x26 = 0x00000100 >> 1 = 0x00000080
    
    # SRA
    sra x27, x11, x1      # x27 = 0x00000100 >> 1 = 0x00000080
    sra x28, x4, x1       # x28 = 0xFFFFFFFF >> 1 = 0xFFFFFFFF (sign extension)
    
    # OR
    or x29, x9, x10       # x29 = 0xAAAAAAAA | 0x55555555 = 0xFFFFFFFF
    
    # AND
    and x30, x9, x10      # x30 = 0xAAAAAAAA & 0x55555555 = 0x00000000   # STOPS HERE
    
    # -------------------------------------------------------------------------
    # RV32M Multiply Instructions
    # -------------------------------------------------------------------------
    
    # MUL (lower 32 bits of product)
    mul x15, x7, x13      # x15 = 10 * 7 = 70
    nop
    nop
    nop
    mul x16, x4, x2       # x16 = -1 * 2 = -2
    and x30, x9, x10      # x30 = 0xAAAAAAAA & 0x55555555 = 0x00000000

    # MULH (upper 32 bits of signed * signed)
    mulh x17, x5, x5      # x17 = upper((0x80000000 * 0x80000000)) = 0x40000000
    mulh x0, x0, x0
    mulh x18, x6, x6      # x18 = upper((0x7FFFFFFF * 0x7FFFFFFF)) = 0x3FFFFFFF
    
    # MULHSU (upper 32 bits of signed * unsigned)
    mulhsu x19, x5, x6    # x19 = upper((signed)0x80000000 * (unsigned)0x7FFFFFFF)
    mulhsu x20, x4, x7    # x20 = upper((signed)-1 * (unsigned)10) #instr 53


    # MULHU (upper 32 bits of unsigned * unsigned)
    mulhu x21, x6, x6     # x21 = upper((unsigned)0x7FFFFFFF * (unsigned)0x7FFFFFFF)
    mulhu x22, x9, x10    # x22 = upper((unsigned)0xAAAAAAAA * (unsigned)0x55555555)
    
    # -------------------------------------------------------------------------
    # RV32M Divide Instructions
    # -------------------------------------------------------------------------
    
    # DIV (signed division)
    div x23, x7, x13      # x23 = 10 / 7 = 1
    div x24, x7, x4       # x24 = 10 / -1 = -10
    div x25, x5, x1       # x25 = 0x80000000 / 1 = 0x80000000
    div x26, x1, x8       # x26 = 1 / 0 = -1 (division by zero)
    div x27, x5, x4       # x27 = 0x80000000 / -1 = 0x80000000 (overflow case)
    
    # DIVU (unsigned division)
    divu x28, x7, x13     # x28 = 10 / 7 = 1
    divu x29, x4, x2      # x29 = 0xFFFFFFFF / 2 = 0x7FFFFFFF
    divu x30, x1, x8      # x30 = 1 / 0 = 0xFFFFFFFF (division by zero)
    
    # REM (signed remainder)
    rem x15, x7, x13      # x15 = 10 % 7 = 3
    rem x16, x7, x4       # x16 = 10 % -1 = 0
    rem x17, x5, x1       # x17 = 0x80000000 % 1 = 0
    rem x18, x1, x8       # x18 = 1 % 0 = 1 (division by zero)
    rem x19, x5, x4       # x19 = 0x80000000 % -1 = 0 (overflow case)
    
    # REMU (unsigned remainder)
    remu x20, x7, x13     # x20 = 10 % 7 = 3
    remu x21, x4, x2      # x21 = 0xFFFFFFFF % 2 = 1
    remu x22, x1, x8      # x22 = 1 % 0 = 1 (division by zero)
    
    # -------------------------------------------------------------------------
    # Additional tests to exercise OoO execution
    # -------------------------------------------------------------------------
    
    # Create dependencies that can be resolved out-of-order
    addi x1, x0, 100
    addi x2, x0, 200
    addi x3, x0, 300
    
    # Independent operations that can execute in parallel
    mul x4, x1, x2        # Can execute while the following instructions are being processed
    add x5, x1, x3
    xor x6, x2, x3
    and x7, x1, x2
    
    # Create a dependency chain with intermediate results
    addi x8, x0, 5
    mul x9, x8, x8        # x9 = 25
    add x10, x9, x9       # x10 = 50, depends on x9
    div x11, x10, x8      # x11 = 10, depends on x10 and x8
    rem x12, x11, x8      # x12 = 0, depends on x11 and x8
    
    # Create potential for memory forwarding
    addi x13, x0, 1
    addi x14, x0, 2
    mul x15, x13, x14     # x15 = 2
    add x13, x15, x13     # x13 = 3, depends on x15
    sub x14, x13, x15     # x14 = 1, depends on both x13 and x15
    
    # Test for potential hazards
    addi x16, x0, 10
    div x17, x16, x13     # Division with result from previous computation
    mul x18, x17, x14     # Multiply with results from previous computations
    rem x19, x18, x16     # Remainder with results from previous computations

    # Initialize registers with test values
    li x1, 10           # Small positive value
    li x2, -15          # Negative value
    li x3, 0x7FFFFFFF   # Most positive 32-bit value
    li x4, 0x80000000   # Most negative 32-bit value
    li x5, 0            # Zero (will be used as divisor)
    li x6, 1            # For comparison

    # -------------------------------------------------------------------------
    # Test 1: DIV - Signed Division by Zero
    # Expected result: 0xFFFFFFFF (-1)
    # -------------------------------------------------------------------------
    div x10, x1, x5     # 10 / 0 = -1 (all 1's)
    div x11, x2, x5     # -15 / 0 = -1 (all 1's)
    div x12, x3, x5     # 0x7FFFFFFF / 0 = -1 (all 1's)
    div x13, x4, x5     # 0x80000000 / 0 = -1 (all 1's)
    
    # -------------------------------------------------------------------------
    # Test 2: DIVU - Unsigned Division by Zero
    # Expected result: 0xFFFFFFFF (all 1's)
    # -------------------------------------------------------------------------
    divu x14, x1, x5    # 10 / 0 = 0xFFFFFFFF
    divu x15, x2, x5    # 0xFFFFFFF1 / 0 = 0xFFFFFFFF (x2 is treated as unsigned)
    divu x16, x3, x5    # 0x7FFFFFFF / 0 = 0xFFFFFFFF
    divu x17, x4, x5    # 0x80000000 / 0 = 0xFFFFFFFF
    
    # -------------------------------------------------------------------------
    # Test 3: REM - Signed Remainder by Zero
    # Expected result: Dividend is returned unchanged
    # -------------------------------------------------------------------------
    rem x18, x1, x5     # 10 % 0 = 10
    rem x19, x2, x5     # -15 % 0 = -15
    rem x20, x3, x5     # 0x7FFFFFFF % 0 = 0x7FFFFFFF
    rem x21, x4, x5     # 0x80000000 % 0 = 0x80000000
    
    # -------------------------------------------------------------------------
    # Test 4: REMU - Unsigned Remainder by Zero
    # Expected result: Dividend is returned unchanged
    # -------------------------------------------------------------------------
    remu x22, x1, x5    # 10 % 0 = 10
    remu x23, x2, x5    # 0xFFFFFFF1 % 0 = 0xFFFFFFF1
    remu x24, x3, x5    # 0x7FFFFFFF % 0 = 0x7FFFFFFF
    remu x25, x4, x5    # 0x80000000 % 0 = 0x80000000
    
    # -------------------------------------------------------------------------
    # Test 5: Special Case - Division Overflow
    # DIV: Most negative value divided by -1 should return the same value
    # -------------------------------------------------------------------------
    li x5, -1           # Divisor = -1
    div x26, x4, x5     # 0x80000000 / -1 = 0x80000000 (overflow)
    rem x27, x4, x5     # 0x80000000 % -1 = 0


    # Initialize registers with test values
    li x1, 0x80000000   # Most negative 32-bit value (-2^31)
    li x2, 0xFFFFFFFF   # -1 in two's complement
    li x3, 0x00000001   # 1

    # Test 1: DIV Overflow - Most negative value divided by -1
    # Expected: 0x80000000 (same as dividend, due to overflow)
    div x10, x1, x2     # (-2^31) / (-1) = 2^31, but that overflows 32-bit signed int

    # Test 2: REM with DIV Overflow
    # Expected: 0 (remainder is always 0 when dividing by -1)
    rem x11, x1, x2     # (-2^31) % (-1) = 0

    # Test 3: DIVU with large values (no overflow, but good boundary test)
    # Expected: 0x80000000 (treated as unsigned division)
    divu x12, x1, x3    # (2^31) / 1 = 2^31

    # Test 4: REMU with large values
    # Expected: 0 (no remainder when dividing by 1)
    remu x13, x1, x3    # (2^31) % 1 = 0

    # Initialize registers with test values
    li x1, 0x80000000   # Most negative 32-bit value (-2^31)
    li x2, 0xFFFFFFFF   # -1 in two's complement
    li x3, 0x7FFFFFFF   # Maximum positive 32-bit value (2^31-1)
    li x4, 0x00000002   # 2

    # Test 1: MUL with overflow (low bits)
    # Expected: 0x00000000 (low 32 bits of (-2^31) * (-1) = 2^31)
    mul x14, x1, x2     # (-2^31) * (-1) = 2^31, but we only get lower 32 bits

    # Test 2: MULH with overflow (high bits)
    # Expected: 0x00000000 (high 32 bits of (-2^31) * (-1) = 0)
    mulh x15, x1, x2    # High 32 bits of (-2^31) * (-1)

    # Test 3: MULHU with large values
    # Expected: 0x7FFFFFFF (high 32 bits of unsigned multiplication)
    mulhu x16, x3, x4   # High 32 bits of (2^31-1) * 2 as unsigned

    # Test 4: MULHSU with mixed signs
    # Expected: Will depend on implementation, tests signed * unsigned
    mulhsu x17, x1, x3  # High 32 bits of (-2^31) * (2^31-1) as signed * unsigned

    # Initialize registers
    li x1, 0x80000000   # Most negative 32-bit value (-2^31)
    li x2, 0x00000001   # 1
    li x3, 0xFFFFFFFF   # -1 in two's complement

    # Test 1: DIV followed by MUL (tests overflow handling chain)
    div x18, x1, x3     # Should return 0x80000000 (overflow)
    mul x19, x18, x2    # Should return 0x80000000 (no overflow, just passing through)

    # Test 2: MUL followed by DIV (tests another chain)
    mul x20, x1, x3     # Should return 0x80000000 (lower bits)
    div x21, x20, x3    # Should return 0x80000000 (overflow again)

    # Test 3: Extreme value division chain
    div x22, x1, x3     # 0x80000000 (overflow)
    div x23, x22, x3    # 0x80000000 (overflow again)
    div x24, x23, x2    # 0x80000000 (normal division, no overflow)


        # Initialize registers with known values
    li x1, 0x00000001
    li x2, 0x00000002
    li x3, 0x00000003
    li x4, 0x00000004
    li x5, 0x00000005
    li x6, 0x00000006
    li x7, 0x00000007
    li x8, 0x00000008

    # -------------------------------------------------------------------------
    # Test 1: RAW (Read-After-Write) Hazards
    # -------------------------------------------------------------------------
    
    # RAW with immediate dependency (distance=1)
    add x10, x1, x2      # x10 = 1 + 2 = 3
    sub x11, x10, x3     # RAW: x11 = x10 - 3 = 0
    
    # RAW with longer dependency chain (distance=2)
    add x12, x4, x5      # x12 = 4 + 5 = 9
    xor x13, x6, x7      # Independent operation
    or  x14, x12, x8     # RAW: x14 = x12 | 8 = 9 | 8 = 9
    
    # RAW with multiple consumers
    mul x15, x1, x2      # x15 = 1 * 2 = 2 (long latency operation)
    add x16, x15, x3     # RAW: x16 = x15 + 3 = 5
    sub x17, x15, x4     # RAW: x17 = x15 - 4 = -2
    
    # -------------------------------------------------------------------------
    # Test 2: WAR (Write-After-Read) Hazards
    # -------------------------------------------------------------------------
    
    # WAR hazard (distance=1)
    add x20, x1, x2      # x20 = 1 + 2 = 3
    add x1, x3, x4       # WAR: x1 = 3 + 4 = 7 (x1 read by previous instruction)
    
    # WAR with operations between (distance=2)
    or  x21, x5, x6      # x21 = 5 | 6 = 7
    xor x22, x7, x8      # Independent operation
    add x5, x1, x3       # WAR: x5 = 7 + 3 = 10 (x5 read by first instruction)
    
    # WAR with long-latency operation
    div x23, x2, x3      # x23 = 2 / 3 = 0 (long latency, reads x2 and x3)
    add x2, x4, x5       # WAR: x2 = 4 + 10 = 14 (x2 read by previous instruction)
    add x3, x6, x7       # WAR: x3 = 6 + 7 = 13 (x3 read by previous instruction)
    
    # -------------------------------------------------------------------------
    # Test 3: WAW (Write-After-Write) Hazards
    # -------------------------------------------------------------------------
    
    # WAW hazard (distance=1)
    add x25, x1, x2      # x25 = 7 + 14 = 21
    sub x25, x3, x4      # WAW: x25 = 13 - 4 = 9 (overwrites previous x25)
    
    # WAW with operations between (distance=2)
    add x26, x5, x6      # x26 = 10 + 6 = 16
    xor x27, x7, x8      # Independent operation
    mul x26, x1, x2      # WAW: x26 = 7 * 14 = 98 (overwrites previous x26)
    
    # WAW with different latency operations
    div x28, x2, x3      # x28 = 14 / 13 = 1 (long latency)
    add x28, x1, x5      # WAW: x28 = 7 + 10 = 17 (shorter latency, should complete first)
    
    # -------------------------------------------------------------------------
    # Test 4: Complex Mixed Hazards
    # -------------------------------------------------------------------------
    
    # Complex RAW + WAW chain
    add x29, x1, x2      # x29 = 7 + 14 = 21
    mul x30, x29, x3     # RAW: x30 = 21 * 13 = 273
    add x29, x30, x4     # RAW + WAW: x29 = 273 + 4 = 277
    
    # Complex RAW + WAR chain
    add x31, x5, x6      # x31 = 10 + 6 = 16
    mul x5, x31, x7      # RAW + WAR: x5 = 16 * 7 = 112
    add x31, x5, x8      # RAW + WAW: x31 = 112 + 8 = 120

    mul x1, x1, x1
    mul x1, x1, x1
    mul x1, x1, x1

    mul x2, x2, x2
    add x2, x2, x2
    mul x2, x2, x2


    # Initialize registers with critical values
    li x1, 0x80000000   # Most negative 32-bit value (-2^31)
    li x2, 0xFFFFFFFF   # -1 in two's complement
    li x3, 0x7FFFFFFF   # Most positive 32-bit value (2^31-1)
    li x4, 0x00000000   # Zero
    li x5, 0x00000001   # One
    li x6, 0x00000002   # Two

    # ===== Multiplication Edge Cases =====
    
    # 1. Extreme value multiplication
    mul  x10, x1, x2    # (-2^31) * (-1) = 2^31, but truncated to 32 bits
    mulh x11, x1, x2    # High bits of (-2^31) * (-1)
    
    # 2. Multiply by zero
    mul  x12, x3, x4    # (2^31-1) * 0 = 0
    mulh x13, x3, x4    # High bits should be 0
    
    # 3. Overflow cases
    mul  x14, x3, x6    # (2^31-1) * 2 = 2^32-2 (truncated to -2 in 32 bits)
    mulh x15, x3, x6    # High bits should be 0
    
    # 4. MULHSU with critical values
    mulhsu x16, x1, x3  # High bits of (-2^31) * (2^31-1) as signed * unsigned
    mulhsu x17, x2, x3  # High bits of (-1) * (2^31-1) as signed * unsigned
    
    # 5. MULHU with large values
    mulhu x18, x3, x3   # High bits of (2^31-1) * (2^31-1) as unsigned
    
    # ===== Division Edge Cases =====
    
    # 6. Division by zero
    div  x20, x1, x4    # (-2^31) / 0 = -1 (all 1's)
    divu x21, x3, x4    # (2^31-1) / 0 = all 1's
    rem  x22, x1, x4    # (-2^31) % 0 = (-2^31)
    remu x23, x3, x4    # (2^31-1) % 0 = (2^31-1)
    
    # 7. Division overflow
    div  x24, x1, x2    # (-2^31) / (-1) = 2^31, but overflow to (-2^31)
    rem  x25, x1, x2    # (-2^31) % (-1) = 0
    
    # 8. Division edge cases
    div  x26, x4, x5    # 0 / 1 = 0
    div  x27, x5, x5    # 1 / 1 = 1
    rem  x28, x3, x5    # (2^31-1) % 1 = 0
    
    # 9. Unsigned vs signed division
    div  x29, x2, x6    # -1 / 2 = 0 (signed)
    divu x30, x2, x6    # 0xFFFFFFFF / 2 = 0x7FFFFFFF (unsigned)

# Test Suite for Data Hazard Stress Testing
.section .text

    # Initialize registers
    li x1, 1
    li x2, 2
    
    # ===== RAW Hazards with Mixed Operations =====
    
    # 1. ALU -> MUL RAW Hazard
    add  x3, x1, x2     # x3 = 3
    mul  x4, x3, x2     # x4 = 6, RAW on x3
    
    # 2. MUL -> DIV RAW Hazard
    mul  x5, x1, x2     # x5 = 2
    div  x6, x3, x5     # x6 = 1, RAW on x5
    
    # 3. DIV -> ALU RAW Hazard
    div  x7, x4, x2     # x7 = 3
    add  x8, x7, x1     # x8 = 4, RAW on x7
    
    # 4. Long chain of RAW dependencies
    add  x9, x1, x2     # x9 = 3
    mul  x10, x9, x2    # x10 = 6, RAW on x9
    div  x11, x10, x2   # x11 = 3, RAW on x10
    rem  x12, x11, x2   # x12 = 1, RAW on x11
    sub  x13, x12, x1   # x13 = 0, RAW on x12
    
    # ===== WAR Hazards with Mixed Operations =====
    
    # 5. WAR Hazard with MUL
    add  x14, x1, x2    # x14 = 3, reads x1
    mul  x1, x2, x2     # x1 = 4, WAR on x1
    
    # 6. WAR Hazard with DIV
    mul  x15, x2, x2    # x15 = 4, reads x2
    div  x2, x4, x3     # x2 = 2, WAR on x2
    
    # ===== WAW Hazards with Mixed Operations =====
    
    # 7. WAW Hazard with different latency ops
    div  x16, x4, x2    # x16 = 3 (slow operation)
    add  x16, x1, x2    # x16 = 6 (fast operation)
    
    # 8. WAW Hazard chain
    mul  x17, x2, x2    # x17 = 4
    div  x17, x4, x2    # x17 = 2
    add  x17, x1, x1    # x17 = 2


# Test Suite for Instruction Interleaving and Parallelism
.section .text

    # Initialize registers
    li x1, 1
    li x2, 2
    li x3, 3
    li x4, 4
    
    # ===== Parallel Independent Operations =====
    
    # 1. Independent ALU operations
    add  x5, x1, x2     # x5 = 3
    sub  x6, x4, x3     # x6 = 1
    xor  x7, x3, x4     # x7 = 7
    or   x8, x1, x2     # x8 = 3
    
    # 2. Mix of independent ALU and MUL/DIV
    add  x9, x1, x2     # x9 = 3
    mul  x10, x3, x4    # x10 = 12
    sub  x11, x4, x1    # x11 = 3
    div  x12, x4, x2    # x12 = 2
    
    # ===== Interleaved Dependent Operations =====
    
    # 3. Interleaved dependency chains
    add  x13, x1, x2    # x13 = 3 (Chain A start)
    mul  x14, x3, x4    # x14 = 12 (Chain B start)
    add  x15, x13, x1   # x15 = 4 (Chain A continues)
    mul  x16, x14, x2   # x16 = 24 (Chain B continues)
    add  x17, x15, x1   # x17 = 5 (Chain A end)
    mul  x18, x16, x2   # x18 = 48 (Chain B end)
    
    # 4. Cross-chain dependencies
    add  x19, x1, x2    # x19 = 3 (Chain C start)
    mul  x20, x3, x4    # x20 = 12 (Chain D start)
    add  x21, x19, x20  # x21 = 15 (Depends on both chains)
    div  x22, x21, x2   # x22 = 7 (Continues from merged chain)

# Test Suite for Complex Mixed Operations
.section .text

    # Initialize registers with prime numbers
    li x1, 2
    li x2, 3
    li x3, 5
    li x4, 7
    li x5, 11
    li x6, 13
    
    # 1. Multi-step calculation with mixed operations
    mul  x10, x1, x2    # x10 = 6
    add  x11, x3, x4    # x11 = 12
    div  x12, x11, x1   # x12 = 6
    rem  x13, x5, x3    # x13 = 1
    mul  x14, x12, x13  # x14 = 6
    sub  x15, x10, x14  # x15 = 0
    
    # 2. Long dependency chain with all operation types
    add  x16, x1, x2    # x16 = 5
    mul  x17, x16, x3   # x17 = 25
    div  x18, x17, x4   # x18 = 3
    rem  x19, x18, x2   # x19 = 0
    sub  x20, x5, x19   # x20 = 11
    xor  x21, x20, x6   # x21 = 6
    or   x22, x21, x1   # x22 = 6
    and  x23, x22, x5   # x23 = 2
    
    # 3. Repeated operations on same registers
    add  x24, x1, x2    # x24 = 5
    add  x24, x24, x3   # x24 = 10
    mul  x24, x24, x2   # x24 = 30
    div  x24, x24, x4   # x24 = 4
    rem  x24, x24, x3   # x24 = 4
    
    # 4. Fibonacci calculation using mixed operations
    li   x25, 1         # First Fibonacci number
    li   x26, 1         # Second Fibonacci number
    add  x27, x25, x26  # x27 = 2 (Third Fibonacci)
    mul  x28, x27, x1   # x28 = 4 (just doubling)
    add  x29, x26, x27  # x29 = 3 (Fourth Fibonacci)
    div  x30, x28, x2   # x30 = 1 (integer division)


    # Test for handling long dependency chains on the same register
    # Stresses register renaming and result forwarding

    li x1, 1
    li x2, 2

    # Chain with increasing operation latency
    add  x3, x1, x2       # x3 = 3
    add  x3, x3, x3       # x3 = 6
    mul  x3, x3, x3       # x3 = 36
    div  x3, x3, x2       # x3 = 18
    mul  x3, x3, x3       # x3 = 324
    add  x3, x3, x1       # x3 = 325

    # Chain with decreasing operation latency
    div  x4, x1, x1       # x4 = 1
    mul  x4, x4, x2       # x4 = 2
    add  x4, x4, x4       # x4 = 4
    add  x4, x4, x1       # x4 = 5

    # Interleaved operations on multiple registers
    add  x5, x1, x2       # x5 = 3
    add  x6, x1, x2       # x6 = 3
    mul  x5, x5, x2       # x5 = 6
    mul  x6, x6, x2       # x6 = 6
    add  x5, x5, x6       # x5 = 12
    mul  x6, x5, x6       # x6 = 72

    # Test for scenarios where dependencies are resolved out of order
    # Stresses reservation station dependency tracking

    li x1, 1
    li x2, 2
    li x3, 3

    # Long-latency operation followed by dependent short-latency operations
    div  x4, x3, x1       # x4 = 3 (long latency)
    add  x5, x4, x1       # x5 = 4 (depends on div)
    add  x6, x4, x2       # x6 = 5 (depends on div)
    add  x7, x5, x6       # x7 = 9 (depends on both adds)

    # Independent operations that could execute during div
    mul  x8, x2, x3       # x8 = 6
    add  x9, x1, x1       # x9 = 2

    # Operations that depend on results of independent ops
    add  x10, x8, x9      # x10 = 8 (should complete before div results)
    mul  x11, x10, x4     # x11 = 24 (mixes early and late dependencies)

    # Test for correct reservation station reuse
    # Stresses allocation and deallocation timing

    li x1, 1
    li x2, 2
    li x3, 3

    # Fill multiple reservation stations of same type
    add  x4, x1, x2       # RS-ADD1: x4 = 3
    add  x5, x2, x3       # RS-ADD2: x5 = 5
    add  x6, x3, x1       # RS-ADD3: x6 = 4

    # Long latency operation
    div  x7, x3, x1       # RS-DIV1: x7 = 3

    # More adds that need to reuse stations
    add  x8, x4, x5       # Reuses RS-ADD1 after first add completes: x8 = 8
    add  x9, x5, x6       # Reuses RS-ADD2 after second add completes: x9 = 9
    add  x10, x6, x4      # Reuses RS-ADD3 after third add completes: x10 = 7

    # Operation dependent on division (forces specific execution order)
    mul  x11, x7, x2      # RS-MUL1: x11 = 6 (must wait for div)

    # More adds that create complex reuse patterns
    add  x12, x8, x9      # Reuses RS-ADD1 again: x12 = 17
    add  x13, x9, x10     # Reuses RS-ADD2 again: x13 = 16
    add  x14, x10, x11    # Reuses RS-ADD3 again, but depends on mul: x14 = 13

    # Test for handling multiple results ready for writeback simultaneously
    # Stresses CDB arbitration and result forwarding

    li x1, 1
    li x2, 2
    li x3, 4

    # Start multiple operations with same latency
    mul  x4, x2, x3       # x4 = 8
    mul  x5, x3, x3       # x5 = 16
    mul  x6, x1, x3       # x6 = 4

    # Operations dependent on results (test writeback prioritization)
    add  x7, x4, x1       # x7 = 9
    add  x8, x5, x1       # x8 = 17
    add  x9, x6, x1       # x9 = 5

    # Operations that depend on multiple prior results
    add  x10, x4, x5      # x10 = 24
    add  x11, x5, x6      # x11 = 20
    add  x12, x6, x4      # x12 = 12

    # Final operation dependent on all results
    add  x13, x10, x11    # x13 = 44
    add  x13, x13, x12    # x13 = 56

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