# RV32I and RV32M Comprehensive Test
# Tests all register-register, register-immediate, and M-extension instructions

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
    and x30, x9, x10      # x30 = 0xAAAAAAAA & 0x55555555 = 0x00000000
    
    # -------------------------------------------------------------------------
    # RV32M Multiply Instructions
    # -------------------------------------------------------------------------
    
    # MUL (lower 32 bits of product)
    mul x15, x7, x13      # x15 = 10 * 7 = 70
    mul x16, x4, x2       # x16 = -1 * 2 = -2
    
    # MULH (upper 32 bits of signed * signed)
    mulh x17, x5, x5      # x17 = upper((0x80000000 * 0x80000000)) = 0x40000000
    mulh x18, x6, x6      # x18 = upper((0x7FFFFFFF * 0x7FFFFFFF)) = 0x3FFFFFFF
    
    # MULHSU (upper 32 bits of signed * unsigned)
    mulhsu x19, x5, x6    # x19 = upper((signed)0x80000000 * (unsigned)0x7FFFFFFF)
    mulhsu x20, x4, x7    # x20 = upper((signed)-1 * (unsigned)10)
    
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


    # Other tests
    add x16, x16, x16
    div x17, x16, x13     # Division with result from previous computation
    mul x17, x17, x17     # Multiply with results from previous computations
    rem x19, x18, x17     # Remainder with results from previous computations
    mul x15, x13, x14     # x15 = 2
    add x13, x15, x13     # x13 = 3, depends on x15
    sub x14, x13, x15     # x14 = 1, depends on both x13 and x15
    
halt:
    slti x0, x0, -256