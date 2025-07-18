module decode
import rv32i_types::*;
(
    input if_id_stage_reg_t     decode_struct_in, // Will only contain instr, pc, order & valid
    output id_dis_stage_reg_t   decode_struct_out
);

    logic [31:0] inst;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [6:0] opcode;
    logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;
    logic [4:0] rs1_addr, rs2_addr, rd_addr;

    assign inst = decode_struct_in.inst;
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

        decode_struct_out.inst = decode_struct_in.inst;
        decode_struct_out.pc = decode_struct_in.pc;
        decode_struct_out.order = decode_struct_in.order;
        decode_struct_out.valid = decode_struct_in.valid;
        decode_struct_out.opcode = opcode;
        decode_struct_out.funct3 = funct3;
        decode_struct_out.funct7 = funct7;
        decode_struct_out.rd_addr = rd_addr;
        decode_struct_out.aluop = alu_ops'('x);
        decode_struct_out.multop = mult_ops'('x);
        decode_struct_out.brop = branch_f3_t'('x);
        decode_struct_out.memop = mem_ops'('x);
        decode_struct_out.prediction = decode_struct_in.prediction;
        
        unique case (opcode)
            op_b_lui  : begin
                decode_struct_out.op_type = alu;
                decode_struct_out.imm = u_imm;
                decode_struct_out.regf_we = 1'b1;
                decode_struct_out.alu_m1_sel = no_out;
                decode_struct_out.alu_m2_sel = imm_out;
                decode_struct_out.aluop = alu_op_add;
            end
            op_b_imm  : begin            
                decode_struct_out.op_type = alu;
                decode_struct_out.rs1_addr = rs1_addr;
                decode_struct_out.imm = i_imm;
                decode_struct_out.regf_we = 1'b1;
                decode_struct_out.alu_m1_sel = rs1_out;
                decode_struct_out.alu_m2_sel = imm_out;
                decode_struct_out.use_rs1 = 1'b1;
                decode_struct_out.use_rs2 = 1'b0;
                unique case (funct3)
                    arith_f3_slt: decode_struct_out.aluop = alu_op_slt;
                    arith_f3_sltu: decode_struct_out.aluop = alu_op_sltu;
                    arith_f3_sr: begin
                        unique case (funct7)
                            base: decode_struct_out.aluop = alu_op_srl;
                            variant: decode_struct_out.aluop = alu_op_sra;
                            default: decode_struct_out.aluop = alu_op_srl;
                        endcase
                    end
                    default: decode_struct_out.aluop = alu_ops'(funct3);
                endcase
            end
            op_b_reg  : begin
                decode_struct_out.regf_we = 1'b1;
                decode_struct_out.alu_m1_sel = rs1_out;
                decode_struct_out.alu_m2_sel = rs2_out;
                decode_struct_out.rs1_addr = rs1_addr;
                decode_struct_out.rs2_addr = rs2_addr;
                decode_struct_out.use_rs1 = 1'b1;
                decode_struct_out.use_rs2 = 1'b1;

                if (funct7 == mult) begin   // multiply extension
                    decode_struct_out.multop = mult_ops'(funct3);
                    decode_struct_out.op_type = mul; 
                end 
                else begin                  // integer alu
                    decode_struct_out.op_type = alu;
                    unique case (funct3)
                        arith_f3_slt: decode_struct_out.aluop = alu_op_slt;
                        arith_f3_sltu: decode_struct_out.aluop = alu_op_sltu;
                        arith_f3_sr: begin
                            unique case (funct7)
                                base: decode_struct_out.aluop = alu_op_srl;
                                variant: decode_struct_out.aluop = alu_op_sra;
                                default: decode_struct_out.aluop = alu_op_none;
                            endcase
                        end
                        arith_f3_add: begin
                            unique case (funct7)
                                base: decode_struct_out.aluop = alu_op_add;
                                variant: decode_struct_out.aluop = alu_op_sub;
                                default: decode_struct_out.aluop = alu_op_none;
                            endcase
                        end
                        default: decode_struct_out.aluop = alu_ops'(funct3);
                    endcase
                end


            end
            op_b_auipc: begin
                decode_struct_out.imm = u_imm;
			    decode_struct_out.regf_we = 1'b1;
                decode_struct_out.rd_addr = rd_addr;
                decode_struct_out.alu_m1_sel = pc_out;
                decode_struct_out.alu_m2_sel = imm_out;
                decode_struct_out.op_type = alu;    
                decode_struct_out.aluop = alu_op_add;
 
            end
            op_b_jal  : begin
                decode_struct_out.imm = j_imm;
			    decode_struct_out.regf_we = 1'b1;
                decode_struct_out.rd_addr = rd_addr;
                decode_struct_out.op_type = br;
            end
            op_b_jalr : begin
                decode_struct_out.imm = i_imm;
			    decode_struct_out.regf_we = 1'b1;
                decode_struct_out.rs1_addr = rs1_addr;
                decode_struct_out.use_rs1 = 1'b1;
                decode_struct_out.op_type = br;
            end
            op_b_br   : begin
                decode_struct_out.imm = b_imm;
                decode_struct_out.rs1_addr = rs1_addr; 
                decode_struct_out.rs2_addr = rs2_addr;
                decode_struct_out.rd_addr = '0;

			    decode_struct_out.brop = branch_f3_t'(funct3);   
                decode_struct_out.op_type = br;
                decode_struct_out.use_rs1 = 1'b1;
                decode_struct_out.use_rs2 = 1'b1;
            end
            op_b_load : begin
                decode_struct_out.rs1_addr = rs1_addr; 
                decode_struct_out.use_rs1 = 1'b1;
                decode_struct_out.imm = i_imm;
                decode_struct_out.regf_we = 1'b1;        // We can also use this to differentiate loads from stores in the mem unit
                decode_struct_out.op_type = mem;

                unique case (funct3)
                    load_f3_lb: begin
                        decode_struct_out.mem_rmask = 4'b0001;
                        decode_struct_out.memop = mem_op_b;
                    end
                    load_f3_lbu: begin
                        decode_struct_out.mem_rmask = 4'b0001;
                        decode_struct_out.memop = mem_op_bu;
                    end
                    load_f3_lh: begin
                        decode_struct_out.mem_rmask = 4'b0011;
                        decode_struct_out.memop = mem_op_h;
                    end
                    load_f3_lhu: begin
                        decode_struct_out.mem_rmask = 4'b0011;
                        decode_struct_out.memop = mem_op_hu;
                    end
                    load_f3_lw:  begin
                        decode_struct_out.mem_rmask = 4'b1111;
                        decode_struct_out.memop = mem_op_w;
                    end 
                    default:  begin
                        decode_struct_out.memop = mem_op_none;
                    end
                endcase

            end
            op_b_store: begin 
                decode_struct_out.rs1_addr = rs1_addr; 
                decode_struct_out.rs2_addr = rs2_addr;
                decode_struct_out.use_rs1 = 1'b1;
                decode_struct_out.use_rs2 = 1'b1;
                decode_struct_out.imm = s_imm;
                decode_struct_out.rd_addr = 5'd0;
                decode_struct_out.op_type = mem;

                unique case (funct3)
                    store_f3_sb: begin
                        decode_struct_out.mem_wmask = 4'b0001;
                        decode_struct_out.memop = mem_op_b;
                    end
                    store_f3_sh: begin
                        decode_struct_out.mem_wmask = 4'b0011;
                        decode_struct_out.memop = mem_op_h;
                    end
                    store_f3_sw: begin
                        decode_struct_out.mem_wmask = 4'b1111;
                        decode_struct_out.memop = mem_op_w;
                    end
                    default:  begin
                        decode_struct_out.memop = mem_op_none;
                    end
                endcase
            end
            default   : ;
        endcase
    end

endmodule