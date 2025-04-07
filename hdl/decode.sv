module decode
import rv32i_types::*;
(
    input  logic        clk,
    input  logic        rst,
    // input  logic [31:0] rs1_data,
    // input  logic [31:0] rs2_data,
//     input  logic        load_use_hazard,
//     input if_id_stage_reg_t  if_id_reg,
    output if_id_stage_reg_t    decode_struct_in, // Will only contain instr, pc, order & valid
    output id_dis_stage_reg_t    decode_struct_out,
);

    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] opcode;
    logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;
    logic [4:0] rs1_addr, rs2_addr, rd_addr

    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign opcode = inst[6:0];
    assign i_imm  = {{21{inst[31]}}, inst[30:20]};
    assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign u_imm  = {inst[31:12], 12'h000};
    assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
    assign rs1_addr = inst[19:15];
    assign rs2_addr = inst[24:20];
    assign rd_addr = inst[11:7];

    always_comb begin
        decode_struct_out = '0;

        if (!stall) begin
            decode_struct_out.valid = decode_struct_in.valid;
            decode_struct_out.inst = decode_struct_in.inst;
            decode_struct_out.pc = decode_struct_in.pc;
            decode_struct_out.order = decode_struct_in.order;
            decode_struct_out.opcode = opcode;
            decode_struct_out.funct3 = funct3;
            decode_struct_out.funct7 = funct7;
            decode_struct_out.rs1_addr = rs1_addr;
            decode_struct_out.rs2_addr = rs2_addr;
            decode_struct_out.rd_addr = rd_addr;
            
            unique case (opcode)
                // op_b_lui  : begin
                //     decode_struct_out.rd_addr = rd_addr;
                //     decode_struct_out.imm_sext = u_imm;
				// 	id_ex_reg_next.regf_we = 1'b1;          // Control Signals
				// 	id_ex_reg_next.alu_m1_sel = no_out;
				// 	id_ex_reg_next.alu_m2_sel = imm_out;
				// 	id_ex_reg_next.aluop = alu_op_add;
                // end
                // op_b_auipc: begin
                //     decode_struct_out.rd_addr = rd_addr;  
                //     decode_struct_out.imm_sext = u_imm;
                // end
                // op_b_jal  : begin
                //     decode_struct_out.rd_addr = rd_addr;  
                //     decode_struct_out.imm_sext = j_imm;
                // end
                // op_b_jalr : begin
                //     decode_struct_out.rd_addr = rd_addr;
                //     decode_struct_out.rs1_addr = rs1_addr;
                //     decode_struct_out.rs1_data = rs1_data;  
                //     decode_struct_out.imm_sext = i_imm;
                // end
                // op_b_br   : begin
                //     decode_struct_out.rs1_addr = rs1_addr;
                //     decode_struct_out.rs1_data = rs1_data;   
                //     decode_struct_out.rs2_addr = rs2_addr;
                //     decode_struct_out.rs2_data = rs2_data;    
                //     decode_struct_out.imm_sext = b_imm;
                // end
                // op_b_load : begin
                //     decode_struct_out.rs1_addr = rs1_addr;
                //     decode_struct_out.rs1_data = rs1_data;   
                //     decode_struct_out.imm_sext = i_imm;
                //     decode_struct_out.rd_addr = rd_addr;
                // end
                // op_b_store: begin
                //     decode_struct_out.rs1_addr = rs1_addr;
                //     decode_struct_out.rs1_data = rs1_data;  
                //     decode_struct_out.rs2_addr = rs2_addr;
                //     decode_struct_out.rs2_data = rs2_data;   
                //     decode_struct_out.imm_sext = s_imm;
                // end
                op_b_imm  : begin
                    // decode_struct_out.rs1_data = rs1_data;  
                    decode_struct_out.imm_sext = i_imm;
					id_ex_reg_next.regf_we = 1'b1;          // Control Signals
					id_ex_reg_next.alu_m1_sel = rs1_out;
					id_ex_reg_next.alu_m2_sel = imm_out;
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
                    // decode_struct_out.rs1_data = rs1_data;  
                    // decode_struct_out.rs2_data = rs2_data;  
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
                //default   : ;
            endcase
        end
    end

endmodule