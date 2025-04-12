module cpu
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid
);

    logic welp;
    assign welp =  (bmem_raddr == 32'd0); // prevents lint warning on unused variable bmem_raddr

    logic [31:0] pc, pc_next;
    logic [63:0] order;
    logic        commit;
    logic        stall;

    logic   [31:0]  data    [32];
    logic           ready   [32];
    logic   [4:0]   rob_idx [32];
    logic           rs1_rdy, rs2_rdy;

    // Stage Registers
    localparam NUM_FUNC_UNIT = 2;
    
    if_id_stage_reg_t  decode_struct_in;
    id_dis_stage_reg_t decode_struct_out;
    id_dis_stage_reg_t dispatch_struct_in;
    reservation_station_t dispatch_struct_out [NUM_FUNC_UNIT]; 
    reservation_station_t next_execute [NUM_FUNC_UNIT];
    to_writeback_t   execute_output [NUM_FUNC_UNIT];
    to_writeback_t   next_writeback [NUM_FUNC_UNIT]; 

    logic [31:0] rs1_data, rs2_data;
    logic [4:0] current_rd_rob_idx;

    assign pc_next = pc + 32'd4;

    // Cache
    logic   [31:0]  ufp_addr;
    logic   [3:0]   ufp_rmask;
    logic   [3:0]   ufp_wmask;
    logic   [31:0]  ufp_rdata;
    logic   [255:0] ufp_rcache_line;
    logic   [31:0]  ufp_wdata;
    logic           ufp_resp;

    logic   [31:0]  dfp_addr;
    logic           dfp_read;
    logic           dfp_write;
    logic   [255:0] dfp_rdata;
    logic   [255:0] dfp_wdata;
    logic           dfp_resp;
    logic           reached_loop; // debug value

    assign ufp_wmask = '0;
    assign ufp_wdata = '0;

    deserializer cache_line_adapter (
        .clk        (clk),
        .rst        (rst),
        .bmem_ready (bmem_ready),
      //  .bmem_raddr (bmem_raddr),
        .bmem_rdata (bmem_rdata),
        .bmem_rvalid(bmem_rvalid),
        .dfp_wdata  (dfp_wdata),
        .dfp_write  (dfp_write),
        .dfp_rdata  (dfp_rdata),
        .dfp_resp   (dfp_resp),
        .bmem_wdata (bmem_wdata)
    );

    cache instruction_cache (
        .clk        (clk),
        .rst        (rst),
        
        .ufp_addr   (ufp_addr),
        .ufp_rmask  (ufp_rmask),
        .ufp_wmask  (ufp_wmask),
        .ufp_rdata  (ufp_rdata),
        .ufp_rcache_line (ufp_rcache_line),
        .ufp_wdata  (ufp_wdata),
        .ufp_resp   (ufp_resp),

        .dfp_addr   (dfp_addr),
        .dfp_read   (dfp_read),
        .dfp_write  (dfp_write),
        .dfp_rdata  (dfp_rdata),
        .dfp_wdata  (dfp_wdata),
        .dfp_resp   (dfp_resp)
    );

    // Instruction Queue
    localparam WIDTH = 128;  // order + inst addr + data    
    localparam DEPTH = 32;
    localparam ALEN = 256;
    localparam BLEN = 32;

    logic full_o, empty_o;
    logic enqueue_i, dequeue_i;
    logic [WIDTH-1:0] data_i, data_o;

    queue #(
        .WIDTH      (WIDTH),
        .DEPTH      (DEPTH)
    ) instruction_queue (
        .clk        (clk),
        .rst        (rst),
        .data_i     (data_i),
        .enqueue_i  (enqueue_i),
        .full_o     (full_o),
        .data_o     (data_o),
        .dequeue_i  (dequeue_i),
        .empty_o    (empty_o)
    );

    logic [31:0] curr_instr_addr, last_instr_addr;
    logic [255:0] curr_instr_data, last_instr_data;
    logic enable;



    register #(
        .A_LEN          (ALEN),
        .B_LEN          (BLEN)
    ) line_buffer (
        .clk            (clk),
        .rst            (rst),
        .data_a_input   (curr_instr_data),
        .data_b_input   (curr_instr_addr),
        .data_valid     (enable),  // update line buffer if 1
        .data_a_output  (last_instr_data),
        .data_b_output  (last_instr_addr)
    );

    logic [4:0] rs1_rob_idx, rs2_rob_idx;
    logic       rs1_renamed, rs2_renamed;
    logic       rs1_ready, rs2_ready;
    logic       regf_we, rs_we;
    logic rsv_valid_out;

    logic [4:0] rob_addr;
    rob_entry_t rob_entry_i, rob_entry_o;
    logic       rob_enqueue_i, rob_update_i, rob_dequeue_i;
    logic [4:0] rob_head_addr, rob_tail_addr;


    decode decode_stage (
        .stall              (stall),
        .decode_struct_in   (decode_struct_in),
        .decode_struct_out  (decode_struct_out)
    );

    logic [4:0] rs1_dis_idx, rs2_dis_idx;
    assign rs1_dis_idx = dispatch_struct_in.rs1_addr;
    assign rs2_dis_idx = dispatch_struct_in.rs2_addr;
    cdb cdbus;
    
    rat_arf regfile (
        // ARF
        .clk        (clk),
        .rst        (rst),
        .dispatch_struct_in (decode_struct_out),    // this should output correct data by the t1me rsv receives new dispatch_struct_in
        .cdbus(cdbus),
        //.regf_we(execute_output.regf_we),
        // RAT
        //.new_entry  (rob_enqueue_i),
        .rd_rob_idx (rob_tail_addr),
        .data(data),
        .ready(ready),
        .rob_idx(rob_idx),
        .rs1_rdy(rs1_rdy),
        .rs2_rdy(rs2_rdy)
    );

    always_comb begin : fill_rob_entry
        rob_entry_i.valid = 1'b1;
        rob_entry_i.status = rob_wait;
        rob_entry_i.rd_addr = decode_struct_in.inst[11:7];
        rob_entry_i.rd_data = 'x;

        case (decode_struct_in.inst[6:0])
            op_b_lui, op_b_auipc, op_b_imm, op_b_reg:
                rob_entry_i.op_type = alu;
                
            op_b_br, op_b_jal, op_b_jalr:
                rob_entry_i.op_type = br;

            op_b_load, op_b_store:
                rob_entry_i.op_type = mem;

            default: 
                rob_entry_i.op_type = none;
        endcase
    end

    rob rob_inst (
        .clk        (clk),
        .rst        (rst),
      //  .rob_addr   (next_writeback[0].rd_rob_idx)
        .dispatch_struct_in(decode_struct_out),
        //.rob_entry_i  (rob_entry_i),
        .current_rd_rob_idx(current_rd_rob_idx),
        .rob_entry_o  (rob_entry_o),
        .enqueue_i  (decode_struct_out.valid),
    //    .update_i   (next_writeback.valid),     // 1 at writeback
        .dequeue_i  (cdbus.regf_we), // from commit
        .cdbus      (cdbus),
        .head_addr  (rob_head_addr),
        .tail_addr  (rob_tail_addr)
    );
    logic   rs1_new, rs2_new;


    reservation_station rsv (
        .clk(clk),
        .rst(rst),
        .we(/*dispatch_struct_in.valid*/rs_we),
        .dispatch_struct_in(dispatch_struct_in),
        .current_rd_rob_idx(current_rd_rob_idx),
        .rs1_data_in(/*rsv_rs1_data_in*/data[rs1_dis_idx]),  //input
        .rs1_ready(/*ready[rs1_dis_idx]*/rs1_rdy || (!dispatch_struct_in.use_rs1)),
        .rs2_data_in(/*rsv_rs2_data_in*/data[rs2_dis_idx]),
        .rs2_ready(/*ready[rs2_dis_idx]*/rs2_rdy || (!dispatch_struct_in.use_rs2)),
        .rs1_new(rs1_new),
        .rs2_new(rs2_new),
        .cdbus(cdbus),
        .integer_alu_available(integer_alu_available),
        .mul_alu_available(mul_alu_available),
        .load_store_alu_available(load_store_alu_available),
        .next_execute_alu(dispatch_struct_out[0]),
        .next_execute_mult_div(dispatch_struct_out[1])
    );

    logic mul_ready;
    
    alu_unit alu_inst (
        .clk(clk),
        .rst(rst),
        .next_execute(next_execute[0]),
        .execute_output(execute_output[0])
    );

    mul_unit mul_inst (
        .clk(clk),
        .rst(rst),
        .next_execute(next_execute[1]),
        .execute_output(execute_output[1])
    );

    logic bmem_flag;
    always_ff @(posedge clk) begin : fetch
        reached_loop <= '0;
        if (rst) begin
            pc          <= 32'haaaaa000;
            order       <= '0;
            ufp_rmask   <= '0;
            data_i      <= '0;
            bmem_read   <= 1'b0;
            bmem_write  <= 1'b0;
            commit <= 1'b0;
            enqueue_i <= 1'b0;    
            bmem_flag <= 1'b0;   
        end else begin
            if (commit)     commit <= 1'b0;
            if (enqueue_i)  enqueue_i <= 1'b0;

            if (pc[31:5] == last_instr_addr[31:5]) begin       // line buffer
                ufp_rmask <= '0;
                reached_loop <= '1;
                data_i <= {order, pc, last_instr_data[32*pc[4:2] +: 32]};
                if (!full_o && !stall) begin
                    enqueue_i <= 1'b1;
                    pc <= pc_next;
                    order <= order + 'd1;
                    commit <= 1'b1;
                end
            end

            else begin                                  // cache
                if (ufp_rmask == 4'd0) begin
                    ufp_addr <= pc;
                    ufp_rmask <= '1;                   
                end else if (ufp_resp) begin
                    data_i <= {order, pc, ufp_rdata[32*pc[4:2] +: 32]};
                    if (!full_o) begin
                        ufp_rmask <= '0;
                        enqueue_i <= 1'b1;
                        // curr_instr_addr <= pc;
                        // curr_instr_data <= ufp_rcache_line;
                        // enable <= 1'b1;
                        pc <= pc_next;
                        order <= order + 'd1;
                        commit <= 1'b1;
                    end
                end else if (dfp_write) begin
                    bmem_addr <= dfp_addr;
                    bmem_write <= 1'b1;
                    if (bmem_write && bmem_wdata == 64'h0) begin 
                        bmem_write <= 1'b0;
                    end
                end else if (dfp_read) begin
                    bmem_addr <= dfp_addr;
                    if (bmem_flag == 0) begin
                        bmem_read <= 1'b1;
                        bmem_flag <= 1'b1;
                    end else begin
                        bmem_read <= 1'b0;
                    end
                    if (dfp_resp) begin 
                        bmem_read <= 1'b0;
                        bmem_flag <= 1'b0;
                    end
                end
            end
        end
    end


    always_comb begin : prep_decode_in
        dequeue_i = (!empty_o && !rst && !stall); 

        if (rst) begin
            decode_struct_in = '0;
        end else begin
            if (dequeue_i) begin
                decode_struct_in.inst = data_o[31:0];
                decode_struct_in.pc = data_o[63:32];
                decode_struct_in.order = data_o[127:64];
                decode_struct_in.valid = 1'b1;
            end else begin
                decode_struct_in.valid = 1'b0;
            end
        end
    end


    always_comb begin : update_line_buffer
        enable = 1'b0;
        if (ufp_resp) begin
            curr_instr_addr = pc;
            curr_instr_data = ufp_rcache_line;
            enable = 1'b1;            
        end
    end

    always_ff @(posedge clk) begin : update_dispatch_str
        if (rst) begin
            dispatch_struct_in <= '0;
            next_execute <= '{default: '0};
            next_writeback <= '{default: '0};
        end
        else begin
            dispatch_struct_in <= decode_struct_out;
            next_execute <= dispatch_struct_out;
            next_writeback <= execute_output;
        end
    end

    always_comb begin : update_rs_we_cdbus
        cdbus = '0;
        if (rst || stall) begin
            rs_we = 1'b0;
            cdbus = '0;
        end else if (decode_struct_out.valid == 1'b1) 
            rs_we = 1'b1;
        else 
            rs_we = 1'b0;

        // broadcast writeback
        if (next_writeback[0].valid) begin 
            cdbus.alu_data = next_writeback[0].rd_data;
            cdbus.alu_rd_addr = next_writeback[0].rd_addr;
            cdbus.alu_rob_idx = next_writeback[0].rd_rob_idx;
            cdbus.alu_valid = next_writeback[0].valid;
            cdbus.pc = next_writeback[0].pc;
            cdbus.inst = next_writeback[0].inst;
            cdbus.rs1_addr = next_writeback[0].rs1_addr;
            cdbus.rs2_addr = next_writeback[0].rs2_addr;
        end 
        if (next_writeback[1].valid) begin 
            cdbus.mul_data = next_writeback[1].rd_data;
            cdbus.mul_rd_addr = next_writeback[1].rd_addr;
            cdbus.mul_rob_idx = next_writeback[1].rd_rob_idx;
            cdbus.mul_valid = next_writeback[1].valid;
            cdbus.pc = next_writeback[1].pc;
            cdbus.inst = next_writeback[1].inst;
            cdbus.rs1_addr = next_writeback[1].rs1_addr;
            cdbus.rs2_addr = next_writeback[1].rs2_addr;
        end

        // commit
        if (rob_entry_o.valid && rob_entry_o.status == done) begin
            cdbus.commit_data = rob_entry_o.rd_data;
            cdbus.commit_rd_addr = rob_entry_o.rd_addr;
            cdbus.commit_rob_idx = rob_entry_o.rd_rob_idx;
            cdbus.regf_we = 1'b1;
        end
    end

    logic failure;
    assign failure = (!integer_alu_available) != (!integer_alu_available && (dispatch_struct_in.op_type == alu || dispatch_struct_in.op_type == none));
    always_comb begin : update_stall
        stall = 1'b0;
        if (empty_o || full_o) stall = 1'b1;
        else if ( (!integer_alu_available && (dispatch_struct_in.op_type == alu || dispatch_struct_in.op_type == none)) 
                     || (!mul_alu_available &&  (dispatch_struct_in.op_type == mul || dispatch_struct_in.op_type == none)) )  begin
                stall = 1'b1;    
            end
                
        // else if (!integer_alu_available )
        //     stall = 1'b1;    

        end

    logic[64:0] m_order;
    always_ff @(posedge clk) begin
        if (rst) begin
            m_order <= 0;
        end
        else begin
            if(cdbus.regf_we)
                m_order <= m_order + 1;
        end
    end
    logic           monitor_valid;
    logic   [63:0]  monitor_order;
    logic   [31:0]  monitor_inst;
    logic   [4:0]   monitor_rs1_addr;
    logic   [4:0]   monitor_rs2_addr;
    logic   [31:0]  monitor_rs1_rdata;
    logic   [31:0]  monitor_rs2_rdata;
    logic           monitor_regf_we;
    logic   [4:0]   monitor_rd_addr;
    logic   [31:0]  monitor_rd_wdata;
    logic   [31:0]  monitor_pc_rdata;
    logic   [31:0]  monitor_pc_wdata;
    logic   [31:0]  monitor_mem_addr;
    logic   [3:0]   monitor_mem_rmask;
    logic   [3:0]   monitor_mem_wmask;
    logic   [31:0]  monitor_mem_rdata;
    logic   [31:0]  monitor_mem_wdata;

    logic [4:0] commit_rs1_addr, commit_rs2_addr;
    always_ff @( posedge clk ) begin
        if (rst) begin
            commit_rs1_addr <= '0;
            commit_rs2_addr <= '0;   
        end
        if (cdbus.regf_we) begin
            commit_rs1_addr <= monitor_rs1_addr;
            commit_rs2_addr <= monitor_rs2_addr;            
        end
    end

    assign monitor_valid     = cdbus.regf_we;
    assign monitor_order     = m_order; 
    assign monitor_inst      = cdbus.inst;
    assign monitor_rs1_addr  = cdbus.rs1_addr;
    assign monitor_rs2_addr  = cdbus.rs2_addr;
    assign monitor_rs1_rdata = data[commit_rs1_addr];
    assign monitor_rs2_rdata = data[commit_rs2_addr];
    assign monitor_rd_addr   = cdbus.commit_rd_addr;
    assign monitor_rd_wdata  = cdbus.commit_data;
    assign monitor_pc_rdata  = cdbus.pc;
    assign monitor_pc_wdata  = cdbus.pc + 4;
    assign monitor_mem_addr  = '0;
    assign monitor_mem_rmask = '0;
    assign monitor_mem_wmask = '0;
    assign monitor_mem_rdata = '0;
    assign monitor_mem_wdata = '0;


endmodule : cpu