covergroup instr_cg with function sample(instr_t instr);
    // Easy covergroup to see that we're at least exercising
    // every opcode. Since opcode is an enum, this makes bins
    // for all its members.
    all_opcodes : coverpoint instr.i_type.opcode;


    // Some simple coverpoints on various instruction fields.
    // Recognize that these coverpoints are inherently less useful
    // because they really make sense in the context of the opcode itself.
    all_funct7 : coverpoint funct7_t'(instr.r_type.funct7);

    // TODO: Write the following coverpoints:

    // Check that funct3 takes on all possible values.
    // all_funct3 : coverpoint ... ;
    all_funct3 : coverpoint instr.i_type.funct3;

    // Check that the rs1 and rs2 fields across instructions take on
    // all possible values (each register is touched).
    // all_regs_rs1 : coverpoint ... ;
    all_regs_rs1 : coverpoint instr.i_type.rs1 {
        bins regs[32] = {[0:31]};
    }
    // all_regs_rs2 : coverpoint ... ;
    all_regs_rs2 : coverpoint instr.r_type.rs2 {
        bins regs[32] = {[0:31]};
    }

    // Now, cross coverage takes in the opcode context to correctly
    // figure out the /actual/ coverage.
    funct3_cross : cross instr.i_type.opcode, instr.i_type.funct3 {

        // We want to ignore the cases where funct3 isn't relevant.

        // For example, for JAL, funct3 doesn't exist. Put it in an ignore_bins.
        ignore_bins JAL_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_jal);

        // TODO:    What other opcodes does funct3 not exist for? Put those in
        // ignore_bins.
        ignore_bins LUI_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_lui);
        ignore_bins AUIPC_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_auipc);

        // Branch instructions use funct3, but only 6 of the 8 possible values
        // are valid. Ignore the other two -- don't add them into the coverage
        // report. In fact, if they're generated, that's an illegal instruction.
        illegal_bins BR_FUNCT3 = funct3_cross with
        (instr.i_type.opcode == op_b_br
        && !(instr.i_type.funct3 inside {branch_f3_beq, branch_f3_bne, branch_f3_blt, branch_f3_bge, branch_f3_bltu, branch_f3_bgeu}));

        // TODO: You'll also have to ignore some funct3 cases in JALR, LOAD, and
        // STORE. Write the illegal_bins/ignore_bins for those cases.

        illegal_bins JALR_FUNCT3 = funct3_cross with (
            instr.i_type.opcode == op_b_jalr && instr.i_type.funct3 != 3'b000
        );

        illegal_bins LOAD_FUNCT3 = funct3_cross with (
            instr.i_type.opcode == op_b_load &&
            !(instr.i_type.funct3 inside { load_f3_lb, load_f3_lh, load_f3_lw,
                                            load_f3_lbu, load_f3_lhu })
        );

        illegal_bins STORE_FUNCT3 = funct3_cross with (
            instr.i_type.opcode == op_b_store &&
            !(instr.i_type.funct3 inside { store_f3_sb, store_f3_sh, store_f3_sw })
        );
    }

    // Coverpoint to make separate bins for funct7.
    coverpoint instr.r_type.funct7 {
        bins range[] = {[0:$]};
        ignore_bins not_in_spec = {[2:31], [33:127]};
    }

    // Cross coverage for funct7.
    funct7_cross : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7 {

        // No opcodes except op_b_reg and op_b_imm use funct7, so ignore the rest.
        ignore_bins OTHER_INSTS = funct7_cross with
        (!(instr.r_type.opcode inside {op_b_reg, op_b_imm}));
        // ignore_bins OTHER_INSTS = funct7_cross with
        // (!(instr.r_type.opcode inside {op_b_reg}));

        // TODO: Get rid of all the other cases where funct7 isn't necessary, or cannot
        // take on certain values.

        ignore_bins NON_SHIFT_IMM = funct7_cross with (
            (instr.r_type.opcode == op_b_imm) &&
            ((instr.r_type.funct3 != arith_f3_sll) &&
             (instr.r_type.funct3 != arith_f3_sr))
        );
        
    // illegal_bins R_VARIANT_ILLEGAL = funct7_cross with (
    //     (instr.r_type.opcode == op_b_reg) &&
    //     ((instr.r_type.funct3 == arith_f3_add ||
    //       instr.r_type.funct3 == arith_f3_sr) &&
    //      !(instr.r_type.funct7 inside {7'b0100000, 7'b0000000}))
    // );
    
    // illegal_bins REG_VARIANT_ILLEGAL = funct7_cross with (
    //     (instr.r_type.opcode == op_b_reg) &&
    //     (((instr.r_type.funct3 inside {arith_f3_add, arith_f3_sr}) &&
    //      !(instr.r_type.funct7 inside {7'b0100000,  7'b0000001, 7'b0000000})) ||
         
    //      !((instr.r_type.funct3 inside {arith_f3_add, arith_f3_sr}) &&
    //      !(instr.r_type.funct7 inside {7'b0000001, 7'b0000000})))
    // );

    illegal_bins REG_VARIANT_ILLEGAL = funct7_cross with (
        (instr.r_type.opcode == op_b_reg) &&
        !(
            ((instr.r_type.funct3 inside {arith_f3_add, arith_f3_sr}) &&
            (instr.r_type.funct7 inside {7'b0100000, 7'b0000001, 7'b0000000})) ||

            (!(instr.r_type.funct3 inside {arith_f3_add, arith_f3_sr}) &&
            (instr.r_type.funct7 inside {7'b0000001, 7'b0000000}))
        )
    );

    // illegal_bins REG_NON_VARIANT_ILLEGAL = funct7_cross with (
    //     (instr.r_type.opcode == op_b_reg) &&
    //     (!(instr.r_type.funct3 inside {arith_f3_add, arith_f3_sr, mult_op_mul, mult_op_mulh, mult_op_mulhsu, 
    //                                     mult_op_mulhu, mult_op_div, mult_op_divu, 
    //                                     mult_op_rem, mult_op_remu}) &&
    //      (instr.r_type.funct7 != 7'b0000001))
    // );


    illegal_bins IMM_SHIFT_VARIANT_ILLEGAL = funct7_cross with (
        (instr.r_type.opcode == op_b_imm) &&
        (instr.r_type.funct3 == arith_f3_sr) &&
        !(instr.r_type.funct7 inside {7'b0100000, 7'b0000000})
    );


    illegal_bins IMM_SHIFT_NON_VARIANT_ILLEGAL = funct7_cross with (
        (instr.r_type.opcode == op_b_imm) &&
        (instr.r_type.funct3 == arith_f3_sll) &&
        (instr.r_type.funct7 != 7'b0000000)
    );


        
    }

endgroup : instr_cg
