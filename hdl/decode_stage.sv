module decode_stage 
import rv32i_types::*;
(
    //input  logic        clk,
    input  logic        rst,
    input  logic        stall,	
    input  logic        load_use_hazard,
    input if_id_stage_reg_t  if_id_reg,
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    output id_ex_stage_reg_t id_ex_reg_next
);

    logic [31:0] inst;
    assign inst = if_id_reg.inst;

    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] opcode;
    logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;


    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign opcode = inst[6:0];
    assign i_imm  = {{21{inst[31]}}, inst[30:20]};
    assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign u_imm  = {inst[31:12], 12'h000};
    assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};


    always_comb begin
		id_ex_reg_next = '0;
		id_ex_reg_next.valid = 1'b0;

		if (if_id_reg.valid && !rst && (!stall) && (!load_use_hazard)) begin
			id_ex_reg_next.rs1_addr = if_id_reg.inst[19:15];
			id_ex_reg_next.rs2_addr = if_id_reg.inst[24:20];

			id_ex_reg_next.inst = if_id_reg.inst;
			id_ex_reg_next.pc = if_id_reg.pc;
			id_ex_reg_next.pc_next = if_id_reg.pc_next;
			id_ex_reg_next.order = if_id_reg.order;
			id_ex_reg_next.valid = 1'b1;

			// instr data
			id_ex_reg_next.rd = if_id_reg.inst[11:7];
			id_ex_reg_next.rs1_data = rs1_data;
			id_ex_reg_next.rs2_data = rs2_data;
			id_ex_reg_next.load = 1'b0;

			unique case (opcode)
				op_b_lui  : begin
					id_ex_reg_next.imm = u_imm;
					id_ex_reg_next.regf_we = 1'b1;
					id_ex_reg_next.alu_m1_sel = no_out;
					id_ex_reg_next.alu_m2_sel = imm_out;
					id_ex_reg_next.aluop = alu_op_add;
					id_ex_reg_next.memop = mem_op_none;
					id_ex_reg_next.mem_addr = '0;
					id_ex_reg_next.mem_wmask = 4'b0000;
					id_ex_reg_next.mem_rmask = 4'b0000;
				end
				op_b_auipc: begin
					id_ex_reg_next.imm = u_imm;
					id_ex_reg_next.regf_we = 1'b1;
					id_ex_reg_next.alu_m1_sel = pc_out;
					id_ex_reg_next.alu_m2_sel = imm_out;
					id_ex_reg_next.aluop = alu_op_add;
					id_ex_reg_next.memop = mem_op_none;
					id_ex_reg_next.mem_addr = '0;
					id_ex_reg_next.mem_wmask = 4'b0000;
					id_ex_reg_next.mem_rmask = 4'b0000;
				end

				op_b_jal: begin
					id_ex_reg_next.imm = j_imm;
					id_ex_reg_next.regf_we = 1'b1;
					id_ex_reg_next.alu_m1_sel = pc_out;
					id_ex_reg_next.alu_m2_sel = four_out;
					id_ex_reg_next.pc_sel = imm_off_uncon;
					id_ex_reg_next.memop = mem_op_none;
					id_ex_reg_next.jump = 1'b1;
				end
				op_b_jalr: begin
					id_ex_reg_next.imm = i_imm;
					id_ex_reg_next.regf_we = 1'b1;
					id_ex_reg_next.alu_m1_sel = pc_out;
					id_ex_reg_next.alu_m2_sel = four_out;
					id_ex_reg_next.pc_sel = rs1_off;
					id_ex_reg_next.memop = mem_op_none;
					id_ex_reg_next.jump = 1'b1;
				end
				op_b_br: begin
					id_ex_reg_next.imm = b_imm;
					id_ex_reg_next.rd = '0;
					id_ex_reg_next.regf_we = 1'b0;
					id_ex_reg_next.alu_m1_sel = rs1_out;
					id_ex_reg_next.alu_m2_sel = rs2_out;
					id_ex_reg_next.pc_sel = imm_off;
					id_ex_reg_next.cmpop = branch_f3_t'(funct3);
					id_ex_reg_next.memop = mem_op_none;			
					id_ex_reg_next.jump = 1'b0;
				end

				op_b_imm  : begin
					id_ex_reg_next.imm = i_imm;
					id_ex_reg_next.regf_we = 1'b1;
					id_ex_reg_next.alu_m1_sel = rs1_out;
					id_ex_reg_next.alu_m2_sel = imm_out;
					id_ex_reg_next.memop = mem_op_none;
					id_ex_reg_next.mem_addr = '0;
					id_ex_reg_next.mem_wmask = 4'b0000;
					id_ex_reg_next.mem_rmask = 4'b0000;
					unique case (funct3)
						arith_f3_slt: id_ex_reg_next.aluop = alu_op_slt;
						arith_f3_sltu: id_ex_reg_next.aluop = alu_op_sltu;
						arith_f3_sr: begin
							unique case (funct7)
								base: id_ex_reg_next.aluop = alu_op_srl;
								variant: id_ex_reg_next.aluop = alu_op_sra;
								default: id_ex_reg_next.aluop = alu_op_srl;
							endcase
						end
						default: id_ex_reg_next.aluop = alu_ops'(funct3);
					endcase
				end
				op_b_reg  : begin
					id_ex_reg_next.imm = '0;
					id_ex_reg_next.regf_we = 1'b1;
					id_ex_reg_next.alu_m1_sel = rs1_out;
					id_ex_reg_next.alu_m2_sel = rs2_out;
					id_ex_reg_next.mem_wmask = 4'b0000;
					id_ex_reg_next.mem_rmask = 4'b0000;
					unique case (funct3)
						arith_f3_slt: id_ex_reg_next.aluop = alu_op_slt;
						arith_f3_sltu: id_ex_reg_next.aluop = alu_op_sltu;
						arith_f3_sr: begin
							unique case (funct7)
								base: id_ex_reg_next.aluop = alu_op_srl;
								variant: id_ex_reg_next.aluop = alu_op_sra;
								default: id_ex_reg_next.aluop = alu_op_none;
							endcase
						end
						arith_f3_add: begin
							unique case (funct7)
								base: id_ex_reg_next.aluop = alu_op_add;
								variant: id_ex_reg_next.aluop = alu_op_sub;
								default: id_ex_reg_next.aluop = alu_op_none;
							endcase
						end
						default: id_ex_reg_next.aluop = alu_ops'(funct3);
					endcase
				end
				op_b_load: begin
					id_ex_reg_next.imm = i_imm;
					id_ex_reg_next.alu_m1_sel = rs1_out;
					id_ex_reg_next.alu_m2_sel = imm_out;
					id_ex_reg_next.aluop = alu_op_add;
					id_ex_reg_next.regf_we = 1'b1;
					id_ex_reg_next.mem_wmask = 4'b0000;
					id_ex_reg_next.load = 1'b1;

					//id_ex_reg_next.mem_addr = rs1_data + i_imm;
					unique case (funct3)
						load_f3_lb: begin
							id_ex_reg_next.mem_rmask = 4'b0001; //<< id_ex_reg_next.mem_addr[1:0];
							id_ex_reg_next.memop = mem_op_b;
						end
						load_f3_lbu: begin
							id_ex_reg_next.mem_rmask = 4'b0001; //<< id_ex_reg_next.mem_addr[1:0];
							id_ex_reg_next.memop = mem_op_bu;
						end
						load_f3_lh: begin
							id_ex_reg_next.mem_rmask = 4'b0011; //<< id_ex_reg_next.mem_addr[1:0];
							id_ex_reg_next.memop = mem_op_h;
						end
						load_f3_lhu: begin
							id_ex_reg_next.mem_rmask = 4'b0011; //<< id_ex_reg_next.mem_addr[1:0];
							id_ex_reg_next.memop = mem_op_hu;
						end
						load_f3_lw:  begin
							id_ex_reg_next.mem_rmask = 4'b1111;
							id_ex_reg_next.memop = mem_op_w;
						end 
						default:  begin
						//id_ex_reg_next.mem_rmask = '0;
						id_ex_reg_next.memop = mem_op_none;
						end
					endcase
					//id_ex_reg_next.mem_addr[1:0] = 2'd0;
				end
				op_b_store: begin
					id_ex_reg_next.imm = s_imm;
					id_ex_reg_next.alu_m1_sel = rs1_out;
					id_ex_reg_next.alu_m2_sel = imm_out;
					id_ex_reg_next.aluop = alu_op_add;
					id_ex_reg_next.regf_we = 1'b0;
					id_ex_reg_next.mem_rmask = 4'b0000;
					

					//id_ex_reg_next.mem_addr = rs1_data + s_imm;
					unique case (funct3)
						store_f3_sb: begin
							id_ex_reg_next.mem_wmask = 4'b0001; //<< id_ex_reg_next.mem_addr[1:0];
							id_ex_reg_next.memop = mem_op_b;
						end
						store_f3_sh: begin
							id_ex_reg_next.mem_wmask = 4'b0011; //<< id_ex_reg_next.mem_addr[1:0];
							id_ex_reg_next.memop = mem_op_h;
						end
						store_f3_sw: begin
							id_ex_reg_next.mem_wmask = 4'b1111;
							id_ex_reg_next.memop = mem_op_w;
						end
						default:  begin
						//id_ex_reg_next.mem_wmask = '0;
						id_ex_reg_next.memop = mem_op_none;
						end
					endcase
					//id_ex_reg_next.mem_addr[1:0] = 2'd0;
				end
				default   : begin
					id_ex_reg_next.imm = '0;
					id_ex_reg_next.regf_we = 1'b0;
					id_ex_reg_next.alu_m1_sel = rs1_out;
					id_ex_reg_next.alu_m2_sel = rs2_out;
					id_ex_reg_next.aluop = alu_op_add;
					id_ex_reg_next.memop = mem_op_none;
					id_ex_reg_next.rs1_addr = '0;
					id_ex_reg_next.rs2_addr = '0;
					id_ex_reg_next.mem_addr = '0;
					id_ex_reg_next.mem_wmask = '0;
					id_ex_reg_next.mem_rmask = '0;
				end
			endcase
		end
    end


endmodule
