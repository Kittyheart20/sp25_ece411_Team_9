// module dispatch 
// import rv32i_types::*;
// (
//     input  logic        clk,
//     input  logic        rst,
//     input  id_dis_stage_reg_t dispatch_struct_in,
//     input logic [31:0]  rs1_data,
//     input logic [31:0]  rs2_data,
//     input logic         rs1_ready,
//     input logic         rs2_ready,
//     input logic integer_alu_available,
//     output logic station_assignment
// );


//     always_comb begin
//         if ( ((dispatch_struct_in.aluop == alu_op_add) || (dispatch_struct_in.aluop == alu_op_sub)) && integer_alu_available) begin
//             rs1_data_in = rs1_data;
//             rs2_data_in = rs2_data;
//         end 
    
//     end

// endmodule