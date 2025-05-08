//code from synopsys docs
module DW_mult_inst #(
    parameter A_width = 8,
    parameter B_width = 8,
    parameter tc_mode = 1
)( 
    input  logic clk,
    input  logic rst,
    input  logic [A_width-1 : 0] inst_A, 
    input  logic [B_width-1 : 0] inst_B, 
    output logic [A_width+B_width-1 : 0] PRODUCT_inst,
    input  logic start,
    output logic complete
);

    DW_mult_seq #(
        .a_width(A_width), 
        .b_width(B_width),
        .tc_mode(tc_mode),
        .early_start(1)
    ) mult_seq_isnt (
        .clk(clk),
        .rst_n(~rst),
        .hold(1'b0),
        .start(start),
        .a(inst_A),
        .b(inst_B),
        .complete(complete),
        .product(PRODUCT_inst)
    );

endmodule

module DW_div_inst #(
    parameter width    = 8,
    parameter tc_mode  = 0
)(
    input  logic clk,
    input  logic rst,
    input  logic [width-1 : 0] inst_A,
    input  logic [width-1 : 0] inst_B,
    output logic [width-1 : 0] quotient,
    output logic [width-1 : 0] remainder,
    output logic divide_by_0,
    input  logic start,
    output logic complete
);

    DW_div_seq #(
        .a_width(width), 
        .b_width(width),
        .tc_mode(tc_mode),
        .early_start(1)
    ) div_seq_isnt (
        .clk(clk),
        .rst_n(~rst),
        .hold(1'b0),
        .start(start),
        .a(inst_A),
        .b(inst_B),
        .complete(complete),
        .divide_by_0(divide_by_0),
        .quotient(quotient),
        .remainder(remainder)
    );
    
endmodule

module mul_unit 
import rv32i_types::*;
(
    input  logic            clk,
    input  logic            rst,
    input  reservation_station_t next_execute,
    output to_writeback_t   execute_output
);

    logic start [5];
    logic done  [5];

    logic [31:0] a_mul, b_mul;
    logic [63:0] product_mul_u, product_mul_s;
    logic [65:0] product_mul_su;

    logic [31:0] a_div_u, b_div_u, a_div_s, b_div_s;
    logic [31:0] quotient_u, quotient_s;
    logic [31:0] remainder_u, remainder_s;
    logic        div_by_0_u, div_by_0_s;

    logic div_overflow_s;
    
    logic new_inst;
    mult_ops mult_op_running;
    logic [31:0] prev_pc;
    logic [2:0]  module_idx;
    logic [4:0]  prev_rd_rob_idx;
    assign div_overflow_s = (a_div_s == 32'h80000000) && (b_div_s == 32'hFFFFFFFF);
    assign new_inst = next_execute.valid && (prev_pc != next_execute.pc || prev_rd_rob_idx != next_execute.rd_rob_idx);

    DW_mult_inst #(32, 32, 1) multiply_signed (
        .clk(clk), .rst(rst),
        .start(start[0]), .complete(done[0]),
        .inst_A(a_mul), .inst_B(b_mul), 
        .PRODUCT_inst(product_mul_s)
    );
    DW_mult_inst #(32, 32, 0) multiply_unsigned (
        .clk(clk), .rst(rst),
        .start(start[1]), .complete(done[1]),
        .inst_A(a_mul), .inst_B(b_mul), 
        .PRODUCT_inst(product_mul_u)
    );  
    DW_mult_inst #(33, 33, 1) multiply_su ( 
        .clk(clk), .rst(rst), 
        .start(start[2]), .complete(done[2]),
        .inst_A({a_mul[31], a_mul}), .inst_B({1'b0, b_mul}), 
        .PRODUCT_inst(product_mul_su)
    );
    DW_div_inst  #(32, 1) divide_signed (
        .clk(clk), .rst(rst),
        .start(start[3]), .complete(done[3]),
        .inst_A(a_div_s), .inst_B(b_div_s), 
        .quotient(quotient_s), .remainder(remainder_s), 
        .divide_by_0(div_by_0_s)
    );
    DW_div_inst  #(32, 0) divide_unsigned(
        .clk(clk), .rst(rst),
        .start(start[4]), .complete(done[4]),
        .inst_A(a_div_u), .inst_B(b_div_u), 
        .quotient(quotient_u), .remainder(remainder_u), 
        .divide_by_0(div_by_0_u)
    );

    always_comb begin : module_select
        unique case (next_execute.multop)
            mult_op_mul, mult_op_mulh: module_idx = 3'd0;

            mult_op_mulhu: module_idx = 3'd1;
            
            mult_op_mulhsu: module_idx = 3'd2;
            
            mult_op_div, mult_op_rem: module_idx = 3'd3;

            mult_op_divu, mult_op_remu: module_idx = 3'd4;
        endcase
    end

    always_ff @(posedge clk ) begin
        if (rst) begin
            execute_output <= '0;
            mult_op_running <= mult_ops'(0);
            prev_pc <= 32'd0;
            start <= '{default: 1'b0};
        end else begin
            prev_pc <= next_execute.pc;
            prev_rd_rob_idx <= next_execute.rd_rob_idx;
            unique case (next_execute.status)
                BUSY: begin
                    if (new_inst) begin
                        execute_output.valid <= 1'b0;            
                        execute_output.pc <= next_execute.pc;
                        execute_output.inst <= next_execute.inst;
                        execute_output.rd_addr <= next_execute.rd_addr;
                        execute_output.rs1_addr <= next_execute.rs1_addr;
                        execute_output.rs2_addr <= next_execute.rs2_addr;
                        execute_output.regf_we <= next_execute.regf_we;
                        execute_output.rd_rob_idx <= next_execute.rd_rob_idx;
                        execute_output.rd_data <= '0; 

                        mult_op_running <= next_execute.multop;
                        start[module_idx] <= 1'b1;

                        unique case (next_execute.multop)
                            mult_op_mul, mult_op_mulh, mult_op_mulhsu, mult_op_mulhu:   begin 
                                a_mul <= next_execute.rs1_data;   
                                b_mul <= next_execute.rs2_data;
                            end
                            mult_op_div, mult_op_rem: begin
                                a_div_s <= next_execute.rs1_data;   
                                b_div_s <= next_execute.rs2_data;
                            end
                            mult_op_divu, mult_op_remu:  begin
                                a_div_u <= next_execute.rs1_data;   
                                b_div_u <= next_execute.rs2_data;
                            end
                        endcase
                    end
                    else if (start[module_idx] == 1'b1) begin
                        start[module_idx] <= 1'b0;
                    end
                    else if (done[module_idx]) begin
                        unique case (mult_op_running)
                            mult_op_mul:    execute_output.rd_data <= product_mul_s [31:0]; 
                            mult_op_mulh:   execute_output.rd_data <= product_mul_s [63:32]; 
                            mult_op_mulhsu: execute_output.rd_data <= product_mul_su[63:32]; 
                            mult_op_mulhu:  execute_output.rd_data <= product_mul_u [63:32]; 

                            mult_op_div: begin
                                if (div_by_0_s)
                                    execute_output.rd_data <= 32'hFFFFFFFF;
                                else if (div_overflow_s)
                                    execute_output.rd_data <= 32'h80000000;
                                else execute_output.rd_data <= quotient_s;
                            end
                            mult_op_divu: begin 
                                if (div_by_0_u)
                                    execute_output.rd_data <= 32'hFFFFFFFF;
                                else execute_output.rd_data <= quotient_u;
                            end
                            mult_op_rem: begin 
                                if (div_by_0_s)
                                    execute_output.rd_data <= a_div_s;
                                else if (div_overflow_s)
                                    execute_output.rd_data <= 32'h0;
                                else execute_output.rd_data <= remainder_s; 
                            end
                            mult_op_remu:  begin 
                                if (div_by_0_u)
                                    execute_output.rd_data <= a_div_u;
                                else execute_output.rd_data <= remainder_u; 
                            end
                        endcase
                        execute_output.valid <= 1'b1; 
                    end
                end 
                IDLE: begin
                    execute_output.valid <= 1'b0;                  
                end
                COMPLETE: begin
                    execute_output.valid <= 1'b0;                  
                end
                default: ;
            endcase
        end 
    end



endmodule