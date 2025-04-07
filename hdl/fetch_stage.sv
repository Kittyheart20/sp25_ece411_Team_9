// module fetch_stage 
// //import rv32i_types::*;
// (
//     //input  logic        clk,
//     input  logic        rst,
//     input  logic        stall,
//     input  logic        load_use_hazard,
//     input  logic [31:0] pc,
//     input  logic [31:0] pc_branch,
//     input  logic        branch,
//     input  logic [63:0] order,
//     input  logic        instruction_valid,
//     //input  logic [3:0]  imem_rmask,
//     input  logic [31:0] imem_rdata,
//     //input  logic        imem_resp,
//     output logic [31:0] pc_next,
//     output logic [31:0] if_id_reg_next
// );

//     logic enable;
    
    

//     always_comb begin
// 	// if_id_reg_next = '0; 
// 	// pc_next = pc;
//     // enable = (instruction_valid) && (!rst) && (!stall) && (!load_use_hazard);

//     //     if (enable) begin
//     //         if_id_reg_next.inst = imem_rdata;
//     //         if_id_reg_next.pc = pc;
// 	//         if_id_reg_next.order = order;
//     //         if_id_reg_next.valid = 1'b1;
//     //         pc_next = pc + 4;
//     //         if (branch) begin
// 	//             pc_next = pc_branch;
//     //         end
//     //         if_id_reg_next.pc_next = pc_next;
//     //     end
//     end


// endmodule
