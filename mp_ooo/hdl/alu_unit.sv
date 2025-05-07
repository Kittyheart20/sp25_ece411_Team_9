module alu_unit 
import rv32i_types::*;
(
    // input  logic            rst,
    input  reservation_station_t next_execute,
    output to_writeback_t   execute_output
);

    logic [31:0] aluout;
    logic [31:0] a, b;
    logic [31:0] rs1_for, rs2_for;

    always_comb begin           
        rs1_for = next_execute.rs1_data;   
        rs2_for = next_execute.rs2_data;
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
        
        if (next_execute.valid) begin
            execute_output.valid = next_execute.valid;
            execute_output.pc = next_execute.pc;
            execute_output.inst = next_execute.inst;

            execute_output.rd_addr = next_execute.rd_addr;
            execute_output.rs1_addr = next_execute.rs1_addr;
            execute_output.rs2_addr = next_execute.rs2_addr;

            execute_output.rd_rob_idx = next_execute.rd_rob_idx;
            execute_output.rd_data = aluout;
            execute_output.regf_we = next_execute.regf_we;
        end else begin
            execute_output = '0;
	        execute_output.valid = 1'b0;
        end
    end

endmodule