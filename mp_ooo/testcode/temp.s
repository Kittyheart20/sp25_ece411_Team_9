# Integrated Branch and ALU Test
.section .text
.globl _start
_start:
    # Initialize memory region (well away from code)
    li x1, 0xB5000000    # Base memory address
    
    # Initialize test values
    li x2, 10            # Loop counter
    li x3, 0             # Sum accumulator
    li x4, 0             # Memory index
    
    # Test 1: Conditional branch with ALU operations
branch_alu_loop:
    # ALU operation
    addi x3, x3, 5       # Add 5 to accumulator
    sub x5, x3, x2       # Subtract counter from accumulator
    
    # Store result to memory
    slli x6, x4, 2       # Convert index to byte offset (x4 * 4)
    add x7, x1, x6       # Calculate memory address
    sw x5, 0(x7)         # Store result
    
    # Increment memory index
    addi x4, x4, 1
    
    # Decrement counter and branch if not zero
    addi x2, x2, -1
    bnez x2, branch_alu_loop
    
    # Verify final accumulator value
    li x8, 50            # Expected sum: 5*10 = 50
    bne x3, x8, fail
    
    # Verify stored values by loading and checking
    li x2, 10            # Reset counter
    li x4, 0             # Reset memory index
    
verify_loop:
    # Calculate expected value: 5*iteration - (10-iteration)
    sub x9, x2, x4       # Counter difference
    addi x10, x4, 1      # Iteration number (1-based)
    li x11, 5
    mul x12, x10, x11    # 5 * iteration
    sub x13, x12, x9     # Expected value
    
    # Load stored value
    slli x6, x4, 2       # Convert index to byte offset
    add x7, x1, x6       # Calculate memory address
    lw x14, 0(x7)        # Load value
    
    # Compare with expected
    bne x13, x14, fail
    
    # Increment and continue
    addi x4, x4, 1
    blt x4, x2, verify_loop
    
    j test_passed
    
fail:
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed:
    li x31, 0x1          # Success indicator







    # Multiplication and Division with Memory Test
    # Initialize memory region (well away from code)
    li x1, 0xB6000000    # Base memory address
    
    # Initialize test values
    li x2, 12            # First operand
    li x3, 3             # Second operand
    
    # Test 1: Basic multiplication and division with memory
    mul x4, x2, x3       # x4 = 12 * 3 = 36
    sw x4, 0(x1)         # Store result
    
    div x5, x4, x3       # x5 = 36 / 3 = 12
    sw x5, 4(x1)         # Store result
    
    rem x6, x4, x3       # x6 = 36 % 3 = 0
    sw x6, 8(x1)         # Store result
    
    # Load and verify
    lw x7, 0(x1)         # Load multiplication result
    li x8, 36            # Expected value
    bne x7, x8, fail_2
    
    lw x7, 4(x1)         # Load division result
    li x8, 12            # Expected value
    bne x7, x8, fail_2
    
    lw x7, 8(x1)         # Load remainder result
    li x8, 0             # Expected value
    bne x7, x8, fail_2
    
    # Test 2: More complex multiplication/division with memory
    li x2, 100           # First operand
    li x3, 7             # Second operand
    
    mul x4, x2, x3       # x4 = 100 * 7 = 700
    sw x4, 12(x1)        # Store result
    
    div x5, x4, x3       # x5 = 700 / 7 = 100
    sw x5, 16(x1)        # Store result
    
    rem x6, x4, x3       # x6 = 700 % 7 = 0
    sw x6, 20(x1)        # Store result
    
    # Test 3: Signed multiplication and division
    li x2, -50           # Negative operand
    li x3, 5             # Positive operand
    
    mul x4, x2, x3       # x4 = -50 * 5 = -250
    sw x4, 24(x1)        # Store result
    
    div x5, x4, x3       # x5 = -250 / 5 = -50
    sw x5, 28(x1)        # Store result
    
    div x6, x4, x2       # x6 = -250 / -50 = 5
    sw x6, 32(x1)        # Store result
    
    # Load and verify complex results
    lw x7, 12(x1)        # Load multiplication result
    li x8, 700           # Expected value
    bne x7, x8, fail_2
    
    lw x7, 16(x1)        # Load division result
    li x8, 100           # Expected value
    bne x7, x8, fail_2
    
    lw x7, 24(x1)        # Load signed multiplication result
    li x8, -250          # Expected value
    bne x7, x8, fail_2
    
    lw x7, 28(x1)        # Load signed division result
    li x8, -50           # Expected value
    bne x7, x8, fail_2
    
    lw x7, 32(x1)        # Load signed division result
    li x8, 5             # Expected value
    bne x7, x8, fail_2
    
    j test_passed_2
    
fail_2:
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_2:
    li x31, 0x1          # Success indicator



























    # Complex ALU and Memory Operations
    # Initialize memory region (well away from code)
    li x1, 0xB8000000    # Base memory address
    
    # Test 1: Bitwise operations with memory
    li x2, 0xAAAAAAAA    # Pattern 1
    li x3, 0x55555555    # Pattern 2
    
    and x4, x2, x3       # x4 = 0x00000000
    or x5, x2, x3        # x5 = 0xFFFFFFFF
    xor x6, x2, x3       # x6 = 0xFFFFFFFF
    
    sw x4, 0(x1)         # Store AND result
    sw x5, 4(x1)         # Store OR result
    sw x6, 8(x1)         # Store XOR result
    
    # Test 2: Shift operations with memory
    li x7, 0x00000001
    
    slli x8, x7, 10      # x8 = 0x00000400 (1 << 10)
    sw x8, 12(x1)        # Store left shift result
    
    srli x9, x2, 8       # x9 = 0x00AAAAAA (logical right shift)
    sw x9, 16(x1)        # Store logical right shift result
    
    srai x10, x2, 8      # x10 = 0xFFAAAAAA (arithmetic right shift)
    sw x10, 20(x1)       # Store arithmetic right shift result
    
    # Test 3: ALU operations with loaded values
    lw x11, 0(x1)        # Load AND result
    lw x12, 4(x1)        # Load OR result
    
    add x13, x11, x12    # x13 = 0x00000000 + 0xFFFFFFFF = 0xFFFFFFFF
    sub x14, x12, x11    # x14 = 0xFFFFFFFF - 0x00000000 = 0xFFFFFFFF
    
    sw x13, 24(x1)       # Store addition result
    sw x14, 28(x1)       # Store subtraction result
    
    # Test 4: Verify all results
    lw x15, 0(x1)        # Load AND result
    li x16, 0x00000000   # Expected value
    bne x15, x16, fail_3
    
    lw x15, 4(x1)        # Load OR result
    li x16, 0xFFFFFFFF   # Expected value
    bne x15, x16, fail_3
    
    lw x15, 8(x1)        # Load XOR result
    li x16, 0xFFFFFFFF   # Expected value
    bne x15, x16, fail_3
    
    lw x15, 12(x1)       # Load left shift result
    li x16, 0x00000400   # Expected value
    bne x15, x16, fail_3
    
    lw x15, 16(x1)       # Load logical right shift result
    li x16, 0x00AAAAAA   # Expected value
    bne x15, x16, fail_3
    
    lw x15, 20(x1)       # Load arithmetic right shift result
    li x16, 0xFFAAAAAA   # Expected value
    bne x15, x16, fail_3
    
    lw x15, 24(x1)       # Load addition result
    li x16, 0xFFFFFFFF   # Expected value
    bne x15, x16, fail_3
    
    lw x15, 28(x1)       # Load subtraction result
    li x16, 0xFFFFFFFF   # Expected value
    bne x15, x16, fail_3
    
    j test_passed_3
    
fail_3:
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_3:
    li x31, 0x1          # Success indicator







    # Integrated Multiply-Divide and Branch Test
    # Initialize memory region (well away from code)
    li x1, 0xB9000000    # Base memory address
    
    # Initialize test values
    li x2, 7             # First operand
    li x3, 3             # Second operand
    li x4, 10            # Loop counter
    li x5, 0             # Result accumulator
    
    # Test 1: Loop with multiplication and division
mul_div_loop:
    mul x6, x2, x3       # x6 = 7 * 3 = 21
    add x5, x5, x6       # Add to accumulator
    
    div x7, x5, x3       # Divide accumulator by 3
    rem x8, x5, x3       # Remainder of accumulator / 3
    
    # Store results
    sw x5, 0(x1)         # Store accumulator
    sw x7, 4(x1)         # Store quotient
    sw x8, 8(x1)         # Store remainder
    
    # Update memory pointer
    addi x1, x1, 12      # Move to next storage location
    
    # Branch condition
    addi x4, x4, -1      # Decrement counter
    bnez x4, mul_div_loop # Loop if counter not zero
    
    # Reset memory pointer
    li x1, 0xB9000000
    
    # Verify final accumulator value (21 * 10 = 210)
    lw x9, 108(x1)       # Load final accumulator value (offset 9*12)
    li x10, 210          # Expected value
    bne x9, x10, fail_4
    
    # Test 2: Conditional multiplication based on loaded value
    lw x11, 0(x1)        # Load first result (21)
    lw x12, 12(x1)       # Load second result (42)
    
    blt x11, x12, do_multiply  # Branch if first < second (should be taken)
    j fail_4
    
do_multiply:
    mul x13, x11, x12    # x13 = 21 * 42 = 882
    sw x13, 120(x1)      # Store result
    
    # Test 3: Division with branch on remainder
    li x14, 100
    li x15, 3
    
    rem x16, x14, x15    # x16 = 100 % 3 = 1
    bnez x16, remainder_not_zero  # Branch if remainder not zero (should be taken)
    j fail_4
    
remainder_not_zero:
    div x17, x14, x15    # x17 = 100 / 3 = 33
    sw x17, 124(x1)      # Store result
    
    # Test 4: Verify multiplication result
    lw x18, 120(x1)      # Load multiplication result
    li x19, 882          # Expected value
    bne x18, x19, fail_4
    
    # Test 5: Verify division result
    lw x20, 124(x1)      # Load division result
    li x21, 33           # Expected value
    bne x20, x21, fail_4
    
    j test_passed_4
    
fail_4:
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_4:
    li x31, 0x1          # Success indicator


















    # Memory-to-Memory Operations with Branches
    # Initialize memory regions (well away from code)
    li x1, 0xBA000000    # Source memory address
    li x2, 0xBA001000    # Destination memory address
    
    # Initialize source memory with test values
    li x3, 10
    li x4, 20
    li x5, 30
    li x6, 40
    
    sw x3, 0(x1)         # Store 10 at source+0
    sw x4, 4(x1)         # Store 20 at source+4
    sw x5, 8(x1)         # Store 30 at source+8
    sw x6, 12(x1)        # Store 40 at source+12
    
    # Test 1: Copy with transformation if value meets condition
    li x7, 0             # Loop counter
    li x8, 4             # Loop limit
    
copy_loop:
    # Calculate source address
    slli x9, x7, 2       # Convert counter to byte offset
    add x10, x1, x9      # Source address
    
    # Load value
    lw x11, 0(x10)       # Load value from source
    
    # Branch based on value
    li x12, 25
    blt x11, x12, small_value    # Branch if value < 25
    
    # Large value path
    mul x13, x11, x11    # Square the value
    j store_result
    
small_value:
    # Small value path
    addi x13, x11, 5     # Add 5 to value
    
store_result:
    # Calculate destination address
    add x14, x2, x9      # Destination address
    
    # Store transformed value
    sw x13, 0(x14)       # Store result to destination
    
    # Loop control
    addi x7, x7, 1       # Increment counter
    blt x7, x8, copy_loop # Loop if counter < limit
    
    # Test 2: Verify results
    lw x15, 0(x2)        # Load first result (10+5 = 15)
    li x16, 15           # Expected value
    bne x15, x16, fail_5
    
    lw x15, 4(x2)        # Load second result (20+5 = 25)
    li x16, 25           # Expected value
    bne x15, x16, fail_5
    
    lw x15, 8(x2)        # Load third result (30*30 = 900)
    li x16, 900          # Expected value
    bne x15, x16, fail_5
    
    lw x15, 12(x2)       # Load fourth result (40*40 = 1600)
    li x16, 1600         # Expected value
    bne x15, x16, fail_5
    
    # Test 3: Process results further based on even/odd
    li x7, 0             # Reset loop counter
    
process_loop:
    # Calculate address
    slli x9, x7, 2       # Convert counter to byte offset
    add x10, x2, x9      # Address
    
    # Load value
    lw x11, 0(x10)       # Load result
    
    # Check if even or odd
    andi x12, x11, 1     # Get least significant bit
    beqz x12, even_value # Branch if even (LSB = 0)
    
    # Odd value path
    div x13, x11, x1     # Divide by base address (arbitrary operation)
    sw x13, 16(x10)      # Store at offset +16
    j process_next
    
even_value:
    # Even value path
    rem x13, x11, x8     # Remainder when divided by 4
    sw x13, 16(x10)      # Store at offset +16
    
process_next:
    # Loop control
    addi x7, x7, 1       # Increment counter
    blt x7, x8, process_loop # Loop if counter < limit
    
    j test_passed_5
    
fail_5:
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_5:
    li x31, 0x1          # Success indicator





























    # Complex Branch Prediction Test
    # Initialize memory region (well away from code)
    li x1, 0xBB000000    # Base memory address
    
    # Initialize test values
    li x2, 0             # Counter
    li x3, 20            # Loop limit
    li x4, 0             # Sum accumulator
    
    # Test 1: Pattern of taken/not-taken branches
branch_pattern_loop:
    # Check if counter is even or odd
    andi x5, x2, 1       # Get LSB
    beqz x5, even_counter # Branch if counter is even
    
    # Odd counter path (should be taken for odd iterations)
    addi x4, x4, 1       # Add 1 to sum
    sw x4, 0(x1)         # Store sum
    j continue_loop
    
even_counter:
    # Even counter path (should be taken for even iterations)
    addi x4, x4, 2       # Add 2 to sum
    sw x4, 4(x1)         # Store sum
    
continue_loop:
    # Increment counter
    addi x2, x2, 1       # Increment counter
    
    # Every 5 iterations, do a multiplication
    li x6, 5
    rem x7, x2, x6       # x7 = counter % 5
    bnez x7, skip_multiply # Branch if not multiple of 5
    
    # Multiple of 5 path (every 5th iteration)
    lw x8, 0(x1)         # Load current sum
    mul x9, x8, x6       # Multiply by 5
    sw x9, 8(x1)         # Store result
    
skip_multiply:
    # Branch based on counter value
    blt x2, x3, branch_pattern_loop # Loop if counter < limit
    
    # Test 2: Verify final sum
    # For odd iterations: add 1, for even iterations: add 2
    # Sum should be: 10 odd iterations * 1 + 10 even iterations * 2 = 10 + 20 = 30
    li x10, 30           # Expected sum
    bne x4, x10, fail_6
    
    # Test 3: Nested branches
    li x2, 0             # Reset counter
    li x11, 0            # Another accumulator
    
nested_branch_loop:
    addi x2, x2, 1       # Increment counter
    
    # First level branch
    li x12, 10
    blt x2, x12, first_level_true
    j first_level_false
    
first_level_true:
    # Second level branch
    li x13, 5
    blt x2, x13, second_level_true
    j second_level_false
    
second_level_true:
    # Counter < 5
    addi x11, x11, 10    # Add 10 to accumulator
    j nested_continue
    
second_level_false:
    # 5 <= Counter < 10
    addi x11, x11, 100   # Add 100 to accumulator
    j nested_continue
    
first_level_false:
    # Counter >= 10
    # Third level branch
    li x14, 15
    blt x2, x14, third_level_true
    j third_level_false
    
third_level_true:
    # 10 <= Counter < 15
    addi x11, x11, 1000  # Add 1000 to accumulator
    j nested_continue
    
third_level_false:
    # Counter >= 15
    addi x11, x11, 1000 # Add 10000 to accumulator
    
nested_continue:
    # Store accumulator
    sw x11, 12(x1)
    
    # Continue loop if counter < 20
    blt x2, x3, nested_branch_loop
    
    # Verify final accumulator value
    # Should be: 4*10 + 5*100 + 5*1000 + 6*10000 = 40 + 500 + 5000 + 60000 = 65540
    lw x15, 12(x1)       # Load final accumulator
    li x16, 65540        # Expected value
    bne x15, x16, fail_6
    
    j test_passed_6
    
fail_6:
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_6:
    li x31, 0x1          # Success indicator











# Extreme Register Hazard Chain Test
    # Initialize memory region (well away from code)
    li x1, 0xBD000000
    
    # Create a complex WAR, WAW, RAW hazard chain
    li x2, 0x12345678
    li x3, 0xABCDEF01
    li x4, 0x87654321
    
    # Begin hazard sequence
    add x5, x2, x3       # x5 = x2 + x3 (RAW on x2, x3)
    sub x2, x4, x5       # WAR on x5, WAW on x2
    mul x6, x2, x5       # RAW on x2, x5
    add x3, x6, x2       # RAW on x6, x2, WAW on x3
    xor x5, x3, x6       # RAW on x3, x6, WAW on x5
    or  x2, x5, x4       # RAW on x5, x4, WAW on x2
    and x4, x2, x3       # RAW on x2, x3, WAW on x4
    mul x3, x4, x5       # RAW on x4, x5, WAW on x3
    sub x6, x3, x2       # RAW on x3, x2, WAW on x6
    
    # Store results to check later
    sw x2, 0(x1)
    sw x3, 4(x1)
    sw x4, 8(x1)
    sw x5, 12(x1)
    sw x6, 16(x1)
    
    # Now create a loop that depends on these values
    li x7, 10            # Loop counter
    li x8, 0             # Accumulator
    
hazard_loop:
    lw x9, 0(x1)         # Load x2's value (RAW memory dependency)
    lw x10, 4(x1)        # Load x3's value (potential memory reordering)
    add x8, x8, x9       # Update accumulator with x2's value
    sub x9, x10, x8      # Reuse x9 (WAW on x9)
    sw x9, 20(x1)        # Store result (creates memory WAR hazard)
    xor x10, x9, x10     # Reuse x10 (WAW on x10, RAW on x9)
    sw x10, 24(x1)       # Store another result
    
    # Create a difficult-to-predict branch pattern
    andi x11, x7, 1      # Check if counter is odd/even
    bnez x11, odd_iteration
    
    # Even iteration
    mul x12, x8, x7      # Long-latency operation
    sw x12, 28(x1)
    j continue_loop
    
odd_iteration:
    div x12, x8, x7      # Different long-latency operation
    sw x12, 32(x1)
    
continue_loop:
    addi x7, x7, -1      # Decrement counter
    bnez x7, hazard_loop # Loop back





# Store-to-Load Forwarding Stress Test
    # Initialize memory regions
    li x1, 0xBE000000    # Base address
    li x2, 0xBE001000    # Second address region
    
    # Fill memory with initial pattern
    li x3, 0xDEADBEEF
    sw x3, 0(x1)
    sw x3, 4(x1)
    sw x3, 8(x1)
    sw x3, 12(x1)
    
    # Create complex store-to-load forwarding patterns
    
    # Pattern 1: Store followed immediately by load (obvious forwarding)
    li x4, 0x12345678
    sw x4, 0(x1)         # Store x4
    lw x5, 0(x1)         # Load into x5 - should forward
    
    # Pattern 2: Store followed by dependent store then load
    li x6, 0xABCDEF01
    sw x6, 4(x1)         # Store x6
    add x7, x6, x5       # Compute new value
    sw x7, 8(x1)         # Store computed value
    lw x8, 4(x1)         # Load original value - should forward
    lw x9, 8(x1)         # Load computed value - should forward
    
    # Pattern 3: Byte store followed by word load (partial forwarding)
    li x10, 0xFF
    sb x10, 12(x1)       # Store byte
    lw x11, 12(x1)       # Load word - should partially forward
    
    # Pattern 4: Multiple stores to same address before load
    li x12, 0x11111111
    li x13, 0x22222222
    li x14, 0x33333333
    
    sw x12, 16(x1)       # First store
    sw x13, 16(x1)       # Second store (overwrites first)
    sw x14, 16(x1)       # Third store (overwrites second)
    lw x15, 16(x1)       # Load - should get x14's value
    
    # Pattern 5: Interleaved stores and loads to different addresses
    li x16, 0xAAAAAAAA
    li x17, 0xBBBBBBBB
    li x18, 0xCCCCCCCC
    
    sw x16, 20(x1)       # Store to first address
    sw x17, 24(x1)       # Store to second address
    lw x19, 20(x1)       # Load from first address - should forward x16
    sw x18, 20(x1)       # Store to first address again
    lw x20, 24(x1)       # Load from second address - should forward x17
    lw x21, 20(x1)       # Load from first address - should forward x18
    
    # Pattern 6: Store-to-load with computed addresses
    li x22, 0xDDDDDDDD
    li x23, 0
    
    # Compute address
    addi x23, x1, 28     # Calculate address
    sw x22, 0(x23)       # Store using computed address
    lw x24, 28(x1)       # Load using constant offset - should forward
    
    # Pattern 7: Stores in a tight loop followed by loads
    li x25, 5            # Loop counter
    li x26, 0            # Offset
    
store_loop:
    slli x27, x26, 2     # Convert to byte offset
    add x28, x2, x27     # Compute address
    sw x25, 0(x28)       # Store counter
    addi x26, x26, 1     # Increment offset
    addi x25, x25, -1    # Decrement counter
    bnez x25, store_loop
    
    # Now load in reverse order
    li x25, 5            # Reset counter
    
load_loop:
    addi x25, x25, -1    # Decrement first
    slli x27, x25, 2     # Convert to byte offset
    add x28, x2, x27     # Compute address
    lw x29, 0(x28)       # Load value
    addi x26, x25, 1     # Expected value
    bne x29, x26, store_load_fail
    bnez x25, load_loop
    
    j store_load_pass
    
store_load_fail:
    li x31, 0xFFFFFFFF
    j store_load_end
    
store_load_pass:
    li x31, 0x00000001
    
store_load_end:
    nop







# Multiplication-Division Hazard Torture Test
    # Initialize memory region
    li x1, 0xBF000000
    
    # Initialize test values
    li x2, 0x00010001    # Operand 1
    li x3, 0x00020002    # Operand 2
    li x4, 0x00030003    # Operand 3
    li x5, 0x00040004    # Operand 4
    
    # Create a sequence of dependent multiply/divide operations
    # interleaved with ALU operations and memory accesses
    
    # Sequence 1: Multiply chain with dependencies
    mul x6, x2, x3       # x6 = x2 * x3
    mul x7, x3, x4       # x7 = x3 * x4 (independent of first mul)
    mul x8, x6, x7       # x8 = x6 * x7 (depends on both previous muls)
    add x9, x6, x7       # x9 = x6 + x7 (ALU op dependent on muls)
    sw x8, 0(x1)         # Store mul result
    sw x9, 4(x1)         # Store ALU result
    
    # Sequence 2: Division chain with dependencies
    div x10, x8, x2      # x10 = x8 / x2 (depends on previous mul)
    rem x11, x8, x3      # x11 = x8 % x3 (depends on previous mul)
    div x12, x9, x4      # x12 = x9 / x4 (depends on previous ALU)
    rem x13, x9, x5      # x13 = x9 % x5 (depends on previous ALU)
    
    # Sequence 3: Interleaved mul/div with memory operations
    lw x14, 0(x1)        # Load x8 (mul result)
    mul x15, x14, x10    # x15 = x14 * x10 (depends on load and div)
    sw x15, 8(x1)        # Store result
    lw x16, 4(x1)        # Load x9 (ALU result)
    div x17, x15, x16    # x17 = x15 / x16 (depends on mul and load)
    sw x17, 12(x1)       # Store result
    
    # Sequence 4: Mul/div with immediate dependencies
    mul x18, x2, x3      # x18 = x2 * x3
    div x18, x18, x4     # x18 = x18 / x4 (WAW hazard)
    mul x18, x18, x5     # x18 = x18 * x5 (WAW hazard)
    sw x18, 16(x1)       # Store result
    
    # Sequence 5: Complex dependency chain with branches
    li x19, 10           # Loop counter
    li x20, 1            # Initial value
    
mul_div_loop:
    mul x20, x20, x19    # x20 = x20 * x19
    sw x20, 20(x1)       # Store intermediate result
    div x21, x20, x2     # x21 = x20 / x2
    rem x22, x20, x3     # x22 = x20 % x3
    
    # Branch based on remainder
    beqz x22, zero_remainder
    
    # Non-zero remainder path
    mul x20, x21, x19    # Update with mul result
    j continue_mul_div
    
zero_remainder:
    # Zero remainder path
    div x20, x21, x19    # Update with div result
    
continue_mul_div:
    addi x19, x19, -1    # Decrement counter
    bnez x19, mul_div_loop # Loop back
    
    # Store final result
    sw x20, 24(x1)












# Branch Misprediction Recovery Stress Test
    # Initialize memory region
    li x1, 0xC0000000
    
    # Initialize test values
    li x2, 0             # Counter
    li x3, 20            # Limit
    li x4, 0             # Accumulator 1
    li x5, 0             # Accumulator 2
    
    # Create a complex branch pattern that's difficult to predict
    # with register and memory dependencies
    
branch_test_loop:
    # Increment counter
    addi x2, x2, 1
    
    # Store counter
    sw x2, 0(x1)
    
    # Load counter (memory dependency)
    lw x6, 0(x1)
    
    # Complex branch condition based on multiple factors
    rem x7, x6, x3       # x7 = counter % 20
    li x8, 3
    rem x9, x6, x8       # x9 = counter % 3
    li x10, 7
    rem x11, x6, x10     # x11 = counter % 7
    
    # Branch 1: Based on counter % 3
    bnez x9, branch1_not_taken
    
    # Branch 1 taken path (counter divisible by 3)
    addi x4, x4, 10      # Update accumulator 1
    sw x4, 4(x1)         # Store accumulator 1
    
    # Branch 2: Nested branch based on counter % 7
    bnez x11, branch2_not_taken
    
    # Branch 2 taken path (counter divisible by 3 and 7)
    mul x12, x4, x5      # Complex operation
    sw x12, 8(x1)        # Store result
    j branch2_end
    
branch2_not_taken:
    # Branch 2 not taken path
    div x12, x4, x8      # Different complex operation
    sw x12, 12(x1)       # Store to different location
    
branch2_end:
    j branch1_end
    
branch1_not_taken:
    # Branch 1 not taken path
    addi x5, x5, 5       # Update accumulator 2
    sw x5, 16(x1)        # Store accumulator 2
    
    # Branch 3: Another nested branch
    li x13, 10
    blt x6, x13, branch3_taken
    
    # Branch 3 not taken path
    mul x14, x5, x8      # Complex operation
    sw x14, 20(x1)       # Store result
    j branch3_end
    
branch3_taken:
    # Branch 3 taken path
    div x14, x5, x8      # Different complex operation
    sw x14, 24(x1)       # Store to different location
    
branch3_end:
    
branch1_end:
    # Branch 4: Final branch in loop
    bne x2, x3, branch_test_loop
    
    # Store final accumulator values
    sw x4, 28(x1)        # Final accumulator 1
    sw x5, 32(x1)        # Final accumulator 2









# Memory Aliasing and Dependency Resolution Test
    # Initialize memory regions
    li x1, 0xC1000000    # Base address 1
    li x2, 0xC1000100    # Base address 2 (different region)
    
    # Initialize test values
    li x3, 0xAAAAAAAA
    li x4, 0xBBBBBBBB
    li x5, 0xCCCCCCCC
    li x6, 0xDDDDDDDD
    
    # Store initial values
    sw x3, 0(x1)
    sw x4, 4(x1)
    sw x5, 0(x2)
    sw x6, 4(x2)
    
    # Create potential aliasing scenarios
    
    # Scenario 1: Same address, different base registers
    li x7, 0x11111111
    sw x7, 0(x1)         # Store to address via x1
    lw x8, 0(x1)         # Load from same address via x1 (should forward)
    
    # Compute same address using different register
    addi x9, x1, 0       # x9 = x1 (same base address)
    lw x10, 0(x9)        # Load from same address via x9 (should forward or load x7)
    
    # Scenario 2: Memory address dependency chain
    li x11, 0x22222222
    sw x11, 4(x1)        # Store to x1+4
    
    # Compute address based on loaded value
    lw x12, 0(x1)        # Load x7 from x1+0
    andi x12, x12, 0xFF  # Mask to get offset
    add x13, x1, x12     # Compute new address
    
    li x14, 0x33333333
    sw x14, 0(x13)       # Store to computed address
    lw x15, 0(x13)       # Load from computed address (should forward or load x14)
    
    # Scenario 3: Potential address aliasing
    li x16, 0x44444444
    li x17, 0x100        # Offset to make x1+x17 = x2
    
    # Store to address via different paths
    sw x16, 0(x2)        # Store to x2+0
    add x18, x1, x17     # x18 = x1+0x100 = x2
    lw x19, 0(x18)       # Load from x18 (should get x16)
    
    # Scenario 4: Complex aliasing with branches
    li x20, 0x55555555
    li x21, 0x66666666
    
    # Branch to determine which address to use
    andi x22, x15, 1     # Check if loaded value is odd/even
    bnez x22, use_addr2
    
    # Use first address
    sw x20, 8(x1)        # Store to x1+8
    j addr_selected
    
use_addr2:
    # Use second address
    sw x21, 8(x2)        # Store to x2+8
    
addr_selected:
    # Now load from both addresses
    lw x23, 8(x1)        # Load from x1+8
    lw x24, 8(x2)        # Load from x2+8
    
    # Scenario 5: Store address depends on loaded value
    lw x25, 0(x1)        # Load value from x1+0
    srli x25, x25, 16    # Shift to get address offset
    andi x25, x25, 0xFF  # Mask to ensure valid offset
    add x26, x1, x25     # Compute address
    
    li x27, 0x77777777
    sw x27, 0(x26)       # Store to computed address
    lw x28, 0(x26)       # Load from computed address (should forward or load x27)














# Pipeline Flush and Recovery Stress Test
    # Initialize memory region
    li x1, 0xC2000000
    
    # Initialize test values
    li x2, 0             # Loop counter
    li x3, 10            # Loop limit
    li x4, 0             # Result accumulator
    
    # Create a scenario with frequent pipeline flushes
    # due to branches and data dependencies
    
flush_test_loop:
    # Increment counter
    addi x2, x2, 1
    
    # Store counter
    sw x2, 0(x1)
    
    # Create long dependency chain
    lw x5, 0(x1)         # Load counter
    addi x6, x5, 100     # x6 = counter + 100
    mul x7, x6, x5       # x7 = (counter + 100) * counter
    sw x7, 4(x1)         # Store result
    
    # Load result back
    lw x8, 4(x1)         # Load multiplication result
    
    # Branch based on complex condition
    srli x9, x8, 8       # Shift result right
    andi x9, x9, 0x3     # Mask to get 2 bits
    
    # Multi-way branch based on extracted bits
    beqz x9, branch_path0
    li x10, 1
    beq x9, x10, branch_path1
    li x10, 2
    beq x9, x10, branch_path2
    
    # Default path (x9 = 3)
    div x11, x8, x5      # Perform division
    add x4, x4, x11      # Update accumulator
    j branch_end
    
branch_path0:
    # Path 0
    add x11, x8, x6      # Perform addition
    sub x4, x4, x11      # Update accumulator
    j branch_end
    
branch_path1:
    # Path 1
    sub x11, x8, x6      # Perform subtraction
    mul x4, x4, x11      # Update accumulator
    j branch_end
    
branch_path2:
    # Path 2
    xor x11, x8, x6      # Perform XOR
    or x4, x4, x11       # Update accumulator
    
branch_end:
    # Store updated accumulator
    sw x4, 8(x1)
    
    # Nested branch with memory dependency
    lw x12, 8(x1)        # Load accumulator
    andi x13, x12, 0xF   # Extract low bits
    li x14, 0xA
    blt x13, x14, nested_branch_taken
    
    # Nested branch not taken
    addi x15, x12, 50    # Perform operation
    sw x15, 12(x1)       # Store result
    j nested_branch_end
    
nested_branch_taken:
    # Nested branch taken
    subi x15, x12, 30    # Perform different operation
    sw x15, 16(x1)       # Store to different location
    
nested_branch_end:
    # Continue loop
    bne x2, x3, flush_test_loop
    
    # Final result
    sw x4, 20(x1)












# Extreme Instruction Interleaving Test
    # Initialize memory region
    li x1, 0xC3000000
    
    # Initialize test values
    li x2, 0x12345678
    li x3, 0xABCDEF01
    
    # Create a complex mix of interleaved instructions
    # with dependencies designed to stress the scheduler
    
    # Store initial values
    sw x2, 0(x1)         # Store first value
    sw x3, 4(x1)         # Store second value
    
    # Begin interleaved sequence
    lw x4, 0(x1)         # Load first value (depends on first store)
    mul x5, x2, x3       # Multiply registers (long latency)
    lw x6, 4(x1)         # Load second value (depends on second store)
    add x7, x4, x6       # Add loaded values (depends on both loads)
    div x8, x5, x7       # Divide mul result by sum (depends on mul and add)
    sw x7, 8(x1)         # Store sum (depends on add)
    rem x9, x5, x7       # Remainder of mul result and sum (depends on mul and add)
    sw x8, 12(x1)        # Store division result (depends on div)
    xor x10, x8, x9      # XOR div and rem results (depends on div and rem)
    sw x9, 16(x1)        # Store remainder result (depends on rem)
    add x11, x10, x7     # Add XOR result and sum (depends on xor and add)
    sw x10, 20(x1)       # Store XOR result (depends on xor)
    sub x12, x11, x8     # Subtract div result from new sum (depends on new add and div)
    sw x11, 24(x1)       # Store new sum (depends on new add)
    mul x13, x12, x9     # Multiply subtraction result by remainder (depends on sub and rem)
    sw x12, 28(x1)       # Store subtraction result (depends on sub)
    div x14, x13, x10    # Divide new mul result by XOR result (depends on new mul and xor)
    sw x13, 32(x1)       # Store new mul result (depends on new mul)
    sw x14, 36(x1)       # Store new div result (depends on new div)
    
    # Now load everything back in reverse order
    lw x15, 36(x1)       # Load last result
    lw x16, 32(x1)       # Load second-to-last result
    lw x17, 28(x1)       # And so on...
    lw x18, 24(x1)
    lw x19, 20(x1)
    lw x20, 16(x1)
    lw x21, 12(x1)
    lw x22, 8(x1)
    lw x23, 4(x1)
    lw x24, 0(x1)
    
    # Perform operations with loaded values
    add x25, x15, x16    # Depends on first two loads
    sub x26, x17, x18    # Depends on next two loads
    mul x27, x19, x20    # Depends on next two loads
    div x28, x21, x22    # Depends on next two loads
    xor x29, x23, x24    # Depends on last two loads
    
    # Final chain of dependent operations
    add x30, x25, x26    # Depends on first two results
    mul x31, x30, x27    # Depends on previous result and third result
    div x5, x31, x28     # Depends on previous result and fourth result
    xor x6, x5, x29      # Depends on previous result and fifth result
    
    # Store final result
    sw x6, 40(x1)        # Store final result





















    # Load-Hit-Store and Store-Hit-Load Hazard Test
    # Initialize memory region
    li x1, 0xC4000000
    
    # Initialize test values
    li x2, 0xAAAAAAAA
    li x3, 0xBBBBBBBB
    
    # Test 1: Basic Load-Hit-Store (LHS) hazard
    sw x2, 0(x1)         # Store x2
    lw x4, 0(x1)         # Load from same address (potential forwarding)
    
    # Test 2: Store-Hit-Load (SHL) hazard
    lw x5, 4(x1)         # Load from address
    sw x3, 4(x1)         # Store to same address
    
    # Test 3: Multiple store-hit-load hazards
    lw x6, 8(x1)         # Load from address
    sw x2, 8(x1)         # First store to same address
    sw x3, 8(x1)         # Second store to same address (overwrites first)
    
    # Test 4: Interleaved LHS and SHL hazards
    sw x2, 12(x1)        # Store to address (setup)
    lw x7, 12(x1)        # LHS: Load from same address
    lw x8, 16(x1)        # Load from different address
    sw x3, 16(x1)        # SHL: Store to address just loaded
    
    # Test 5: Byte-level hazards
    li x9, 0xFF
    sb x9, 20(x1)        # Store byte
    lw x10, 20(x1)       # Load word containing that byte
    
    # Test 6: Complex pattern with computed addresses
    li x11, 0x24         # Offset
    add x12, x1, x11     # Compute address
    
    sw x2, 0(x12)        # Store to computed address
    lw x13, 0(x12)       # Load from same computed address
    
    addi x12, x12, 4     # Update computed address
    lw x14, 0(x12)       # Load from new address
    sw x3, 0(x12)        # Store to new address
    
    # Test 7: Hazards in a loop
    li x15, 5            # Loop counter
    li x16, 0            # Base offset
    
hazard_loop:
    # Compute address
    slli x17, x16, 2     # Convert to byte offset
    add x18, x1, x17     # Compute address
    addi x18, x18, 100   # Add base offset for this test
    
    # Create LHS hazard
    sw x15, 0(x18)       # Store counter
    lw x19, 0(x18)       # Load from same address
    
    # Create SHL hazard for next iteration
    addi x20, x18, 4     # Next address
    lw x21, 0(x20)       # Load from next address
    
    # Increment and loop
    addi x16, x16, 1     # Increment offset
    addi x15, x15, -1    # Decrement counter
    
    # Store to address loaded in previous iteration
    sw x15, 0(x20)       # SHL: Store to address loaded above
    
    bnez x15, hazard_loop











    # Register File Port Contention Test
    # Initialize memory region
    li x1, 0xC5000000
    
    # Initialize test values
    li x2, 0x22222222
    li x3, 0x33333333
    li x4, 0x44444444
    li x5, 0x55555555
    li x6, 0x66666666
    li x7, 0x77777777
    
    # Create a sequence of instructions that creates
    # extreme register file port contention
    
    # Group 1: Multiple reads of same registers
    add x8, x2, x3       # Read x2, x3
    sub x9, x2, x3       # Read x2, x3 again
    mul x10, x2, x3      # Read x2, x3 again
    div x11, x2, x3      # Read x2, x3 again
    
    # Group 2: Chained dependencies with shared registers
    add x12, x4, x5      # Read x4, x5
    sub x13, x4, x12     # Read x4, x12 (dependent on previous)
    mul x14, x12, x13    # Read x12, x13 (dependent on previous two)
    div x15, x14, x4     # Read x14, x4 (dependent on previous, reuse x4)
    
    # Group 3: Interleaved dependencies
    add x16, x6, x7      # Read x6, x7
    mul x17, x2, x3      # Read x2, x3 (from Group 1)
    sub x18, x16, x4     # Read x16 (from Group 3), x4 (from Group 2)
    div x19, x17, x12    # Read x17 (from Group 3), x12 (from Group 2)
    
    # Group 4: Write port contention
    add x20, x2, x3      # Write to x20
    add x21, x4, x5      # Write to x21
    add x22, x6, x7      # Write to x22
    add x23, x8, x9      # Write to x23, read x8, x9 (from Group 1)
    add x24, x12, x13    # Write to x24, read x12, x13 (from Group 2)
    add x25, x16, x17    # Write to x25, read x16, x17 (from Group 3)
    
    # Group 5: Immediate read after write
    add x26, x2, x3      # Write to x26
    mul x27, x26, x4     # Read x26 immediately after write
    add x28, x26, x27    # Read x26, x27 immediately after writes
    
    # Store results to check
    sw x8, 0(x1)
    sw x9, 4(x1)
    sw x10, 8(x1)
    sw x11, 12(x1)
    sw x12, 16(x1)
    sw x13, 20(x1)
    sw x14, 24(x1)
    sw x15, 28(x1)
    sw x16, 32(x1)
    sw x17, 36(x1)
    sw x18, 40(x1)
    sw x19, 44(x1)
    sw x28, 48(x1)















    # Instruction Cache Pressure Test
    # Initialize memory region
    li x1, 0xC6000000
    
    # Jump to different code regions to create I-cache pressure
    j region1
    
    # Pad with many NOPs to push regions apart
    .rept 100
    nop
    .endr
    
region1:
    # First code region
    li x2, 0x11111111
    li x3, 0x22222222
    add x4, x2, x3
    sw x4, 0(x1)
    j region2
    
    # More padding
    .rept 100
    nop
    .endr
    
region2:
    # Second code region
    li x5, 0x33333333
    li x6, 0x44444444
    sub x7, x6, x5
    sw x7, 4(x1)
    j region3
    
    # More padding
    .rept 100
    nop
    .endr
    
region3:
    # Third code region
    li x8, 0x55555555
    li x9, 0x66666666
    mul x10, x8, x9
    sw x10, 8(x1)
    j region4
    
    # More padding
    .rept 100
    nop
    .endr
    
region4:
    # Fourth code region
    li x11, 0x77777777
    li x12, 0x88888888
    div x13, x12, x11
    sw x13, 12(x1)
    j region5
    
    # More padding
    .rept 100
    nop
    .endr
    
region5:
    # Fifth code region - now jump back to create conflicts
    lw x14, 0(x1)
    lw x15, 4(x1)
    add x16, x14, x15
    sw x16, 16(x1)
    j region1_revisit
    
    # More padding
    .rept 100
    nop
    .endr
    
region1_revisit:
    # Revisit first region
    lw x17, 8(x1)
    lw x18, 12(x1)
    sub x19, x17, x18
    sw x19, 20(x1)
    j region3_revisit
    
    # More padding
    .rept 100
    nop
    .endr
    
region3_revisit:
    # Revisit third region
    lw x20, 16(x1)
    lw x21, 20(x1)
    mul x22, x20, x21
    sw x22, 24(x1)
    
    # Final check - load all results and verify
    lw x23, 0(x1)
    lw x24, 4(x1)
    lw x25, 8(x1)
    lw x26, 12(x1)
    lw x27, 16(x1)
    lw x28, 20(x1)
    lw x29, 24(x1)
    
    # Final computation with all loaded values
    add x30, x23, x24
    add x30, x30, x25
    add x30, x30, x26
    add x30, x30, x27
    add x30, x30, x28
    add x30, x30, x29
    
    # Store final result
    sw x30, 28(x1)








halt:
    slti x0, x0, -256