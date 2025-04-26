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
 









halt:
    slti x0, x0, -256