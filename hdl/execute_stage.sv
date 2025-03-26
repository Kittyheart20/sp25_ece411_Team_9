// module execute_stage 
// import rv32i_types::*;
// (
//     //input  logic           clk,
//     input  logic               rst,
//     input  logic               stall,
//     input  id_ex_stage_reg_t   id_ex_reg,
//     input  ex_mem_stage_reg_t  ex_mem_reg,
//     input  mem_wb_stage_reg_t  mem_wb_reg,
//     input  mem_wb_stage_reg_t  mem_wb_reg_next,
//     input  [31:0]              prev_wb_rd_data,
//     input  [4:0]               prev_wb_rd_addr,
//     output ex_mem_stage_reg_t  ex_mem_reg_next,
//     output logic               load_use_hazard,
//     output logic               br_en,
//     output logic  [31:0]       pc_branch
// );

//     logic [31:0] aluout;
//     logic [31:0] a, b, as, bs, au, bu;
//     logic [31:0] rs1_for, rs2_for;

//     assign load_use_hazard = id_ex_reg.valid && ex_mem_reg.valid && (ex_mem_reg.load || |mem_wb_reg_next.mem_wmask) && (ex_mem_reg.rd != 0) && 
//                             ((ex_mem_reg.rd == id_ex_reg.rs1_addr) || (ex_mem_reg.rd == id_ex_reg.rs2_addr)
//                             || (mem_wb_reg_next.rd == id_ex_reg.rs1_addr) || (mem_wb_reg_next.rd == id_ex_reg.rs2_addr));


//     always_comb begin
//         rs1_for = id_ex_reg.rs1_data;
//         rs2_for = id_ex_reg.rs2_data;
        
//         if (ex_mem_reg.valid && ex_mem_reg.regf_we && (ex_mem_reg.rd != 0) && 
//            (ex_mem_reg.rd == id_ex_reg.rs1_addr) && !ex_mem_reg.load) begin
//             rs1_for = ex_mem_reg.aluout;
//         end
//         else if (mem_wb_reg.valid && mem_wb_reg.regf_we && (mem_wb_reg.rd != 0) && 
//                 (mem_wb_reg.rd == id_ex_reg.rs1_addr)) begin
//             rs1_for = mem_wb_reg.rd_data;
//         end 
//         else if ((prev_wb_rd_addr == id_ex_reg.rs1_addr) && prev_wb_rd_addr != 0) begin 
//             rs1_for = prev_wb_rd_data;
//         end
        
//         if (ex_mem_reg.valid && ex_mem_reg.regf_we && (ex_mem_reg.rd != 0) && 
//            (ex_mem_reg.rd == id_ex_reg.rs2_addr) && !ex_mem_reg.load) begin
//             rs2_for = ex_mem_reg.aluout;
//         end
//         else if (mem_wb_reg.valid && mem_wb_reg.regf_we && (mem_wb_reg.rd != 0) && 
//                 (mem_wb_reg.rd == id_ex_reg.rs2_addr)) begin
//             rs2_for = mem_wb_reg.rd_data;
//         end 
//         else if ((prev_wb_rd_addr == id_ex_reg.rs2_addr) && prev_wb_rd_addr != 0) begin
//             rs2_for = prev_wb_rd_data;
//         end
//     end

//     always_comb begin
//         a = '0;
//         b = '0;

//         if (id_ex_reg.valid && !rst) begin
//             unique case (id_ex_reg.alu_m1_sel)
//                 rs1_out: a = rs1_for; 
//                 pc_out:	 a = id_ex_reg.pc;
//                 no_out:  a = '0;
//                 default: a = '0;
//             endcase

//             unique case (id_ex_reg.alu_m2_sel)
//                 rs2_out: b = rs2_for;
//                 imm_out: b = id_ex_reg.imm;
//                 four_out: b = 32'h4;
//                 default: b = '0;
//             endcase
//         end
//     end

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

//     always_comb begin
//         br_en = 1'b0;
//         pc_branch = '0;

//         unique case (id_ex_reg.pc_sel) 
//             pc_norm: begin
//                 br_en = 1'b0;
//                 pc_branch = '0;
//             end
//             imm_off_uncon: begin
//                 br_en = 1'b1;
//                 pc_branch = id_ex_reg.imm + id_ex_reg.pc;
//             end
//             rs1_off: begin
//                 br_en = 1'b1;
//                 pc_branch = (rs1_for + id_ex_reg.imm)  & 32'hfffffffe;
//             end
//             imm_off: begin
//                 unique case (id_ex_reg.cmpop)
//                     branch_f3_beq : br_en = (rs1_for == rs2_for);
//                     branch_f3_bne : br_en = (rs1_for != rs2_for);
//                     branch_f3_blt : br_en = unsigned'(signed'(rs1_for) <  signed'(rs2_for));
//                     branch_f3_bge : br_en = unsigned'(signed'(rs1_for) >= signed'(rs2_for));
//                     branch_f3_bltu: br_en = (rs1_for <  rs2_for);
//                     branch_f3_bgeu: br_en = (rs1_for >= rs2_for);
//                     default       : br_en = 1'b0;
//                 endcase
//                 if (br_en) begin
//                     pc_branch = id_ex_reg.imm + id_ex_reg.pc;
//                 end
//             end
//         endcase
//     end


//     always_comb begin
//         ex_mem_reg_next = '0;
// 	    ex_mem_reg_next.valid = 1'b0;
        
//         if (id_ex_reg.valid && !rst && (!stall)) begin

//             ex_mem_reg_next.inst = id_ex_reg.inst;
//             ex_mem_reg_next.pc = id_ex_reg.pc;
//             ex_mem_reg_next.pc_next = id_ex_reg.pc_next;
//             if (br_en) begin
//                 ex_mem_reg_next.pc_next = pc_branch;
//             end
//             ex_mem_reg_next.order = id_ex_reg.order;
//             if (!load_use_hazard) begin
//                 ex_mem_reg_next.valid = id_ex_reg.valid;
//             end

//             ex_mem_reg_next.rd = id_ex_reg.rd;
//             ex_mem_reg_next.rs1_addr = id_ex_reg.rs1_addr;
//             ex_mem_reg_next.rs2_addr = id_ex_reg.rs2_addr;

//             ex_mem_reg_next.rs1_data = rs1_for;
//             ex_mem_reg_next.rs2_data = rs2_for;

//             ex_mem_reg_next.mem_addr = rs1_for + id_ex_reg.imm;

//             ex_mem_reg_next.memop = id_ex_reg.memop;
//             ex_mem_reg_next.regf_we = id_ex_reg.regf_we;
//             ex_mem_reg_next.aluout = aluout;
//             ex_mem_reg_next.mem_rmask = id_ex_reg.mem_rmask << ex_mem_reg_next.mem_addr[1:0];
//             ex_mem_reg_next.mem_wmask = id_ex_reg.mem_wmask << ex_mem_reg_next.mem_addr[1:0];
//             ex_mem_reg_next.load = id_ex_reg.load;
//         end
//     end


// endmodule
