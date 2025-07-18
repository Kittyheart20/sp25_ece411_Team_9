// This class generates random valid RISC-V instructions to test your
// RISC-V cores.

class RandInst;
    // import rv32i_types::*;
    // You will increment this number as you generate more random instruction
    // types. Once finished, NUM_TYPES should be 9, for each opcode type in
    // rv32i_opcode.
    localparam NUM_TYPES = 3;

    // Note that the 'instr_t' type is from ../pkg/types.sv, there are TODOs
    // you must complete there to fully define 'instr_t'.
    rand instr_t instr;
    rand bit [NUM_TYPES-1:0] instr_type;

    // Make sure we have an even distribution of instruction types.
    constraint solve_order_c { solve instr_type before instr; }

    // Hint/TODO: you will need another solve_order constraint for funct3
    // to get 100% coverage with 500 calls to .randomize().
    // constraint solve_order_funct3_c { ... }
    rand logic [2:0] funct3_rand;
    rand logic [6:0] funct7_rand;

    constraint funct3_assign_c {
        instr.i_type.funct3 == funct3_rand;
    }
    constraint solve_order_funct3_c {
        solve funct3_rand before instr;
    }
    constraint funct7_assign_c {
        instr.r_type.funct7 == funct7_rand;
    }

    constraint solve_order_funct3_before_funct7_c {
        solve funct3_rand before funct7_rand;
    }

    // Pick one of the instruction types.
    constraint instr_type_c {
        $countones(instr_type) == 1; // Ensures one-hot.
    }

    // Constraints for actually generating instructions, given the type.
    // Again, see the instruction set listings to see the valid set of
    // instructions, and constrain to meet it. Refer to ../pkg/types.sv
    // to see the typedef enums.

    constraint instr_c {
        // Reg-imm instructions
        instr_type[0] -> {
            instr.i_type.opcode == op_b_imm;

            // Implies syntax: if funct3 is arith_f3_sr, then funct7 must be
            // one of two possibilities.
            instr.i_type.funct3 == arith_f3_sr -> {
                // Use r_type here to be able to constrain funct7.
                instr.r_type.funct7 inside {base, variant};
            }

            // This if syntax is equivalent to the implies syntax above
            // but also supports an else { ... } clause.
            if (instr.i_type.funct3 == arith_f3_sll) {
                instr.r_type.funct7 == base;
            }
        }

        // Reg-reg instructions
        // instr_type[1] -> {
        //         // TODO: Fill this out!
        // }

        instr_type[1] -> {
            instr.r_type.opcode == op_b_reg;
            // Valid R-type arithmetic operations.
            instr.r_type.funct3 inside { arith_f3_add, arith_f3_sll, arith_f3_slt,
                                        arith_f3_sltu, arith_f3_xor, arith_f3_sr,
                                        arith_f3_or,  arith_f3_and };

            // For instructions that allow variant encoding:
            // - When funct3 is ADD or SR, allow both base and variant.
            if (instr.r_type.funct3 == arith_f3_add ||
                instr.r_type.funct3 == arith_f3_sr)
                instr.r_type.funct7 inside { base, mult, variant };

            // else if (instr.r_type.funct3 == mult_op_mul)
            //     instr.r_type.funct7 == mult;
            else // For all others, only the base encoding is valid. + mult ext
                instr.r_type.funct7 inside {base, mult};
        }

            // Valid R-type arithmetic operations.
            // instr.r_type.funct3 inside { mult_op_mul, mult_op_mulh, mult_op_mulhsu, 
            //                             mult_op_mulhu, mult_op_div, mult_op_divu, 
            //                             mult_op_rem, mult_op_remu };

        // Store instructions -- these are easy to constrain!
// instr_type[3] -> {
//     instr.i_type.opcode == op_b_load;
//     // Valid load operations: LB, LH, LW, LBU, LHU.
//     instr.i_type.funct3 inside { load_f3_lb, load_f3_lh, load_f3_lw,
//                                   load_f3_lbu, load_f3_lhu };

//     // Enforce natural alignment:
//     // For half–word loads, force bit 0 of the immediate to 0.
//     if (instr.i_type.funct3 inside { load_f3_lh, load_f3_lhu }) {
//         instr.i_type.i_imm[0] == 1'b0;
//     }
//     // For word loads, force bits [1:0] of the immediate to 0.
//     else if (instr.i_type.funct3 == load_f3_lw) {
//         instr.i_type.i_imm[1:0] == 2'b00;
//     }
// }

// --- Store instructions --- 
// instr_type[2] -> {
//     instr.s_type.opcode == op_b_store;
//     instr.s_type.funct3 inside { store_f3_sb, store_f3_sh, store_f3_sw };

//     // Enforce natural alignment:
//     // Concatenate the two parts of the immediate into a 12–bit value.
//     // For half–word stores, force bit 0 to be 0.
//     if (instr.s_type.funct3 == store_f3_sh) {
//         {instr.s_type.imm_s_top, instr.s_type.imm_s_bot}[0] == 1'b0;
//     }
//     // For word stores, force bits [1:0] to be 0.
//     else if (instr.s_type.funct3 == store_f3_sw) {
//         {instr.s_type.imm_s_top, instr.s_type.imm_s_bot}[1:0] == 2'b00;
//     }
// }

//         instr_type[4] -> {
//             instr.b_type.opcode == op_b_br;
//             // Valid branch operations: BEQ, BNE, BLT, BGE, BLTU, BGEU.
//             instr.b_type.funct3 inside { branch_f3_beq, branch_f3_bne,
//                                           branch_f3_blt, branch_f3_bge,
//                                           branch_f3_bltu, branch_f3_bgeu };
//         }

        // Type 5: U-type LUI instruction.
        // U-type instructions have the same layout as the j_type struct.
        instr_type[2] -> {
            instr.j_type.opcode == op_b_lui;
        }

//         // Type 6: U-type AUIPC instruction.
//         instr_type[6] -> {
//             instr.j_type.opcode == op_b_auipc;
//         }

//         // Type 7: J-type JAL instruction.
//         instr_type[7] -> {
//             instr.j_type.opcode == op_b_jal;
//         }

//         // Type 8: I-type JALR instruction.
//         instr_type[8] -> {
//             instr.i_type.opcode == op_b_jalr;
//             // For JALR, the funct3 field must be 000.
//             instr.i_type.funct3 == 3'b000;
//         }

        // TODO: Do all 9 types!
    }

    `include "instr_cg.svh"

    // Constructor, make sure we construct the covergroup.
    function new();
        instr_cg = new();
    endfunction : new

    // Whenever randomize() is called, sample the covergroup. This assumes
    // that every generated random instruction are send it into the CPU.
    function void post_randomize();
        instr_cg.sample(this.instr);
    endfunction : post_randomize

    // A nice part of writing constraints is that we get constraint checking
    // for free -- this function will check if a bitvector is a valid RISC-V
    // instruction (assuming you have written all the relevant constraints).
    function bit verify_valid_instr(instr_t inp);
        bit valid = 1'b0;
        this.instr = inp;
        for (int i = 0; i < NUM_TYPES; ++i) begin
            this.instr_type = NUM_TYPES'(1 << i);
            if (this.randomize(null)) begin
                valid = 1'b1;
                break;
            end
        end
        return valid;
    endfunction : verify_valid_instr

endclass : RandInst
