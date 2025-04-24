# RV32I and RV32M Comprehensive Test
# Tests all register-register, register-immediate, and M-extension instructions

.globl _start
_start:

# AUIPC Test Suite (No Load/Store)
    # Initialize with immediate values only
    addi x31, x0, 0      # Clear register for comparisons
    
    # Test 1: Basic AUIPC functionality
    auipc x1, 0          # x1 = PC (aligned to 4K boundary)
    auipc x2, 1          # x2 = PC + 4K
    
    # Test 2: Verify PC alignment and difference
    auipc x3, 0          # x3 = PC at this point
    sub x4, x3, x1       # x4 = Difference between PCs (instruction bytes)
    
    # Test 3: AUIPC with larger immediates
    auipc x5, 0xFFF      # x5 = PC + 0xFFF000 (maximum positive offset)
    auipc x6, 0x800      # x6 = PC + 0x800000
    sub x7, x5, x6       # x7 = Difference between offsets (should be 0x7FF000 + PC delta)
    
    # Test 4: AUIPC with negative immediates
    auipc x8, 0xFFFFF    # x8 = PC - 4K (maximum negative offset)
    auipc x9, 0x80000    # x9 = PC - 0x800000
    sub x10, x8, x9      # x10 = Difference between offsets
    
    # Test 5: AUIPC for PC-relative calculations without loads
    auipc x11, 0         # x11 = Current PC
    addi x12, x11, 24    # x12 = PC + 24 (pointing to where data might be)
    addi x13, x0, 0x42   # Just a marker value instead of loading






# # M-Extension Test Suite (No Load/Store)
# .section .text

#     # Initialize with immediate values
#     addi x1, x0, 1       # x1 = 1
#     addi x2, x0, 2       # x2 = 2
#     addi x3, x0, -1      # x3 = -1
#     addi x4, x0, 0       # x4 = 0
#     addi x5, x0, 10      # x5 = 10
#     addi x6, x0, -10     # x6 = -10
#     lui x7, 0x7FFFF      # \
#     addi x7, x7, 0xFFF   # / x7 = 0x7FFFFFFF (MAX_INT)
#     lui x8, 0x80000      # x8 = 0x80000000 (MIN_INT)
    
#     #---------- Multiplication Tests ----------#
    
#     # Test 1: Basic multiplication
#     mul x10, x1, x2      # x10 = 1 * 2 = 2
#     mul x11, x2, x5      # x11 = 2 * 10 = 20
    
#     # Test 2: Multiplication with zero
#     mul x12, x5, x4      # x12 = 10 * 0 = 0
#     mul x13, x4, x3      # x13 = 0 * (-1) = 0
    
#     # Test 3: Multiplication with negative values
#     mul x14, x5, x3      # x14 = 10 * (-1) = -10
#     mul x15, x6, x3      # x15 = (-10) * (-1) = 10
#     mul x16, x6, x2      # x16 = (-10) * 2 = -20
    
#     # Test 4: Overflow cases
#     mul x17, x7, x2      # x17 = MAX_INT * 2 (lower 32 bits)
#     mul x18, x8, x3      # x18 = MIN_INT * (-1) (lower 32 bits)
    
#     # Test 5: MULH variants
#     mulh x19, x7, x7     # x19 = high bits of MAX_INT * MAX_INT
#     mulh x20, x8, x3     # x20 = high bits of MIN_INT * (-1)
#     mulhu x21, x7, x7    # x21 = high bits of MAX_INT * MAX_INT (unsigned)
#     mulhsu x22, x3, x7   # x22 = high bits of (-1) * MAX_INT (signed*unsigned)
    
#     #---------- Division Tests ----------#
    
#     # Test 6: Basic division
#     div x23, x5, x2      # x23 = 10 / 2 = 5
#     div x24, x5, x1      # x24 = 10 / 1 = 10
    
#     # Test 7: Division with negative values
#     div x25, x5, x3      # x25 = 10 / (-1) = -10
#     div x26, x6, x3      # x26 = (-10) / (-1) = 10
#     div x27, x6, x2      # x27 = (-10) / 2 = -5
    
#     # Test 8: Division by zero
#     div x28, x5, x4      # x28 = 10 / 0 = -1 (all 1's)
#     div x29, x4, x4      # x29 = 0 / 0 = -1 (all 1's)
    
#     # Test 9: Division overflow
#     div x30, x8, x3      # x30 = MIN_INT / (-1) = overflow (returns MIN_INT)
    
#     # Test 10: Unsigned division
#     divu x9, x5, x2      # x9 = 10 / 2 = 5 (unsigned)
    
#     # Test 11: Remainder operations
#     rem x10, x5, x2      # x10 = 10 % 2 = 0
#     rem x11, x5, x3      # x11 = 10 % (-1) = 0
#     rem x12, x6, x2      # x12 = (-10) % 2 = 0
    
#     # Test 12: Remainder with zero divisor
#     rem x13, x5, x4      # x13 = 10 % 0 = 10 (return dividend)
#     remu x14, x5, x4     # x14 = 10 % 0 = 10 (unsigned)






# Jump and Branch Test Suite (No Load/Store)

    # Initialize with immediate values
    addi x1, x0, 1
    addi x2, x0, 2
    addi x3, x0, 10
    addi x4, x0, -10
    addi x31, x0, 0      # Success counter
    
    #---------- JAL Tests ----------#
    
    # Test 1: Basic JAL
    jal x5, jal_target1
    addi x31, x31, 100   # Should be skipped
    
jal_target1:
    addi x31, x31, 1     # Success marker
    sub x6, x5, x0       # Save return address
    
    # Test 2: JAL with backward jump
    jal x7, jal_forward
    
jal_backward_target:
    addi x31, x31, 1     # Success marker
    jal x0, jal_backward_done
    
jal_forward:
    addi x31, x31, 1     # Success marker
    jal x8, jal_backward_target
    
jal_backward_done:
    addi x31, x31, 1     # Success marker
    
    #---------- JALR Tests ----------#
    
    # Test 3: JALR with computed address
    # We'll use PC-relative addressing with AUIPC instead of loads
    auipc x9, 0          # Get current PC
    addi x9, x9, 16      # Point to jalr_target1 (offset calculated at assembly)
    jalr x10, 0(x9)      # Jump to computed address
    addi x31, x31, 100   # Should be skipped
    
jalr_target1:
    addi x31, x31, 1     # Success marker
    
    # Test 4: JALR with offset
    auipc x11, 0         # Get current PC
    addi x11, x11, 20    # Base address
    jalr x12, 8(x11)     # Jump to base+8
    addi x31, x31, 100   # Should be skipped
    
    addi x31, x31, 100   # Should be skipped
    addi x31, x31, 1     # Success marker (target of jalr)
    
    # Test 5: Function call pattern
    jal x13, function1
    addi x31, x31, 1     # Success marker (after function return)
    jal x0, branch_tests
    
function1:
    addi x31, x31, 1     # Success marker (in function)
    jalr x0, 0(x13)      # Return
    
    #---------- Branch Tests ----------#
branch_tests:
    # Test 6: BEQ tests
    beq x1, x1, beq_taken
    addi x31, x31, 100   # Should be skipped
    
beq_taken:
    addi x31, x31, 1     # Success marker
    
    beq x1, x2, beq_not_taken
    addi x31, x31, 1     # Success marker
    jal x0, beq_done
    
beq_not_taken:
    addi x31, x31, 100   # Should be skipped
    
beq_done:
    
    # Test 7: BNE tests
    bne x1, x2, bne_taken
    addi x31, x31, 100   # Should be skipped
    
bne_taken:
    addi x31, x31, 1     # Success marker
    
    bne x1, x1, bne_not_taken
    addi x31, x31, 1     # Success marker
    jal x0, bne_done
    
bne_not_taken:
    addi x31, x31, 100   # Should be skipped
    
bne_done:
    
    # Test 8: BLT tests
    blt x1, x2, blt_taken
    addi x31, x31, 100   # Should be skipped
    
blt_taken:
    addi x31, x31, 1     # Success marker
    
    blt x4, x1, blt_taken2
    addi x31, x31, 100   # Should be skipped
    
blt_taken2:
    addi x31, x31, 1     # Success marker
    
    blt x2, x1, blt_not_taken
    addi x31, x31, 1     # Success marker
    jal x0, blt_done
    
blt_not_taken:
    addi x31, x31, 100   # Should be skipped
    
blt_done:
    
    # Test 9: BGE tests
    bge x2, x1, bge_taken
    addi x31, x31, 100   # Should be skipped
    
bge_taken:
    addi x31, x31, 1     # Success marker
    
    bge x1, x1, bge_taken2
    addi x31, x31, 100   # Should be skipped
    
bge_taken2:
    addi x31, x31, 1     # Success marker
    
    bge x4, x1, bge_not_taken
    addi x31, x31, 1     # Success marker
    jal x0, bge_done
    
bge_not_taken:
    addi x31, x31, 100   # Should be skipped
    
bge_done:
    
    # Test 10: BLTU and BGEU tests
    # Use lui to create large unsigned values without loads
    lui x20, 0xFFFFF     # Large unsigned value
    
    bltu x1, x20, bltu_taken
    addi x31, x31, 100   # Should be skipped
    
bltu_taken:
    addi x31, x31, 1     # Success marker
    
    bgeu x20, x1, bgeu_taken
    addi x31, x31, 100   # Should be skipped
    
bgeu_taken:
    addi x31, x31, 1     # Success marker
    
    # Test 11: Complex branch patterns
    addi x21, x0, 5      # Loop counter
    addi x22, x0, 0      # Sum
    
branch_loop:
    add x22, x22, x21    # Add counter to sum
    addi x21, x21, -1    # Decrement counter
    bne x21, x0, branch_loop  # Loop until counter = 0
    
    # x22 should now contain 5+4+3+2+1 = 15
    
    # Final success check - x31 should contain sum of all success markers
    # x31 value can be checked in simulation



halt:
    slti x0, x0, -256