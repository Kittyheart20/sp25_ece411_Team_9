# MULH (upper 32 bits of signed * signed)
    # mulh x17, x5, x5      # x17 = upper((0x80000000 * 0x80000000)) = 0x40000000
    # mulh x18, x6, x6      # x18 = upper((0x7FFFFFFF * 0x7FFFFFFF)) = 0x3FFFFFFF
    
    # MULHSU (upper 32 bits of signed * unsigned)
    # mulhsu x19, x5, x6    # x19 = upper((signed)0x80000000 * (unsigned)0x7FFFFFFF)
    # mulhsu x20, x4, x7    # x20 = upper((signed)-1 * (unsigned)10) #instr 53


    # MULHU (upper 32 bits of unsigned * unsigned)
    # mulhu x21, x6, x6     # x21 = upper((unsigned)0x7FFFFFFF * (unsigned)0x7FFFFFFF)
    # mulhu x22, x9, x10    # x22 = upper((unsigned)0xAAAAAAAA * (unsigned)0x55555555)
    
    # -------------------------------------------------------------------------
    # RV32M Divide Instructions
    # -------------------------------------------------------------------------
    
    # DIV (signed division)
    # div x23, x7, x13      # x23 = 10 / 7 = 1
    # div x24, x7, x4       # x24 = 10 / -1 = -10
    # div x25, x5, x1       # x25 = 0x80000000 / 1 = 0x80000000
   # div x26, x1, x8       # x26 = 1 / 0 = -1 (division by zero)
   # div x27, x5, x4       # x27 = 0x80000000 / -1 = 0x80000000 (overflow case)
    
    # DIVU (unsigned division)
  #  divu x28, x7, x13     # x28 = 10 / 7 = 1
  #  divu x29, x4, x2      # x29 = 0xFFFFFFFF / 2 = 0x7FFFFFFF
  #  divu x30, x1, x8      # x30 = 1 / 0 = 0xFFFFFFFF (division by zero)
    
    # REM (signed remainder)
   # rem x15, x7, x13      # x15 = 10 % 7 = 3
  #  rem x16, x7, x4       # x16 = 10 % -1 = 0
  #  rem x17, x5, x1       # x17 = 0x80000000 % 1 = 0
  #  rem x18, x1, x8       # x18 = 1 % 0 = 1 (division by zero)
  #  rem x19, x5, x4       # x19 = 0x80000000 % -1 = 0 (overflow case)
    
    # REMU (unsigned remainder)
  #  remu x20, x7, x13     # x20 = 10 % 7 = 3
   # remu x21, x4, x2      # x21 = 0xFFFFFFFF % 2 = 1
    # remu x22, x1, x8      # x22 = 1 % 0 = 1 (division by zero)
    
    # -------------------------------------------------------------------------
    # Additional tests to exercise OoO execution
    # -------------------------------------------------------------------------
    
    # Create dependencies that can be resolved out-of-order
  #  addi x1, x0, 100
  #  addi x2, x0, 200
  #  addi x3, x0, 300
    
    # Independent operations that can execute in parallel
  #  mul x4, x1, x2        # Can execute while the following instructions are being processed
 #   add x5, x1, x3
 #   xor x6, x2, x3
 #   and x7, x1, x2
    
    # Create a dependency chain with intermediate results
 #   addi x8, x0, 5
 #   mul x9, x8, x8        # x9 = 25
 #   add x10, x9, x9       # x10 = 50, depends on x9
 #   div x11, x10, x8      # x11 = 10, depends on x10 and x8
 #   rem x12, x11, x8      # x12 = 0, depends on x11 and x8
    
    # Create potential for memory forwarding
#    addi x13, x0, 1
#    addi x14, x0, 2
#    mul x15, x13, x14     # x15 = 2
#    add x13, x15, x13     # x13 = 3, depends on x15
#    sub x14, x13, x15     # x14 = 1, depends on both x13 and x15
    
    # Test for potential hazards
#   addi x16, x0, 10
#    div x17, x16, x13     # Division with result from previous computation
#    mul x18, x17, x14     # Multiply with results from previous computations
#    rem x19, x18, x16     # Remainder with results from previous computations