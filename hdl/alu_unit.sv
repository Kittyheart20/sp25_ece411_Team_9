module alu_unit (
    input  logic        clk,
    input  logic        rst,
    input reservation_station_t next_execute
    output logic        ready,
);

    logic [31:0] a, b;

    always_comb begin
        a = '0;
        b = '0;

        if (id_ex_reg.valid && !rst) begin
            unique case (id_ex_reg.alu_m1_sel)
                rs1_out: a = rs1_for; 
                pc_out:	 a = id_ex_reg.pc;
                no_out:  a = '0;
                default: a = '0;
            endcase

            unique case (id_ex_reg.alu_m2_sel)
                rs2_out: b = rs2_for;
                imm_out: b = id_ex_reg.imm;
                four_out: b = 32'h4;
                default: b = '0;
            endcase
        end
    end

//     always_comb begin
//         aluout = '0;

//         if (id_ex_reg.valid && !rst && !(id_ex_reg.inst == 32'h13)) begin
//             unique case (id_ex_reg.aluop)
//                 alu_op_add: aluout = a +   b;
//                 alu_op_sll: aluout = a <<  b[4:0];
//                 alu_op_sra: aluout = unsigned'(signed'(a) >>> (b[4:0]));
//                 alu_op_sub: aluout = a -   b;
//                 alu_op_xor: aluout = a ^   b;
//                 alu_op_srl: aluout = a >>  b[4:0];
//                 alu_op_or : aluout = a |   b;
//                 alu_op_and: aluout = a &   b;
// 		        alu_op_slt: aluout = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
//                 alu_op_sltu: aluout = (a < b) ? 32'b1 : 32'b0;
//                 default   : aluout = '0;
//             endcase
//         end
//     end

endmodule