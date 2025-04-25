# Basic Load/Store Test Suite
.globl _start
_start:
    # Initialize base address for tests (ensure 4-byte alignment)
    li x1, 0x80001000    # Base memory address
    
    # Test 1: Basic Store Word / Load Word
    li x2, 0xDEADBEEF    # Test pattern
    sw x2, 0(x1)         # Store at base address
    lw x3, 0(x1)         # Load from same address
    li x4, 0xDEADBEEF    # Expected value
    bne x3, x4, fail     # Verify correct value loaded
    
    # Test 2: Store Half / Load Half (aligned)
    li x2, 0x0000CAFE    # Test pattern (16 bits)
    sh x2, 4(x1)         # Store at base+4
    lh x3, 4(x1)         # Load signed half
    li x4, 0xFFFFCAFE    # Expected value (sign extended)
    bne x3, x4, fail
    lhu x3, 4(x1)        # Load unsigned half
    li x4, 0x0000CAFE    # Expected value (zero extended)
    bne x3, x4, fail
    
    # Test 3: Store Byte / Load Byte (aligned)
    li x2, 0x000000A5    # Test pattern (8 bits)
    sb x2, 8(x1)         # Store at base+8
    lb x3, 8(x1)         # Load signed byte
    li x4, 0xFFFFFFA5    # Expected value (sign extended)
    bne x3, x4, fail
    lbu x3, 8(x1)        # Load unsigned byte
    li x4, 0x000000A5    # Expected value (zero extended)
    bne x3, x4, fail
    
    j test_passed
    
fail:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    j test_end
    
test_passed:
    li x31, 0x1          # Success indicator
    
test_end:
    # End of test








    # Memory Dependency Test Suite
.section .text

    # Initialize memory region
    li x1, 0x80001100    # Base memory address
    
    # Test 1: RAW Dependency (Store followed by Load to same address)
    li x2, 0x12345678
    sw x2, 0(x1)         # Store to address
    lw x3, 0(x1)         # Load from same address (RAW dependency)
    bne x3, x2, fail     # Should get the just-stored value
    
    # Test 2: WAR Dependency (Load followed by Store to same address)
    li x4, 0xAABBCCDD
    sw x4, 4(x1)         # Initialize memory
    lw x5, 4(x1)         # Load value
    li x6, 0x99887766
    sw x6, 4(x1)         # Store new value (WAR dependency)
    lw x7, 4(x1)         # Load to verify
    bne x7, x6, fail     # Should get the new value
    
    # Test 3: WAW Dependency (Store followed by Store to same address)
    li x8, 0x11223344
    sw x8, 8(x1)         # First store
    li x9, 0x55667788
    sw x9, 8(x1)         # Second store (WAW dependency)
    lw x10, 8(x1)        # Load to verify
    bne x10, x9, fail    # Should get the second stored value
    
    # Test 4: Multiple RAW Dependencies
    li x11, 0xABCDEF01
    sw x11, 12(x1)       # Store initial value
    lw x12, 12(x1)       # Load (RAW dependency)
    li x13, 0x10FEDCBA
    sw x13, 12(x1)       # Store new value
    lw x14, 12(x1)       # Load again (RAW dependency)
    bne x12, x11, fail   # First load should get initial value
    bne x14, x13, fail   # Second load should get new value









# Sequential Memory Access Test
.section .text

    # Initialize memory region with sequential pattern
    li x1, 0x80001200    # Base memory address
    li x2, 0             # Counter
    li x3, 10            # Number of words to initialize
    
init_loop:
    sw x2, 0(x1)         # Store counter value
    addi x1, x1, 4       # Increment address
    addi x2, x2, 1       # Increment counter
    blt x2, x3, init_loop
    
    # Reset address and verify sequential reads
    li x1, 0x80001200    # Reset base address
    li x2, 0             # Reset counter
    
verify_loop:
    lw x4, 0(x1)         # Load value
    bne x4, x2, fail     # Verify correct sequence
    addi x1, x1, 4       # Increment address
    addi x2, x2, 1       # Increment counter
    blt x2, x3, verify_loop

    

    # Memory Forwarding Test
.section .text

    # Test 1: Store-to-Load Forwarding (no intermediate memory access)
    li x1, 0x80001300    # Base memory address
    li x2, 0xFEDCBA98    # Test pattern
    
    sw x2, 0(x1)         # Store value
    lw x3, 0(x1)         # Load should be forwarded from store buffer
    bne x3, x2, fail
    
    # Test 2: Store-to-Load Forwarding with offset
    li x4, 0x76543210
    sw x4, 4(x1)         # Store at offset
    lw x5, 4(x1)         # Load from same offset
    bne x5, x4, fail
    
    # Test 3: Multiple Store-to-Load Forwarding
    li x6, 0x13579BDF
    li x7, 0x2468ACE0
    
    sw x6, 8(x1)         # First store
    sw x7, 12(x1)        # Second store
    lw x8, 8(x1)         # Load from first address
    lw x9, 12(x1)        # Load from second address
    bne x8, x6, fail
    bne x9, x7, fail
    
    # Test 4: Partial Store-to-Load Forwarding (byte)
    li x10, 0xFF         # 8-bit pattern
    sb x10, 16(x1)       # Store byte
    lb x11, 16(x1)       # Load signed byte
    li x12, 0xFFFFFFFF   # Expected sign-extended value
    bne x11, x12, fail
    





    # Interleaved Load/Store Test
.section .text

    # Initialize memory region
    li x1, 0x80001400    # Base memory address
    li x2, 0x11111111
    li x3, 0x22222222
    li x4, 0x33333333
    li x5, 0x44444444
    
    # Store values to consecutive addresses
    sw x2, 0(x1)
    sw x3, 4(x1)
    sw x4, 8(x1)
    sw x5, 12(x1)
    
    # Interleaved loads and stores
    lw x6, 0(x1)         # Load from first address
    sw x6, 16(x1)        # Store to new address
    lw x7, 4(x1)         # Load from second address
    sw x7, 20(x1)        # Store to new address
    lw x8, 16(x1)        # Load previously stored value
    lw x9, 8(x1)         # Load from third address
    sw x8, 24(x1)        # Store previously loaded value
    lw x10, 20(x1)       # Load previously stored value
    
    # Verify correct values
    bne x6, x2, fail
    bne x7, x3, fail
    bne x8, x2, fail
    bne x9, x4, fail
    bne x10, x3, fail
    






    # Memory Stress Test
.section .text

    # Initialize memory region for stress test
    li x1, 0x80001500    # Base memory address
    li x2, 16            # Number of words to access
    
    # Fill memory with incrementing pattern
    li x3, 0             # Counter
    mv x4, x1            # Current address
    
fill_loop:
    sw x3, 0(x4)         # Store counter value
    addi x3, x3, 1       # Increment counter
    addi x4, x4, 4       # Increment address
    blt x3, x2, fill_loop
    
    # Perform interleaved loads and stores with high traffic
    mv x4, x1            # Reset address pointer
    li x3, 0             # Reset counter
    
stress_loop:
    lw x5, 0(x4)         # Load value
    addi x5, x5, 100     # Modify value
    sw x5, 0(x4)         # Store back
    addi x4, x4, 4       # Move to next word
    addi x3, x3, 1       # Increment counter
    blt x3, x2, stress_loop
    
    # Verify all values were correctly modified
    mv x4, x1            # Reset address pointer
    li x3, 0             # Reset counter
    
verify_stress:
    lw x5, 0(x4)         # Load value
    addi x6, x3, 100     # Expected value
    bne x5, x6, fail     # Verify
    addi x4, x4, 4       # Move to next word
    addi x3, x3, 1       # Increment counter
    blt x3, x2, verify_stress
    





    # Half-Word and Byte Access Test
.section .text

    # Initialize memory region
    li x1, 0x80001600    # Base memory address
    
    # Test 1: Byte access pattern within a word
    li x2, 0x00000000    # Clear word
    sw x2, 0(x1)         # Store cleared word
    
    li x3, 0x000000AA    # Byte pattern 1
    sb x3, 0(x1)         # Store to byte 0
    li x4, 0x000000BB    # Byte pattern 2
    sb x4, 1(x1)         # Store to byte 1
    li x5, 0x000000CC    # Byte pattern 3
    sb x5, 2(x1)         # Store to byte 2
    li x6, 0x000000DD    # Byte pattern 4
    sb x6, 3(x1)         # Store to byte 3
    
    lw x7, 0(x1)         # Load entire word
    li x8, 0xDDCCBBAA    # Expected pattern
    bne x7, x8, fail
    
    # Test 2: Half-word access pattern within a word
    li x2, 0x00000000    # Clear word
    sw x2, 4(x1)         # Store cleared word
    
    li x3, 0x0000AAAA    # Half-word pattern 1
    sh x3, 4(x1)         # Store to lower half
    li x4, 0x0000BBBB    # Half-word pattern 2
    sh x4, 6(x1)         # Store to upper half
    
    lw x5, 4(x1)         # Load entire word
    li x6, 0xBBBBAAAA    # Expected pattern
    bne x5, x6, fail
    
    # Test 3: Mixed byte/half-word access
    li x2, 0x00000000    # Clear word
    sw x2, 8(x1)         # Store cleared word
    
    li x3, 0x000000EE    # Byte pattern
    sb x3, 8(x1)         # Store to byte 0
    li x4, 0x0000FFFF    # Half-word pattern
    sh x4, 10(x1)        # Store to upper half
    
    lw x5, 8(x1)         # Load entire word
    li x6, 0xFFFF00EE    # Expected pattern
    bne x5, x6, fail
    


    # Load/Store with Computed Addresses
.section .text

    # Initialize memory region
    li x1, 0x80001700    # Base memory address
    li x2, 10            # Number of words to initialize
    li x3, 0x12345678    # Value to store
    
    # Store same value to multiple addresses using computed offsets
    li x4, 0             # Offset counter
    
store_computed:
    slli x5, x4, 2       # Convert counter to byte offset (x4 * 4)
    add x6, x1, x5       # Compute address
    sw x3, 0(x6)         # Store value
    addi x4, x4, 1       # Increment counter
    blt x4, x2, store_computed
    
    # Load from computed addresses in reverse order
    addi x4, x2, -1      # Start from last index
    
load_reverse:
    slli x5, x4, 2       # Convert to byte offset
    add x6, x1, x5       # Compute address
    lw x7, 0(x6)         # Load value
    bne x7, x3, fail     # All values should be the same
    addi x4, x4, -1      # Decrement counter
    bge x4, x0, load_reverse
    





    # Out-of-Order Memory Access Test
.section .text

    # Initialize memory region
    li x1, 0x80001800    # Base memory address
    
    # Setup test pattern
    li x2, 0xAABBCCDD
    li x3, 0x11223344
    li x4, 0x55667788
    li x5, 0x99AABBCC
    
    # Create potential for out-of-order execution by interleaving
    # memory operations with independent ALU operations
    
    sw x2, 0(x1)         # Store first value
    addi x10, x0, 100    # Independent operation
    mul x11, x10, x10    # Long-latency operation
    sw x3, 4(x1)         # Store second value
    addi x12, x10, 50    # Independent operation
    lw x6, 0(x1)         # Load first value (potential forwarding)
    sw x4, 8(x1)         # Store third value
    div x13, x11, x10    # Long-latency operation
    lw x7, 4(x1)         # Load second value
    addi x14, x12, 25    # Independent operation
    sw x5, 12(x1)        # Store fourth value
    lw x8, 8(x1)         # Load third value
    add x15, x13, x14    # Independent operation
    lw x9, 12(x1)        # Load fourth value
    
    # Verify all loaded values are correct
    bne x6, x2, fail
    bne x7, x3, fail
    bne x8, x4, fail
    bne x9, x5, fail
    




    # Memory Fence Test
.section .text

    # Initialize memory region
    li x1, 0x80001900    # Base memory address
    
    # Setup test pattern
    li x2, 0x12345678
    li x3, 0xABCDEF01
    
    # Store values
    sw x2, 0(x1)
    sw x3, 4(x1)
    
    # Insert memory fence to ensure all previous stores complete
    fence rw, rw
    
    # Load values (should see updated memory)
    lw x4, 0(x1)
    lw x5, 4(x1)
    
    # Verify values
    bne x4, x2, fail
    bne x5, x3, fail
    
    # Store new values
    li x6, 0x87654321
    li x7, 0x10FEDCBA
    
    sw x6, 0(x1)
    fence w, r          # Ensure store completes before subsequent loads
    lw x8, 0(x1)
    
    sw x7, 4(x1)
    fence w, r          # Ensure store completes before subsequent loads
    lw x9, 4(x1)
    
    # Verify values
    bne x8, x6, fail
    bne x9, x7, fail
    
halt:
    slti x0, x0, -256