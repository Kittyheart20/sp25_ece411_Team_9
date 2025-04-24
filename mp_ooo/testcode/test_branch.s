# RV32I and RV32M Comprehensive Test
# Tests all register-register, register-immediate, and M-extension instructions

.globl _start
_start:
    # Initialize registers with distinct values
    li x1, 0x00000001
    li x2, 0x00000002
    li x3, 0x00000000
        auipc x5, 0x123
        auipc x2, 0x123
    jal test_jal
        auipc x5, 0x163

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
test_jal:
add x5, x5, 1
    # addi x1, x1, 1
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    
    addi x3, x3, 1










    # Basic Branch Functionality Test
    # Initialize registers
    li x1, 10
    li x2, 20
    li x3, 10
    li x4, 0
    
    # Test 1: BEQ - Branch Equal (Taken)
    beq x1, x3, beq_taken
    addi x4, x4, 1       # Should be skipped
beq_taken:
    addi x5, x0, 1       # x5 = 1 (branch taken)
    
    # Test 2: BEQ - Branch Equal (Not Taken)
    beq x1, x2, beq_not_taken
    addi x6, x0, 2       # x6 = 2 (branch not taken)
beq_not_taken:
    
    # Test 3: BNE - Branch Not Equal (Taken)
    bne x1, x2, bne_taken
    addi x4, x4, 1       # Should be skipped
bne_taken:
    addi x7, x0, 3       # x7 = 3 (branch taken)
    
    # Test 4: BNE - Branch Not Equal (Not Taken)
    bne x1, x3, bne_not_taken
    addi x8, x0, 4       # x8 = 4 (branch not taken)
bne_not_taken:
    
    # Test 5: BLT - Branch Less Than (Taken)
    blt x1, x2, blt_taken
    addi x4, x4, 1       # Should be skipped
blt_taken:
    addi x9, x0, 5       # x9 = 5 (branch taken)
    
    # Test 6: BGE - Branch Greater or Equal (Taken)
    bge x2, x1, bge_taken
    addi x4, x4, 1       # Should be skipped
bge_taken:
    addi x10, x0, 6      # x10 = 6 (branch taken)
    
    # Test 7: BLTU - Branch Less Than Unsigned (Taken)
    li x20, 0xFFFFFFFF   # x20 = -1 (signed) but max value (unsigned)
    li x21, 10
    bltu x21, x20, bltu_taken
    addi x4, x4, 1       # Should be skipped
bltu_taken:
    addi x11, x0, 7      # x11 = 7 (branch taken)
    
    # Test 8: BGEU - Branch Greater or Equal Unsigned (Taken)
    bgeu x20, x21, bgeu_taken
    addi x4, x4, 1       # Should be skipped
bgeu_taken:
    addi x12, x0, 8      # x12 = 8 (branch taken)















# Branch Edge Cases Test
.section .text

    # Initialize registers
    li x1, 0x7FFFFFFF    # Maximum positive 32-bit value
    li x2, 0x80000000    # Minimum negative 32-bit value
    li x3, 0xFFFFFFFF    # -1 in two's complement
    
    # Test 1: Branching on maximum positive vs. minimum negative
    blt x1, x2, edge_blt_taken
    addi x4, x0, 1       # Should be skipped (x1 is NOT less than x2 signed)
edge_blt_taken:
    # addi x5, x0, 1       # x5 = 1 (branch taken) modified
    addi x5, x0, 7       # x5 = 1 (branch taken)

    # Test 2: Unsigned comparison of same values
    bltu x2, x1, edge_bltu_taken
    addi x6, x0, 2       # x6 = 2 (branch not taken)
edge_bltu_taken:
    
    # Test 3: Branching on zero equality
    li x10, 0
    li x11, 0
    beq x10, x11, zero_eq_taken
    addi x4, x4, 1       # Should be skipped
zero_eq_taken:
    addi x12, x0, 3      # x12 = 3 (branch taken)
    
    # Test 4: Branching on -1 vs. 0 (signed and unsigned)
    li x13, -1           # 0xFFFFFFFF
    li x14, 0
    blt x13, x14, neg_blt_taken
    addi x15, x0, 4      # x15 = 4 (branch taken)
neg_blt_taken:
    
    bltu x14, x13, neg_bltu_taken
    addi x4, x4, 1       # Should be skipped
neg_bltu_taken:
    addi x16, x0, 5      # x16 = 5 (branch taken)
    
    # Test 5: Branching with the same register
    li x17, 10
    beq x17, x17, same_reg_taken
    addi x4, x4, 1       # Should be skipped
same_reg_taken:
    addi x18, x0, 6      # x18 = 6 (branch taken)
    
    blt x17, x17, same_reg_not_taken
    addi x19, x0, 7      # x19 = 7 (branch not taken)
same_reg_not_taken:






# Branch Chains Test
.section .text

    # Initialize registers
    li x1, 1
    li x2, 2
    li x3, 3
    
    # Test 1: Chain of taken branches
    beq x1, x1, branch1
    addi x4, x0, 99      # Should be skipped
    j end_chain1
    
branch1:
    addi x10, x0, 10     # x10 = 10
    beq x2, x2, branch2
    addi x4, x0, 99      # Should be skipped
    j end_chain1
    
branch2:
    addi x11, x0, 11     # x11 = 11
    beq x3, x3, branch3
    addi x4, x0, 99      # Should be skipped
    j end_chain1
    
branch3:
    addi x12, x0, 12     # x12 = 12
    
end_chain1:
    
    # Test 2: Alternating taken/not-taken branches
    li x5, 5
    li x6, 6
    
    beq x5, x5, alt_branch1  # Taken
    addi x4, x0, 99          # Should be skipped
    
alt_branch1:
    addi x13, x0, 13         # x13 = 13
    beq x5, x6, alt_branch2  # Not taken
    addi x14, x0, 14         # x14 = 14
    
alt_branch2:
    addi x15, x0, 15         # x15 = 15
    
    # Test 3: Branching based on computed values
    li x20, 0
    
    addi x20, x20, 1     # x20 = 1
    beq x20, x1, comp_branch1
    addi x4, x0, 99      # Should be skipped
    
comp_branch1:
    addi x20, x20, 1     # x20 = 2
    beq x20, x2, comp_branch2
    addi x4, x0, 99      # Should be skipped
    
comp_branch2:
    addi x20, x20, 1     # x20 = 3
    beq x20, x3, comp_branch3
    addi x4, x0, 99      # Should be skipped
    
comp_branch3:
    addi x21, x0, 21     # x21 = 21

    # Branch Prediction Test
.section .text

    # Initialize counters
    li x1, 0      # Loop counter
    li x2, 100    # Loop limit
    li x3, 0      # Sum
    
    # Test 1: Loop with backward branch (should be predicted taken)
loop1_start:
    addi x1, x1, 1       # Increment counter
    add x3, x3, x1       # Add to sum
    blt x1, x2, loop1_start  # Branch back if x1 < 100
    
    # x1 should be 100, x3 should be 5050
    
    # Test 2: Loop with early exit (tests prediction accuracy)
    li x5, 0      # Loop counter
    li x6, 50     # Early exit condition
    li x7, 100    # Loop limit
    li x8, 0      # Sum
    
loop2_start:
    addi x5, x5, 1       # Increment counter
    add x8, x8, x5       # Add to sum
    
    # Early exit (branch rarely taken until end)
    beq x5, x6, loop2_early_exit
    
    # Continue loop (branch usually taken)
    blt x5, x7, loop2_start
    j loop2_end
    
loop2_early_exit:
    addi x9, x0, 9       # x9 = 9 (marker for early exit)
    
loop2_end:
    # If early exit taken: x5 = 50, x8 = 1275, x9 = 9
    # If normal completion: x5 = 100, x8 = 5050, x9 = 0
    
    # Test 3: Pattern of branches to test branch history table
    li x10, 0
    li x11, 10
    li x12, 0
    
pattern_loop:
    addi x10, x10, 1     # Increment counter
    
    # Pattern: TNTNTNTNT (alternating taken/not taken)
    andi x13, x10, 1     # x13 = x10 & 1 (0 or 1)
    beq x13, x0, pattern_even
    
    # Odd iteration (branch not taken)
    addi x12, x12, 1
    j pattern_continue
    
pattern_even:
    # Even iteration (branch taken)
    addi x12, x12, 2
    
pattern_continue:
    blt x10, x11, pattern_loop
    
    # x10 should be 10, x12 should be 15


halt:
    slti x0, x0, -256