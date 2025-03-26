// module writeback_stage 
// import rv32i_types::*;
// (
//     //input  logic        clk,
//     input  logic        rst,
//     input  mem_wb_stage_reg_t mem_wb_reg,
//     output logic [4:0]      rd,
//     output logic [31:0]     rd_data,
//     output logic            regf_we
// );


//     always_comb begin
//         rd = '0;
//         rd_data = '0;
//         regf_we = 1'b0;

//         if (mem_wb_reg.valid && !rst) begin
//             rd = mem_wb_reg.rd;
//             rd_data = mem_wb_reg.rd_data;
//             regf_we = mem_wb_reg.regf_we;
//         end
//     end


// endmodule
