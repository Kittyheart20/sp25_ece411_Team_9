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

add x4, x5, x6
sll x10, x11, x12
and x13, x14, x15

halt:
    slti x0, x0, -256