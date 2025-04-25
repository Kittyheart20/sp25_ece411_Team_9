# Basic Load/Store Test Suite
.globl _start
_start:
    # Initialize base address for tests (within valid range but offset from PC)
    li x1, 0xABBBB000    # Base memory address (offset from PC)
    
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
.globl _start
_start:
    # Initialize memory region (valid address range)
    li x1, 0xACCCC100    # Base memory address (well away from code)
    
    # Test 1: RAW Dependency (Store followed by Load to same address)
    li x2, 0x12345678
    sw x2, 0(x1)         # Store to address
    lw x3, 0(x1)         # Load from same address (RAW dependency)
    bne x3, x2, fail_2     # Should get the just-stored value
    
    # Test 2: WAR Dependency (Load followed by Store to same address)
    li x4, 0xAABBCCDD
    sw x4, 4(x1)         # Initialize memory
    lw x5, 4(x1)         # Load value
    li x6, 0x99887766
    sw x6, 4(x1)         # Store new value (WAR dependency)
    lw x7, 4(x1)         # Load to verify
    bne x7, x6, fail_2     # Should get the new value
    
    # Test 3: WAW Dependency (Store followed by Store to same address)
    li x8, 0x11223344
    sw x8, 8(x1)         # First store
    li x9, 0x55667788
    sw x9, 8(x1)         # Second store (WAW dependency)
    lw x10, 8(x1)        # Load to verify
    bne x10, x9, fail_2    # Should get the second stored value
    
    # Test 4: Multiple RAW Dependencies
    li x11, 0xABCDEF01
    sw x11, 12(x1)       # Store initial value
    lw x12, 12(x1)       # Load (RAW dependency)
    li x13, 0x10FEDCBA
    sw x13, 12(x1)       # Store new value
    lw x14, 12(x1)       # Load again (RAW dependency)
    bne x12, x11, fail_2   # First load should get initial value
    bne x14, x13, fail_2   # Second load should get new value
    
    j test_passed_2
    
fail_2:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_2:
    li x31, 0x1          # Success indicator







# Sequential Memory Access Test
.section .text
.globl _start
_start:
    # Initialize memory region with sequential pattern (valid address range)
    li x1, 0xADDDD200    # Base memory address (well away from code)
    li x2, 0             # Counter
    li x3, 10            # Number of words to initialize
    
init_loop:
    sw x2, 0(x1)         # Store counter value
    addi x1, x1, 4       # Increment address
    addi x2, x2, 1       # Increment counter
    blt x2, x3, init_loop
    
    # Reset address and verify sequential reads
    li x1, 0xADDDD200    # Reset base address
    li x2, 0             # Reset counter
    
verify_loop:
    lw x4, 0(x1)         # Load value
    bne x4, x2, fail     # Verify correct sequence
    addi x1, x1, 4       # Increment address
    addi x2, x2, 1       # Increment counter
    blt x2, x3, verify_loop
    
    j test_passed_3
    
fail_3:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_3:
    li x31, 0x1          # Success indicator












    # Memory Forwarding Test
.section .text
.globl _start
_start:
    # Test 1: Store-to-Load Forwarding (valid address range)
    li x1, 0xAEEEE300    # Base memory address (well away from code)
    li x2, 0xFEDCBA98    # Test pattern
    
    sw x2, 0(x1)         # Store value
    lw x3, 0(x1)         # Load should be forwarded from store buffer
    bne x3, x2, fail_4
    
    # Test 2: Store-to-Load Forwarding with offset
    li x4, 0x76543210
    sw x4, 4(x1)         # Store at offset
    lw x5, 4(x1)         # Load from same offset
    bne x5, x4, fail_4
    
    # Test 3: Multiple Store-to-Load Forwarding
    li x6, 0x13579BDF
    li x7, 0x2468ACE0
    
    sw x6, 8(x1)         # First store
    sw x7, 12(x1)        # Second store
    lw x8, 8(x1)         # Load from first address
    lw x9, 12(x1)        # Load from second address
    bne x8, x6, fail_4
    bne x9, x7, fail_4
    
    # Test 4: Partial Store-to-Load Forwarding (byte)
    li x10, 0xFF         # 8-bit pattern
    sb x10, 16(x1)       # Store byte
    lb x11, 16(x1)       # Load signed byte
    li x12, 0xFFFFFFFF   # Expected sign-extended value
    bne x11, x12, fail_4
    
    j test_passed_4
    
fail_4:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_4:
    li x31, 0x1          # Success indicator





    


# Out-of-Order Memory Access Test
.section .text
.globl _start
_start:
    # Initialize memory region (valid address range)
    li x1, 0xAFFFF800    # Base memory address (well away from code)
    
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
    
    j test_passed_5
    
fail_5:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_5:
    li x31, 0x1          # Success indicator










    # Cache Line Boundary Test
.section .text
.globl _start
_start:
    # Test memory operations across cache line boundaries
    # Assuming 64-byte cache lines
    li x1, 0xB111103C    # 4 bytes before potential 64-byte boundary
    li x2, 0xB1111040    # At potential 64-byte boundary
    
    # Store distinct patterns
    li x3, 0x11111111
    li x4, 0x22222222
    
    # Store across potential boundary
    sw x3, 0(x1)         # Last word in cache line
    sw x4, 0(x2)         # First word in next cache line
    
    # Load and verify
    lw x5, 0(x1)
    lw x6, 0(x2)
    
    bne x5, x3, fail_6
    bne x6, x4, fail_6
    
    # Test with a sequence of values across multiple potential boundaries
    li x1, 0xB2222000    # Starting address
    li x2, 4             # Number of potential cache lines to cross
    li x3, 0             # Counter
    
cache_line_loop:
    slli x4, x3, 6       # Convert to byte offset (cache line size = 64)
    add x5, x1, x4       # Address at start of potential cache line
    sw x3, 0(x5)         # Store counter value
    addi x3, x3, 1       # Increment counter
    blt x3, x2, cache_line_loop
    
    # Verify values
    li x3, 0             # Reset counter
    
verify_cache_lines:
    slli x4, x3, 6       # Convert to byte offset
    add x5, x1, x4       # Address at start of potential cache line
    lw x6, 0(x5)         # Load value
    bne x6, x3, fail_6     # Verify correct value
    addi x3, x3, 1       # Increment counter
    blt x3, x2, verify_cache_lines
    
    j test_passed_6
    
fail_6:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_6:
    li x31, 0x1          # Success indicator













    # Mixed Data Size Access Test
.section .text
.globl _start
_start:
    # Initialize memory region (valid address range)
    li x1, 0xB3333000    # Base memory address (well away from code)
    
    # Clear memory region
    li x2, 0
    sw x2, 0(x1)
    sw x2, 4(x1)
    sw x2, 8(x1)
    sw x2, 12(x1)
    
    # Test pattern: Store bytes, half-words, and words interleaved
    li x3, 0xAA          # Byte pattern
    li x4, 0xBBBB        # Half-word pattern
    li x5, 0xCCCCCCCC    # Word pattern
    
    # Store mixed sizes
    sb x3, 0(x1)         # Byte at offset 0
    sh x4, 2(x1)         # Half-word at offset 2
    sw x5, 4(x1)         # Word at offset 4
    sb x3, 8(x1)         # Byte at offset 8
    sh x4, 10(x1)        # Half-word at offset 10
    
    # Load and verify individual elements
    lbu x6, 0(x1)        # Load unsigned byte
    lhu x7, 2(x1)        # Load unsigned half-word
    lw x8, 4(x1)         # Load word
    lbu x9, 8(x1)        # Load unsigned byte
    lhu x10, 10(x1)      # Load unsigned half-word
    
    # Verify correct values
    li x11, 0xAA
    bne x6, x11, fail_7
    li x11, 0xBBBB
    bne x7, x11, fail_7
    li x11, 0xCCCCCCCC
    bne x8, x11, fail_7
    li x11, 0xAA
    bne x9, x11, fail_7
    li x11, 0xBBBB
    bne x10, x11, fail_7
    
    # Load and verify combined values
    lw x12, 0(x1)        # Load word containing byte + half-word
    li x13, 0xBBBB00AA   # Expected pattern
    bne x12, x13, fail_7
    
    lw x14, 8(x1)        # Load word containing byte + half-word
    li x15, 0xBBBB00AA   # Expected pattern
    bne x14, x15, fail_7
    
    j test_passed_7
    
fail_7:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_7:
    li x31, 0x1          # Success indicator














    # Store Buffer Forwarding Test
.section .text
.globl _start
_start:
    # Test store buffer forwarding with multiple stores
    li x1, 0xB4444000    # Base memory address (well away from code)
    
    # Initialize memory with pattern
    li x2, 0xFFFFFFFF
    sw x2, 0(x1)
    sw x2, 4(x1)
    sw x2, 8(x1)
    
    # Test 1: Basic forwarding (store followed by load to same address)
    li x3, 0x12345678
    sw x3, 0(x1)         # Store to address 0
    lw x4, 0(x1)         # Load from same address (should forward)
    bne x4, x3, fail_8     # Verify forwarded value
    
    # Test 2: Partial forwarding (byte store followed by word load)
    li x5, 0xAB          # Byte value
    sb x5, 4(x1)         # Store byte to address 4
    lw x6, 4(x1)         # Load word from address 4
    li x7, 0xFFFFFFAB    # Expected value: original word with byte replaced
    bne x6, x7, fail_8     # Verify partial forwarding
    
    # Test 3: Multiple stores to same address
    li x8, 0x11111111
    li x9, 0x22222222
    li x10, 0x33333333
    
    sw x8, 8(x1)         # First store
    sw x9, 8(x1)         # Second store (overwrites first)
    sw x10, 8(x1)        # Third store (overwrites second)
    lw x11, 8(x1)        # Load (should get third store)
    bne x11, x10, fail_8   # Verify most recent store is forwarded
    
    # Test 4: Store-to-load forwarding with offset
    li x12, 0xAAAAAAAA
    li x13, 0xBBBBBBBB
    
    sw x12, 12(x1)       # Store to address 12
    sw x13, 16(x1)       # Store to address 16
    lw x14, 12(x1)       # Load from address 12
    lw x15, 16(x1)       # Load from address 16
    
    bne x14, x12, fail_8
    bne x15, x13, fail_8
    
    j test_passed_8
    
fail_8:
    # Test failed handling
    li x31, 0xFFFFFFFF   # Error indicator
    
test_passed_8:
    li x31, 0x1          # Success indicator

    
halt:
    slti x0, x0, -256