    .text
    .global _start
_start:
    #-------------------------------------------
    # 1. Put 0x1000 into x15 – this is the target
    #    address for both the store *and* the load
    #-------------------------------------------
        li      x15, 0x1000        # x15 (a5) = 0x1000

    #-------------------------------------------
    # 2. Cause a **branch-mispredict window** so
    #    the load can execute before the store
    #    (common on superscalar/Tomasulo cores
    #    that don't interlock loads with older
    #    unknown-address stores).
    #-------------------------------------------
        li      x6,  3             # x6  = loop counter
loop:
        addi    x6, x6, -1
        bnez    x6, loop           # predictable loop …

        # ------ critical sequence starts here ------
        # Assume your branch predictor wrongly thinks
        # the next branch *IS* taken and issues the
        # load early.
        #
        # 2a. The branch depends on x7, which we
        #     deliberately make slow to compute.
        #-------------------------------------------
        li      x7,  0             # x7 = 0 (makes branch fall-through)
        mul     x7, x7, x6         # a useless multi-cycle op
        beq     x7, x0, after_store

        #-------------------------------------------
        # 3. STORE (older in program order, but its
        #    *address* is still waiting to be written
        #    into the store queue because of the MUL).
        #-------------------------------------------
        li      x5,  0xAB          # byte we want to read later
        sb      x5, 0(x15)         # <-- should reach LSU *before* load

after_store:
        #-------------------------------------------
        # 4. LOAD that *must* see 0xAB.
        #    If it executes early, it will fetch 0x00.
        #-------------------------------------------
        lbu     x11, 0(x15)        # FAILS if load bypass logic wrong

        # Quick visible result: put value in a0 and ecall
        mv      a0, x11            # a0 = what we actually read
        li      a7, 1              # write syscall on most simulators
        ecall                      

        # Spin forever so we can look at the wave
hang:   j       hang


halt:
    slti x0, x0, -256
