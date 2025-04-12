// module cpu
// import rv32i_types::*;
// (
//     input   logic               clk,
//     input   logic               rst,

//     output  logic   [31:0]      bmem_addr,
//     output  logic               bmem_read,
//     output  logic               bmem_write,
//     output  logic   [63:0]      bmem_wdata,
//     input   logic               bmem_ready,

//     input   logic   [31:0]      bmem_raddr,
//     input   logic   [63:0]      bmem_rdata,
//     input   logic               bmem_rvalid
// );

//     logic welp;
//     assign welp =  (bmem_raddr == 32'd0); // prevents lint warning on unused variable bmem_raddr

//     logic [31:0] pc, pc_next;
//     logic [63:0] order;
//     logic        commit;
//     logic        stall;

//     logic   [31:0]  data    [32];
//     logic           ready   [32];
//     logic   [4:0]   rob_idx [32];

//     // Stage Registers
//     if_id_stage_reg_t  decode_struct_in;
//     id_dis_stage_reg_t decode_struct_out;
//     id_dis_stage_reg_t dispatch_struct_in;
//     reservation_station_t dispatch_struct_out [2]; 
//     reservation_station_t next_execute [2];
//     to_writeback_t   execute_output;
//     to_writeback_t   next_writeback; 
//     to_commit_t      next_commit;

//     logic [31:0] rs1_data, rs2_data;
//     logic current_rd_rob_idx;

//     assign pc_next = pc + 32'd4;

//     // Cache
//     logic   [31:0]  ufp_addr;
//     logic   [3:0]   ufp_rmask;
//     logic   [3:0]   ufp_wmask;
//     logic   [31:0]  ufp_rdata;
//     logic   [255:0] ufp_rcache_line;
//     logic   [31:0]  ufp_wdata;
//     logic           ufp_resp;

//     logic   [31:0]  dfp_addr;
//     logic           dfp_read;
//     logic           dfp_write;
//     logic   [255:0] dfp_rdata;
//     logic   [255:0] dfp_wdata;
//     logic           dfp_resp;
//     logic           reached_loop; // debug value

//     assign ufp_wmask = '0;
//     assign ufp_wdata = '0;

//     deserializer cache_line_adapter (
//         .clk        (clk),
//         .rst        (rst),
//         .bmem_ready (bmem_ready),
//       //  .bmem_raddr (bmem_raddr),
//         .bmem_rdata (bmem_rdata),
//         .bmem_rvalid(bmem_rvalid),
//         .dfp_wdata  (dfp_wdata),
//         .dfp_write  (dfp_write),
//         .dfp_rdata  (dfp_rdata),
//         .dfp_resp   (dfp_resp),
//         .bmem_wdata (bmem_wdata)
//     );

//     cache instruction_cache (
//         .clk        (clk),
//         .rst        (rst),
        
//         .ufp_addr   (ufp_addr),
//         .ufp_rmask  (ufp_rmask),
//         .ufp_wmask  (ufp_wmask),
//         .ufp_rdata  (ufp_rdata),
//         .ufp_rcache_line (ufp_rcache_line),
//         .ufp_wdata  (ufp_wdata),
//         .ufp_resp   (ufp_resp),

//         .dfp_addr   (dfp_addr),
//         .dfp_read   (dfp_read),
//         .dfp_write  (dfp_write),
//         .dfp_rdata  (dfp_rdata),
//         .dfp_wdata  (dfp_wdata),
//         .dfp_resp   (dfp_resp)
//     );

//     // Instruction Queue
//     localparam WIDTH = 128;  // order + inst addr + data    
//     localparam DEPTH = 32;
//     localparam ALEN = 256;
//     localparam BLEN = 32;

//     logic full_o, empty_o;
//     logic enqueue_i, dequeue_i;
//     logic [WIDTH-1:0] data_i, data_o;

//     queue #(
//         .WIDTH      (WIDTH),
//         .DEPTH      (DEPTH)
//     ) instruction_queue (
//         .clk        (clk),
//         .rst        (rst),
//         .data_i     (data_i),
//         .enqueue_i  (enqueue_i),
//         .full_o     (full_o),
//         .data_o     (data_o),
//         .dequeue_i  (dequeue_i),
//         .empty_o    (empty_o)
//     );

//     logic [31:0] curr_instr_addr, last_instr_addr;
//     logic [255:0] curr_instr_data, last_instr_data;
//     logic enable;



//     register #(
//         .A_LEN          (ALEN),
//         .B_LEN          (BLEN)
//     ) line_buffer (
//         .clk            (clk),
//         .rst            (rst),
//         .data_a_input   (curr_instr_data),
//         .data_b_input   (curr_instr_addr),
//         .data_valid     (enable),  // update line buffer if 1
//         .data_a_output  (last_instr_data),
//         .data_b_output  (last_instr_addr)
//     );

//     logic [4:0] rs1_rob_idx, rs2_rob_idx;
//     logic       rs1_renamed, rs2_renamed;
//     logic       rs1_ready, rs2_ready;
//     logic       regf_we, rs_we;
//     logic rsv_valid_out;

//     logic [4:0] rob_addr;
//     rob_entry_t rob_entry_i, rob_entry_o;
//     logic       rob_enqueue_i, rob_update_i, rob_dequeue_i;
//     logic [4:0] rob_head_addr, rob_tail_addr;


//     decode decode_stage (
//         .stall              (stall),
//         .decode_struct_in   (decode_struct_in),
//         .decode_struct_out  (decode_struct_out)
//     );

//     logic [4:0] rs1_dis_idx, rs2_dis_idx;
//     assign rs1_dis_idx = dispatch_struct_in.rs1_addr;
//     assign rs2_dis_idx = dispatch_struct_in.rs2_addr;
//     cdb cdbus;
    
//     rat_arf regfile (
//         // ARF
//         .clk        (clk),
//         .rst        (rst),
//         .dispatch_struct_in (decode_struct_out),    // this should output correct data by the t1me rsv receives new dispatch_struct_in
//         .cdbus(cdbus),
//         //.regf_we(execute_output.regf_we),
//         // RAT
//         //.new_entry  (rob_enqueue_i),
//         .rd_rob_idx (rob_tail_addr),
//         .data(data),
//         .ready(ready),
//         .rob_idx(rob_idx)
//     );

//     always_comb begin : fill_rob_entry
//         rob_entry_i.valid = 1'b1;
//         rob_entry_i.status = rob_wait;
//         rob_entry_i.rd_addr = decode_struct_in.inst[11:7];
//         rob_entry_i.rd_data = 'x;

//         case (decode_struct_in.inst[6:0])
//             op_b_lui, op_b_auipc, op_b_imm, op_b_reg:
//                 rob_entry_i.op_type = alu;
                
//             op_b_br, op_b_jal, op_b_jalr:
//                 rob_entry_i.op_type = br;

//             op_b_load, op_b_store:
//                 rob_entry_i.op_type = mem;

//             default: 
//                 rob_entry_i.op_type = none;
//         endcase
//     end

//     rob rob_inst (
//         .clk        (clk),
//         .rst        (rst),
//         .rob_addr   (next_writeback.rd_rob_idx),
//         .dispatch_struct_in(decode_struct_out),
//         //.rob_entry_i  (rob_entry_i),
//         .current_rd_rob_idx(current_rd_rob_idx),
//         .rob_entry_o  (rob_entry_o),
//         .enqueue_i  (decode_struct_out.valid),
//         .update_i   (next_writeback.valid),     // 1 at writeback
//         .dequeue_i  (1'b0), // from commit
//         .cdbus      (cdbus),
//         .head_addr  (rob_head_addr),
//         .tail_addr  (rob_tail_addr)
//     );
//     logic   rs1_new, rs2_new;


//     reservation_station rsv (
//         .clk(clk),
//         .rst(rst),
//         .we(/*dispatch_struct_in.valid*/rs_we),
//         .dispatch_struct_in(dispatch_struct_in),
//         .current_rd_rob_idx(current_rd_rob_idx),
//         .rs1_data_in(/*rsv_rs1_data_in*/data[rs1_dis_idx]),  //input
//         .rs1_ready(ready[rs1_dis_idx]),
//         .rs2_data_in(/*rsv_rs2_data_in*/data[rs2_dis_idx]),
//         .rs2_ready(ready[rs2_dis_idx]),
//         .rs1_new(rs1_new),
//         .rs2_new(rs2_new),
//         .cdbus(cdbus),
//         .integer_alu_available(integer_alu_available),
//         .mul_alu_available(mul_alu_available),
//         .load_store_alu_available(load_store_alu_available),
//         .next_execute_alu(dispatch_struct_out[0]),
//         .next_execute_mult_div(dispatch_struct_out[1])
//     );

//     alu_unit alu_inst (
//         .clk(clk),
//         .rst(rst),
//         .next_execute(next_execute[0]),
//         .execute_output(execute_output)
//     );

//     logic bmem_flag;
//     always_ff @(posedge clk) begin : fetch
//         reached_loop <= '0;
//         if (rst) begin
//             pc          <= 32'haaaaa000;
//             order       <= '0;
//             ufp_rmask   <= '0;
//             data_i      <= '0;
//             bmem_read   <= 1'b0;
//             bmem_write  <= 1'b0;
//             commit <= 1'b0;
//             enqueue_i <= 1'b0;    
//             bmem_flag <= 1'b0;   
//         end else begin
//             if (commit)     commit <= 1'b0;
//             if (enqueue_i)  enqueue_i <= 1'b0;

//             if (pc[31:5] == last_instr_addr[31:5]) begin       // line buffer
//                 ufp_rmask <= '0;
//                 reached_loop <= '1;
//                 data_i <= {order, pc, last_instr_data[32*pc[4:2] +: 32]};
//                 if (!full_o) begin
//                     enqueue_i <= 1'b1;
//                     pc <= pc_next;
//                     order <= order + 'd1;
//                     commit <= 1'b1;
//                 end
//             end

//             else begin                                  // cache
//                 if (ufp_rmask == 4'd0) begin
//                     ufp_addr <= pc;
//                     ufp_rmask <= '1;                   
//                 end else if (ufp_resp) begin
//                     data_i <= {order, pc, ufp_rdata[32*pc[4:2] +: 32]};
//                     if (!full_o) begin
//                         ufp_rmask <= '0;
//                         enqueue_i <= 1'b1;
//                         // curr_instr_addr <= pc;
//                         // curr_instr_data <= ufp_rcache_line;
//                         // enable <= 1'b1;
//                         pc <= pc_next;
//                         order <= order + 'd1;
//                         commit <= 1'b1;
//                     end
//                 end else if (dfp_write) begin
//                     bmem_addr <= dfp_addr;
//                     bmem_write <= 1'b1;
//                     if (bmem_write && bmem_wdata == 64'h0) begin 
//                         bmem_write <= 1'b0;
//                     end
//                 end else if (dfp_read) begin
//                     bmem_addr <= dfp_addr;
//                     if (bmem_flag == 0) begin
//                         bmem_read <= 1'b1;
//                         bmem_flag <= 1'b1;
//                     end else begin
//                         bmem_read <= 1'b0;
//                     end
//                     if (dfp_resp) begin 
//                         bmem_read <= 1'b0;
//                         bmem_flag <= 1'b0;
//                     end
//                 end
//             end
//         end
//     end

//     // assign dequeue_i = (!empty_o && !rst && !stall); 
    
//     always_ff @(posedge clk) begin
//         if(rst) begin
//         dequeue_i <= '0; 
//         decode_struct_in.inst <= '0;
//         decode_struct_in.pc <= '0;
//         decode_struct_in.order <= '0;
//         decode_struct_in.valid <= 1'b0;
//         end else begin
//         if(!empty_o) begin
//             dequeue_i <= (!empty_o && !rst && !stall); 
//             decode_struct_in.inst <= data_o[31:0];
//             decode_struct_in.pc <= data_o[63:32];
//             decode_struct_in.order <= data_o[127:64];
//             decode_struct_in.valid <= 1'b1;
//             end
//         end
//     end


//     always_comb begin : update_line_buffer
//         enable = 1'b0;
//         if (ufp_resp) begin
//             curr_instr_addr = pc;
//             curr_instr_data = ufp_rcache_line;
//             enable = 1'b1;            
//         end
//     end

//     always_ff @(posedge clk) begin : update_dispatch_str
//         if (rst) begin
//             dispatch_struct_in <= '0;
//             next_execute <= '{default: '0};
//             next_writeback <= '0;
//             next_commit <= '0;
//         end
//         else begin
//             dispatch_struct_in <= decode_struct_out;
//             next_execute <= dispatch_struct_out;
//             next_writeback <= execute_output;

//             // Commit stage
//             next_commit.valid <= next_writeback.valid;
//             next_commit.pc <= next_writeback.pc;
//             next_commit.regf_we <= next_writeback.regf_we;
//             next_commit.rd_addr <= next_writeback.rd_addr;
//             next_commit.rd_rob_idx <= next_writeback.rd_rob_idx;
//             next_commit.rd_data <= next_writeback.rd_data;
//         end
//     end

//     always_comb begin : update_rs_we_cdbus
//         cdbus = '0;
//         if (rst || stall) begin
//             rs_we = 1'b0;
//             cdbus = '0;
//         end else if (decode_struct_out.valid == 1'b1) 
//             rs_we = 1'b1;
//         else rs_we = 1'b0;
//         if(next_writeback.valid) begin
//             cdbus.data = next_writeback.rd_data;
//             cdbus.rd_addr = next_writeback.rd_addr;
//             cdbus.rob_idx = next_writeback.rd_rob_idx;
//             cdbus.valid = next_writeback.valid;
//         end 
//         if (next_commit.valid) begin
//             cdbus.commit_data = next_commit.rd_data;
//             cdbus.commit_rd_addr = next_commit.rd_addr;
//             cdbus.commit_rob_idx = next_commit.rd_rob_idx;
//             cdbus.regf_we = next_commit.regf_we;
//         end
//     end

//     always_comb begin : update_stall
//         stall = 1'b0;
//         if (empty_o || full_o) stall = 1'b1;
//         // else if ( (!integer_alu_available && dispatch_struct_in.op_type == alu) 
//         //              || (!mul_alu_available && dispatch_struct_in.op_type == mul ) 
//         //             ) 
//         else if (!integer_alu_available )
//             stall = 1'b1;
//     end
    

// endmodule : cpu


