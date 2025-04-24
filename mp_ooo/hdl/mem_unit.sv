// module mem_unit
//     import rv32i_types::*;
//     (
//         input  logic            clk,
//         input  logic            rst,
//         output logic            mem_stall,
//         input  logic [31:0]     dmem_rdata,
//         output logic [31:0]     dmem_wdata,
//         input  logic            dmem_resp,
//         input  reservation_station_t next_execute,
//         output to_writeback_t   execute_output
//     );


        // logic [31:0] rd_v;
    
        // logic [1:0]  byte_offset;
        // assign byte_offset = ex_mem_reg.mem_addr[1:0];
        // logic mem_op_in_progress;
    
        // assign stall = (ex_mem_reg.valid && (ex_mem_reg.load || |ex_mem_reg.mem_wmask) && !dmem_resp) || 
        //            (mem_op_in_progress && !dmem_resp);
    
        // always_ff @(posedge clk) begin
        //     if (rst) begin
        //         mem_op_in_progress <= 1'b0;
        //     end 
        //     else begin
        //         if (ex_mem_reg.valid && (ex_mem_reg.load || |ex_mem_reg.mem_wmask) && !dmem_resp) begin
        //             // Start tracking a new memory operation
        //             mem_op_in_progress <= 1'b1;
        //         end else if (dmem_resp) begin
        //             // Memory response received, operation complete
        //             mem_op_in_progress <= 1'b0;
        //         end
        //     end
        // end

// endmodule