//code from synopsys docs
module DW02_mult_inst #(
    parameter A_width = 8,
    parameter B_width = 8
)( 
    input [A_width-1 : 0] inst_A, 
    input [B_width-1 : 0] inst_B, 
    input inst_TC,
    output [A_width+B_width-1 : 0] PRODUCT_inst
);

  // Instance of DW02_mult
  DW02_mult #(A_width, B_width)
    U1 ( .A(inst_A), .B(inst_B), .TC(inst_TC), .PRODUCT(PRODUCT_inst) );

endmodule

module DW_div_inst #(
    parameter width    = 8,
    parameter tc_mode  = 0,
    parameter rem_mode = 1
)(
    input  [width-1 : 0] a,
    input  [width-1 : 0] b,
    output [width-1 : 0] quotient,
    output [width-1 : 0] remainder,
    output               divide_by_0
);

  // instance of DW_div
  DW_div #(width, width, tc_mode, rem_mode)
    U1 (.a(a), .b(b),
        .quotient(quotient), .remainder(remainder),
        .divide_by_0(divide_by_0));
endmodule

module mul_unit 
import rv32i_types::*;
(
    input  logic            clk,
    input  logic            rst,
    input  reservation_station_t next_execute,
    output to_writeback_t   execute_output
);

    logic [31:0] a_mul, b_mul;
    logic [63:0] product_mul;
    logic [65:0] product_mul_su;

    logic [31:0] a_div_u, b_div_u, a_div_s, b_div_s;
    logic [31:0] quotient_u, quotient_s;
    logic [31:0] remainder_u, remainder_s;

    logic signed_mode, div_by_0_u, div_by_0_s;
    logic div_overflow_s;
    assign div_overflow_s = (a_div_s == 32'h80000000) && (b_div_s == 32'hFFFFFFFF);

    logic [31:0] prev_pc;

    DW02_mult_inst #(32, 32) multiply (
        .inst_A(a_mul), .inst_B(b_mul), .inst_TC(signed_mode), .PRODUCT_inst(product_mul)
    );
    DW02_mult_inst #(33, 33) multiply_su ( 
        .inst_A({a_mul[31], a_mul}), .inst_B({1'b0, b_mul}), .inst_TC(1'b1), .PRODUCT_inst(product_mul_su) 
    );
    DW_div_inst  #(32, 0, 1) divide_unsigned(
        .a(a_div_u), .b(b_div_u), 
        .quotient(quotient_u), .remainder(remainder_u), 
        .divide_by_0(div_by_0_u));
    DW_div_inst  #(32, 1, 1) divide_signed (
        .a(a_div_s), .b(b_div_s), 
        .quotient(quotient_s), .remainder(remainder_s), 
        .divide_by_0(div_by_0_s));

    logic [7:0] counter;
    
    mult_ops mult_op_running;
    always_ff @(posedge clk ) begin
        if (rst) begin
            counter <= 8'b0;
            execute_output <= '0;
            execute_output.valid <= 1'b0;
            mult_op_running <= mult_ops'(0);
            // debug
            prev_pc <= '0;
        end else begin
            prev_pc <= next_execute.pc;
            if (next_execute.valid && (counter < 10)) begin
                execute_output.valid <= 1'b0;                
                
                execute_output.pc <= next_execute.pc;
                execute_output.rd_addr <= next_execute.rd_addr;
                execute_output.rs1_addr <= next_execute.rs1_addr;
                execute_output.rs2_addr <= next_execute.rs2_addr;

                execute_output.rd_rob_idx <= next_execute.rd_rob_idx;
                execute_output.regf_we <= next_execute.regf_we;
                mult_op_running <= next_execute.multop;
                unique case (next_execute.multop)
                    mult_op_mul:   begin 
                        a_mul <= next_execute.rs1_data;   
                        b_mul <= next_execute.rs2_data;
                        signed_mode <= 1'b1;
                    end
                    mult_op_mulh:  begin
                        a_mul <= next_execute.rs1_data;   
                        b_mul <= next_execute.rs2_data;
                        signed_mode <= 1'b1;
                    end
                    mult_op_mulhsu: begin  // need to convert 
                        a_mul <= next_execute.rs1_data;   
                        b_mul <= next_execute.rs2_data;
                        // signed_mode <= 1'b1;
                    end
                    mult_op_mulhu:  begin
                        signed_mode <= 1'b0;  
                        a_mul <= next_execute.rs1_data;   
                        b_mul <= next_execute.rs2_data;
                        signed_mode <= 1'b0;
                    end

                    mult_op_div: begin
                        a_div_s <= next_execute.rs1_data;   
                        b_div_s <= next_execute.rs2_data;
                        signed_mode <= 1'b1;
                    end
                    mult_op_divu:  begin
                        a_div_u <= next_execute.rs1_data;   
                        b_div_u <= next_execute.rs2_data;
                        signed_mode <= 1'b0;
                    end
                    mult_op_rem: begin
                        a_div_s <= next_execute.rs1_data;   
                        b_div_s <= next_execute.rs2_data;
                        signed_mode <= 1'b1;
                    end
                    mult_op_remu: begin 
                        a_div_u <= next_execute.rs1_data;   
                        b_div_u <= next_execute.rs2_data;
                        signed_mode <= 1'b0;
                    end
                endcase
                counter <= counter + 1;
            end
            else if (counter == 8'd50) begin
                // use result
                unique case (mult_op_running)
                    mult_op_mul: execute_output.rd_data <= product_mul[31:0]; 
                    mult_op_mulh:  execute_output.rd_data <= product_mul[63:32]; 

                    mult_op_mulhsu:  execute_output.rd_data <= product_mul_su[63:32]; 
                    mult_op_mulhu: execute_output.rd_data <= product_mul[63:32]; 

                    mult_op_div: begin
                        if (b_div_s == '0)
                            execute_output.rd_data <= 32'hFFFFFFFF;
                        else if (div_overflow_s)
                            execute_output.rd_data <= 32'h80000000;
                        else execute_output.rd_data <= quotient_s;
                    end
                    mult_op_divu: begin 
                        if (b_div_u == '0)
                            execute_output.rd_data <= 32'hFFFFFFFF;
                        else execute_output.rd_data <= quotient_u;
                    end
                    mult_op_rem: begin 
                        if (b_div_s == '0)
                            execute_output.rd_data <= a_div_s;
                        else if (div_overflow_s)
                            execute_output.rd_data <= 32'h0;
                        else execute_output.rd_data <= remainder_s; 
                    end
                    mult_op_remu:  begin 
                        if (b_div_u == '0)
                            execute_output.rd_data <= a_div_u;
                        else execute_output.rd_data <= remainder_u; 
                    end
                    default:       signed_mode <= 1'b0; //
                endcase
                
                counter <= 8'd0;
                execute_output.valid <= 1'b1;    
            end
            else /* if (counter != 0) */ begin
                counter <= counter + 1;
            end
        end
    end

    // always_comb begin
        
    //     if (next_execute.valid) begin
    //         execute_output.valid = next_execute.valid;
    //         execute_output.pc = next_execute.pc;
    //         // if (br_en) begin
    //         //     ex_mem_reg_next.pc_next = pc_branch;
    //         // end
    //         // ex_mem_reg_next.order = id_ex_reg.order;
    //         // if (!load_use_hazard) begin
    //         //     ex_mem_reg_next.valid = id_ex_reg.valid;
    //         // end

    //         execute_output.rd_addr = next_execute.rd_addr;
    //         execute_output.rs1_addr = next_execute.rs1_addr;
    //         execute_output.rs2_addr = next_execute.rs2_addr;
    //         execute_output.rd_paddr = next_execute.rd_paddr;
    //         execute_output.rs1_paddr = next_execute.rs1_paddr;
    //         execute_output.rs2_paddr = next_execute.rs2_paddr;

    //         execute_output.rd_rob_idx = next_execute.rd_rob_idx;
    //         execute_output.rd_data = aluout;
    //         execute_output.regf_we = next_execute.regf_we;
    //     end
    // end



endmodule
