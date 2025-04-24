module alu_unit 
import rv32i_types::*;
(
    input  logic            clk,
    input  logic            rst,
    input  reservation_station_t next_execute,
    // output logic            ready,
    output to_writeback_t   execute_output
);

    logic [31:0] aluout;
    logic [31:0] a, b;
    logic [31:0] rs1_for, rs2_for;

    always_comb begin           
        rs1_for = next_execute.rs1_data;   
        rs2_for = next_execute.rs2_data;
        
        // This is for data hazards. Handles forwarding for the pipeline processor

        // if (ex_mem_reg.valid && ex_mem_reg.regf_we && (ex_mem_reg.rd != 0) && 
        //    (ex_mem_reg.rd == id_ex_reg.rs1_addr) && !ex_mem_reg.load) begin
        //     rs1_for = ex_mem_reg.aluout;
        // end
        // else if (mem_wb_reg.valid && mem_wb_reg.regf_we && (mem_wb_reg.rd != 0) && 
        //         (mem_wb_reg.rd == id_ex_reg.rs1_addr)) begin
        //     rs1_for = mem_wb_reg.rd_data;
        // end 
        // else if ((prev_wb_rd_addr == id_ex_reg.rs1_addr) && prev_wb_rd_addr != 0) begin 
        //     rs1_for = prev_wb_rd_data;
        // end
        
        // if (ex_mem_reg.valid && ex_mem_reg.regf_we && (ex_mem_reg.rd != 0) && 
        //    (ex_mem_reg.rd == id_ex_reg.rs2_addr) && !ex_mem_reg.load) begin
        //     rs2_for = ex_mem_reg.aluout;
        // end
        // else if (mem_wb_reg.valid && mem_wb_reg.regf_we && (mem_wb_reg.rd != 0) && 
        //         (mem_wb_reg.rd == id_ex_reg.rs2_addr)) begin
        //     rs2_for = mem_wb_reg.rd_data;
        // end 
        // else if ((prev_wb_rd_addr == id_ex_reg.rs2_addr) && prev_wb_rd_addr != 0) begin
        //     rs2_for = prev_wb_rd_data;
        // end
    end

    always_comb begin
        a = '0;
        b = '0;

        if (next_execute.valid) begin
            unique case (next_execute.alu_m1_sel)
                rs1_out: a = rs1_for; 
                pc_out:	 a = next_execute.pc;
                no_out:  a = '0;
                default: a = '0;
            endcase

            unique case (next_execute.alu_m2_sel)
                rs2_out: b = rs2_for;
                imm_out: b = next_execute.imm_sext;
                four_out: b = 32'h4;
                default: b = '0;
            endcase
        end
    end

    always_comb begin
        aluout = '0;

        if (next_execute.valid) begin
            unique case (next_execute.aluop)
                alu_op_add: aluout = a +   b;
                alu_op_sll: aluout = a <<  b[4:0];
                alu_op_sra: aluout = unsigned'(signed'(a) >>> (b[4:0]));
                alu_op_sub: aluout = a -   b;
                alu_op_xor: aluout = a ^   b;
                alu_op_srl: aluout = a >>  b[4:0];
                alu_op_or : aluout = a |   b;
                alu_op_and: aluout = a &   b;
		        alu_op_slt: aluout = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
                alu_op_sltu: aluout = (a < b) ? 32'b1 : 32'b0;
                default   : aluout = '0;
            endcase
        end
    end


    
    always_comb begin
        execute_output = '0;
	    execute_output.valid = 1'b0;
        
        if (next_execute.valid) begin
            execute_output.valid = next_execute.valid;
            execute_output.pc = next_execute.pc;
            execute_output.inst = next_execute.inst;
            // ex_mem_reg_next.order = id_ex_reg.order;
            // if (!load_use_hazard) begin
            //     ex_mem_reg_next.valid = id_ex_reg.valid;
            // end

            execute_output.rd_addr = next_execute.rd_addr;
            execute_output.rs1_addr = next_execute.rs1_addr;
            execute_output.rs2_addr = next_execute.rs2_addr;
            // execute_output.rd_paddr = next_execute.rd_paddr;
            // execute_output.rs1_paddr = next_execute.rs1_paddr;
            // execute_output.rs2_paddr = next_execute.rs2_paddr;

            execute_output.rd_rob_idx = next_execute.rd_rob_idx;
            execute_output.rd_data = aluout;
            execute_output.regf_we = next_execute.regf_we;
        end
    end

    // always_ff @(posedge clk) begin
    //     ready = 1'b1;
    //     /*if (rst)
    //         ready = 1'b1;
    //     else */if (execute_output.valid) begin
    //         ready = 1'b0;
    //         if (aluout != '0)
    //             ready = 1'b1;

    //     end
    // end

endmodule