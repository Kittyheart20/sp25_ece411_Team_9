ooo_test.s:
.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:

# initialize
li x1, 10
nop
add x1, x1, x1

li x2, 20
li x5, 50
li x6, 60
li x8, 21
li x9, 28
li x11, 8
li x12, 4
li x14, 3
li x15, 1

nop 
nop
nop
nop
nop
nop

# this should take many cycles
# if this writes back to the ROB after the following instructions, you get credit for CP2
mul x3, x1, x2 # c8 & rob 16

# these instructions should  resolve before the multiply
add x4, x5, x6 # 6E
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15
li x20, 6
add x1, x1, x1

# this should take many cycles
# if this writes back to the ROB after the following instructions, you get credit for CP2
mul x3, x1, x2 # c8 & rob 16

# these instructions should  resolve before the multiply
add x4, x5, x6 # 6E
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15
li x20, 6
add x1, x1, x1


mul x16, x4, x2       # x16 = -1 * 2 = -2

halt:
    slti x0, x0, -256
