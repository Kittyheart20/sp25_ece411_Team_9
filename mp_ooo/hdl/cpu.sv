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

    logic bmem_flag;
    reservation_station_t default_reservation_station;
    to_writeback_t default_to_writeback;

    always_comb begin: default_values
        default_reservation_station = '0;
        default_to_writeback = '0;
    end

    logic   [31:0]  pc, pc_next, pc_next_prev;
    logic   [63:0]  order;
    //logic           commit;
    logic           stall;
    logic           stall_except_empty;
    logic           alu_stall_unit, mult_stall_unit, br_stall_unit, mem_stall_unit;

    rat_arf_entry_t rat_arf_table [32];
    logic           rs1_rdy, rs2_rdy;
    logic mem_stall;
    logic mem_stall_prev;
    logic flush_registered;

    logic mul_alu_available, int_alu_available, br_alu_available, mem_available;
    logic gselect_taken;

    // Stage Registers
    localparam NUM_FUNC_UNIT = 4;
    
    if_id_stage_reg_t  decode_struct_in;
    id_dis_stage_reg_t decode_struct_out;
    //id_dis_stage_reg_t decode_struct_out_compressed;
    id_dis_stage_reg_t dispatch_struct_in;
    reservation_station_t dispatch_struct_out [NUM_FUNC_UNIT];
    reservation_station_t next_execute [NUM_FUNC_UNIT];

    to_writeback_t   execute_output [NUM_FUNC_UNIT];
    to_writeback_t   next_writeback [NUM_FUNC_UNIT]; 

    logic [31:0] rs1_data, rs2_data;
    logic [4:0] current_rd_rob_idx;

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

    logic prediction_followed;


    assign ufp_wmask = '0;
    assign ufp_wdata = '0;

    // Inst & Data cache
    logic   [31:0]  dfp_addr_inst;
    logic           dfp_read_inst;
    logic           dfp_write_inst;
    logic   [255:0] dfp_rdata_inst;
    logic   [255:0] dfp_wdata_inst;
    logic           dfp_resp_inst;

    logic   [31:0]  dmem_addr;
    logic   [3:0]   dmem_rmask;
    logic   [3:0]   dmem_wmask;
    logic   [31:0]  dmem_rdata;
    logic   [31:0]  dmem_wdata;
    logic           dmem_resp;
    
    logic   [31:0]  ufp_addr_mem;
    logic   [3:0]   ufp_rmask_mem;
    logic   [3:0]   ufp_wmask_mem;
    logic   [31:0]  ufp_rdata_mem;
    logic   [255:0] ufp_rcache_line_mem;
    logic   [31:0]  ufp_wdata_mem;
    logic           ufp_resp_mem;

    logic   [31:0]  dfp_addr_mem;
    logic           dfp_read_mem;
    logic           dfp_write_mem;
    logic   [255:0] dfp_rdata_mem;
    logic   [255:0] dfp_wdata_mem;
    logic           dfp_resp_mem;

    logic ufp_resp_prefetch;
    logic rsv_stall;

    if_id_stage_reg_t  decode_struct_in_early;
    id_dis_stage_reg_t decode_struct_out_early;

    logic gselect_taken_prev;

    // logic   [31:0]      bmem_addr_old;
    // assign bmem_addr = dfp_write ? dfp_addr : bmem_addr_old;

    deserializer cache_line_adapter (
        .clk        (clk),
        .rst        (rst),
        .bmem_ready (bmem_ready),
        .bmem_raddr (bmem_raddr),
        .bmem_rdata (bmem_rdata),
        .bmem_rvalid(bmem_rvalid),
        .dfp_wdata  (dfp_wdata),
        .dfp_write  (dfp_write),
        .dfp_rdata  (dfp_rdata),
        // .dfp_raddr  (dfp_raddr),
        // .dfp_addr   (dfp_addr),
        .dfp_resp   (dfp_resp),
        // .dfp_read   (dfp_read),
        .bmem_wdata (bmem_wdata),
        .bmem_write (bmem_write),
        .bmem_read  (bmem_read),
        .bmem_addr  (bmem_addr),
        .bmem_flag(bmem_flag)
    );

    prefetcher instruction_cache (
        .clk        (clk),
        .rst        (rst),
        
        .ufp_addr   (ufp_addr),
        .ufp_rmask  (ufp_rmask),
        .ufp_wmask  (ufp_wmask),
        .ufp_rdata  (ufp_rdata),
        .ufp_rcache_line (ufp_rcache_line),
        .ufp_wdata  (ufp_wdata),
        .ufp_resp   (ufp_resp),

        .dfp_addr   (dfp_addr_inst),
        .dfp_read   (dfp_read_inst),
        .dfp_write  (dfp_write_inst),
        .dfp_rdata  (dfp_rdata_inst),
        .dfp_wdata  (dfp_wdata_inst),
        .dfp_resp   (dfp_resp_inst),
        .ufp_resp_prefetch(ufp_resp_prefetch)
    );

    cache data_cache (
        .clk        (clk),
        .rst        (rst),
        
        .ufp_addr   (ufp_addr_mem),
        .ufp_rmask  (ufp_rmask_mem),
        .ufp_wmask  (ufp_wmask_mem),
        .ufp_rdata  (ufp_rdata_mem),
        .ufp_rcache_line (ufp_rcache_line_mem),
        .ufp_wdata  (ufp_wdata_mem),
        .ufp_resp   (ufp_resp_mem),

        .dfp_addr   (dfp_addr_mem),
        .dfp_read   (dfp_read_mem),
        .dfp_write  (dfp_write_mem),
        .dfp_rdata  (dfp_rdata_mem),
        .dfp_wdata  (dfp_wdata_mem),
        .dfp_resp   (dfp_resp_mem)
    );
    cdb cdbus;

    // Instruction Queue
    localparam WIDTH = 129;  // order + inst addr + data    
    localparam DEPTH = 32;
    localparam ALEN = 256;
    localparam BLEN = 32;

    logic full_o, empty_o;
    logic enqueue_i, dequeue_i;
    logic [WIDTH-1:0] data_i, data_o;
    logic [31:0] curr_instr_addr, last_instr_addr;
    logic [255:0] curr_instr_data, last_instr_data;

    logic [31:0]  curr_dmem_addr,  last_dmem_addr;
    logic [255:0] curr_dmem_data, last_dmem_data;

    queue #(
        .WIDTH      (WIDTH),
        .DEPTH      (DEPTH)
    ) instruction_queue (
        .clk        (clk),
        .rst        (rst),
        .flush      (cdbus.flush),
        .data_i     (data_i),
        .enqueue_i  (enqueue_i),
        .full_o     (full_o),
        .data_o     (data_o),
        .dequeue_i  (dequeue_i),
        .empty_o    (empty_o)
    );


    logic instr_enable;

    register #(
        .A_LEN          (ALEN),
        .B_LEN          (BLEN)
    ) inst_line_buffer (
        .clk            (clk),
        .rst            (rst),
        .data_a_input   (curr_instr_data),
        .data_b_input   (curr_instr_addr),
        .data_valid     (instr_enable),
        .data_a_output  (last_instr_data),
        .data_b_output  (last_instr_addr)
    );

    logic dmem_enable;

    always_ff @(posedge clk) begin
        if (rst) begin
            mem_stall_prev <= 1'b0;
        end else begin
            mem_stall_prev <= mem_stall;
        end
    end

    logic inst_mem_stall;       // MEM STALL STARTS AT SAME TIME AS INST_MEM_STALL
    /*logic [63:0] cycles_since_inst_mem_stall;

    always_ff @(posedge clk) begin
        if (rst) begin
            cycles_since_inst_mem_stall <= 64'd0;
        end else if (inst_mem_stall) begin
            cycles_since_inst_mem_stall <= cycles_since_inst_mem_stall + 64'd1;
        end else begin
            cycles_since_inst_mem_stall <= '0;
        end
    end*/

    always_ff @(posedge clk) begin
        if (rst) begin
            inst_mem_stall <= 1'b0;
        end else if (ufp_resp_prefetch) begin
            inst_mem_stall <= 1'b0;
        end else if (dfp_read_inst && (!mem_stall)) begin
            inst_mem_stall <= 1'b1;
        end 
    end

    register #(
        .A_LEN          (ALEN),
        .B_LEN          (BLEN)
    ) data_line_buffer (
        .clk            (clk),
        .rst            (rst),
        .data_a_input   (curr_dmem_data),
        .data_b_input   (curr_dmem_addr),
        .data_valid     (dmem_enable),
        .data_a_output  (last_dmem_data),
        .data_b_output  (last_dmem_addr)
    );

    logic [4:0] rs1_rob_idx, rs2_rob_idx;
    //logic       rs1_renamed, rs2_renamed;
    logic       rs1_ready, rs2_ready;
    logic       regf_we;

    logic [4:0] rob_addr;
    rob_entry_t rob_entry_o;
    logic       rob_enqueue_i, rob_update_i, rob_dequeue_i;
    logic       rob_full_o;

    decode decode_stage (
        .decode_struct_in   (decode_struct_in),
        .decode_struct_out  (decode_struct_out)
    );

    decode decode_stage_early (
        .decode_struct_in   (decode_struct_in_early),
        .decode_struct_out  (decode_struct_out_early)
    );

    /*logic is_compressed_inst;+ 
    decode_compressed decode_compressed_stage (
        .decode_struct_in   (decode_struct_in),
        .decode_struct_out  (decode_struct_out_compressed),
        .is_compressed_inst(is_compressed_inst)
    );*/

    logic [4:0] rs1_dis_idx, rs2_dis_idx;
    assign rs1_dis_idx = dispatch_struct_in.rs1_addr;
    assign rs2_dis_idx = dispatch_struct_in.rs2_addr;
    
    rat_arf regfile (
        .clk        (clk),
        .rst        (rst),
        .dispatch_struct_in (dispatch_struct_in),
        .cdbus(cdbus),
        .rd_rob_idx (current_rd_rob_idx),
        .rs1_rob_idx(rs1_rob_idx),
        .rs2_rob_idx(rs2_rob_idx),
        .rat_arf_table(rat_arf_table),
        .rs1_rdy(rs1_rdy),
        .rs2_rdy(rs2_rdy)
    );
    

    rob_entry_t rob_table_o [32];

    rob rob_inst (
        .clk        (clk),
        .rst        (rst),
        .dispatch_struct_in(decode_struct_out),
        .rob_entry_o  (rob_entry_o),
        .rob_table_o  (rob_table_o),
        .enqueue_i  (decode_struct_out.valid),
        .dequeue_i  (cdbus.regf_we),
        .cdbus      (cdbus),
        .next_execute(next_execute),
        .tail_addr  (current_rd_rob_idx),
        .full_o(rob_full_o)
    );
    
    logic   rsv_rs1_ready, rsv_rs2_ready;
    logic store_no_mem;

    assign rsv_rs1_ready = (rat_arf_table[dispatch_struct_in.rs1_addr].ready || rs1_rdy) || (!dispatch_struct_in.use_rs1);
    assign rsv_rs2_ready = (rat_arf_table[dispatch_struct_in.rs2_addr].ready || rs2_rdy) || (!dispatch_struct_in.use_rs2);

    dispatch_issue rsv (
        .clk(clk),
        .rst(rst),
        .dispatch_struct_in(dispatch_struct_in),
        .current_rd_rob_idx(current_rd_rob_idx),
        .rs1_data_in(rat_arf_table[rs1_dis_idx].data),
        .rs1_ready(rsv_rs1_ready),

        .rs2_data_in(rat_arf_table[rs2_dis_idx].data),
        .rs2_ready(rsv_rs2_ready),
        .rob_table(rob_table_o),

        .cdbus(cdbus),
        .dmem_resp(dmem_resp),

        .rs1_rob_idx(rs1_rob_idx), 
        .rs2_rob_idx(rs2_rob_idx),
        .integer_alu_available(int_alu_available),
        .mul_alu_available(mul_alu_available),
        .br_alu_available(br_alu_available),
        .mem_available(mem_available),
        .next_execute_alu(dispatch_struct_out[0]),
        .next_execute_mult_div(dispatch_struct_out[1]),
        .next_execute_branch(dispatch_struct_out[2]),
        .next_execute_mem(dispatch_struct_out[3]),
        .store_no_mem(store_no_mem)
    );

    // logic mul_ready;
    
    alu_unit alu_inst (
        .next_execute(next_execute[0]),
        .execute_output(execute_output[0])
    );

    mul_unit mul_inst (
        .clk(clk),
        .rst(rst),
        .next_execute(next_execute[1]),
        .execute_output(execute_output[1])
    );

    br_unit br_inst (
        .next_execute(next_execute[2]),
        .execute_output(execute_output[2])
    );
    
    mem_unit mem_inst (
        .clk(clk),
        .rst(rst),
        .mem_stall(mem_stall),
        .dmem_addr(dmem_addr),
        .dmem_rmask(dmem_rmask),
        .dmem_wmask(dmem_wmask),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .dmem_resp(dmem_resp),
        .rob_entry_o(rob_entry_o),
        .next_execute(next_execute[3]),
        .execute_output(execute_output[3]),
        .cdbus(cdbus),
        .store_no_mem(store_no_mem)
    );

    logic prediction;

    tournament_predictor hybrid (
        .clk(clk),
        .rst(rst),
        .pc_to_predict(decode_struct_out_early.pc),  
        .pc_to_update(rob_entry_o.pc),            
        .branch_taken(rob_entry_o.br_en),
        .is_branch(rob_entry_o.op_type == br && (rob_entry_o.status == done)),
        .prediction(prediction)
    );
    
    always_comb begin
        dfp_resp_inst = '0;
        dfp_rdata_inst = '0;

        dfp_addr = dfp_addr_inst;
        dfp_read = dfp_read_inst;
        dfp_write = dfp_write_inst;
        dfp_wdata = dfp_wdata_inst;
        dfp_rdata_inst = dfp_rdata;
        dfp_resp_inst = dfp_resp && inst_mem_stall;

        dfp_rdata_mem = '0;
        dfp_resp_mem = 1'b0;

        if (mem_stall) begin
            dfp_addr = dfp_addr_mem;
            dfp_read = dfp_read_mem ;
            dfp_write = dfp_write_mem;
            dfp_wdata = dfp_wdata_mem;

            dfp_rdata_mem = dfp_rdata;
            dfp_resp_mem = dfp_resp && (!inst_mem_stall);

            if (!mem_stall_prev) begin
                dfp_resp_inst = dfp_resp && inst_mem_stall;
            end
        end
    end

    logic flush_stalling;
    logic [63:0] m_order;

    //logic gselect_help_flag;
    always_ff @(posedge clk) begin : fetch
        if (rst) begin
            pc          <= 32'haaaaa000;
            order       <= '0;
            ufp_rmask   <= '0;
            data_i      <= '0;
            bmem_read   <= 1'b0;
            bmem_addr      <= 32'h0;
            //commit <= 1'b0;
            enqueue_i <= 1'b0;    
            bmem_flag <= 1'b0;   
            flush_stalling <= '0;
            //gselect_help_flag <= 1'b0;
        end else begin
            //if (commit)     commit <= 1'b0;
            if (enqueue_i)  enqueue_i <= 1'b0;
            if (bmem_read)  bmem_read <= 1'b0;

            if (cdbus.flush) begin 
                pc <= pc_next; 
                bmem_read <= 1'b0;
                if (dfp_resp) begin 
                    bmem_read <= 1'b0;
                    bmem_flag <= 1'b0;
                 end
                if (ufp_rmask > '0)
                    flush_stalling <= '1;
                else begin
                    data_i <= {prediction && prediction_followed, m_order, pc_next, last_instr_data[32*pc[4:2] +: 32]};
                    order <= m_order;
                    if (pc_next[31:5] != last_instr_addr[31:5]) begin
                        ufp_rmask <= '1; 
                        ufp_addr <= pc_next;                         
                    end
               end            
            end else if (dfp_read_mem && (rob_entry_o.rd_rob_idx == next_execute[3].rd_rob_idx)) begin     // critical path
                if (bmem_flag == 1'd0) begin
                    bmem_addr  <= dfp_addr;
                    bmem_read <= 1'd1;
                    bmem_flag <= 1'd1;
                end else begin
                    bmem_read <= 1'd0;
                end

                if (dfp_resp) begin 
                    bmem_flag <= 1'd0;
                end        
            end 
            else if (ufp_resp && (flush_stalling == '1)) begin
                flush_stalling <= '0;
                data_i <= {prediction && prediction_followed, m_order, pc_next, last_instr_data[32*pc[4:2] +: 32]};
                order <= m_order;
                ufp_addr <= pc;
                ufp_rmask <= '1;   
            end
            else begin
                if (ufp_resp) begin
                    data_i <= {prediction && prediction_followed, order, pc, ufp_rdata}; 
                    if (!full_o) begin
                        ufp_rmask <= '0;
                        enqueue_i <= 1'b1;
                        pc <= pc_next;
                        order <= order + 'd1;
                        //commit <= 1'b1;
                    end
                /*end else if (gselect_taken && (decode_struct_out_early.pc != pc) && (!gselect_help_flag)) begin
                    pc <= pc_next;
                    gselect_help_flag <= 1'b1;*/
                end else if (pc[31:5] == last_instr_addr[31:5] && ~&ufp_rmask) begin    // ~& is bitwise NAND   critical path
                    ufp_rmask <= '0;
                    data_i <= {prediction && prediction_followed, order, pc, last_instr_data[32*pc[4:2] +: 32]};
                    if (!full_o && (!stall_except_empty)/*&& !stall_except_empty*/) begin
                        enqueue_i <= 1'b1;
                        pc <= pc_next;
                        order <= order + 'd1;
                        //commit <= 1'b1;
                    end
                end else if (ufp_rmask == 4'd0) begin
                    ufp_addr <= pc;
                    ufp_rmask <= '1;                   
                end 
                if (dfp_write && !bmem_flag) begin
                    bmem_addr <= dfp_addr;
                end 
                if (dfp_resp) begin 
                        bmem_read <= 1'b0;
                        bmem_flag <= 1'b0;
                end else if (dfp_read) begin
                    if (bmem_flag == 1'b0) begin
                        bmem_addr  <= dfp_addr;
                        bmem_read <= 1'b1;
                        bmem_flag <= 1'b1;
                    end else begin
                        bmem_read <= 1'b0;
                    end
                end

            end
        end
    end

    logic [WIDTH-1:0] data_i_comb;
    //logic nclk;
    //assign nclk = ~clk;
    always_comb  begin 
        data_i_comb = '0;
        if (rst) begin
            data_i_comb      = '0;
        end else begin

            if(cdbus.flush) begin 
                data_i_comb = data_i;
                if (dfp_resp) begin 
                end
                if (ufp_rmask > '0) begin
                end else begin
                    data_i_comb = {1'b0, m_order, pc_next_prev, last_instr_data[32*pc[4:2] +: 32]};
               end
            end else if (dfp_read_mem && (rob_entry_o.rd_rob_idx == next_execute[3].rd_rob_idx)) begin     // ss: dmem read
                data_i_comb = data_i;       
            end 
            else if (ufp_resp && (flush_stalling == '1)) begin
                data_i_comb = {1'b0, m_order, pc_next_prev, last_instr_data[32*pc[4:2] +: 32]}; 
            end
            else begin
                if (ufp_resp) begin
                    data_i_comb = {1'b0, order, pc, ufp_rdata}; 
                /*end else if (gselect_taken && (decode_struct_out_early.pc != pc) && (!gselect_help_flag)) begin
                    pc <= pc_next;
                    gselect_help_flag <= 1'b1;*/
                end else if (pc[31:5] == last_instr_addr[31:5] && ~&ufp_rmask) begin    // ~& is bitwise NAND
                    data_i_comb = {1'b0, order, pc, last_instr_data[32*pc[4:2] +: 32]};
                end else if (ufp_rmask == 4'd0) begin
                    data_i_comb = data_i;                  
                end 

            end
        end
    end

    always_comb begin : data_cache_ufp
        ufp_addr_mem = dmem_addr;
        ufp_rmask_mem = dmem_rmask;
        ufp_wmask_mem = dmem_wmask;

        ufp_wdata_mem = '0;
        if (dmem_wmask[3])  ufp_wdata_mem[31:24] = dmem_wdata[31:24];
        if (dmem_wmask[2])  ufp_wdata_mem[23:16] = dmem_wdata[23:16];
        if (dmem_wmask[1])  ufp_wdata_mem[15:8] = dmem_wdata[15:8];
        if (dmem_wmask[0])  ufp_wdata_mem[7:0] = dmem_wdata[7:0];

        dmem_rdata = '0;
        if (dmem_rmask[3])  dmem_rdata[31:24] = ufp_rdata_mem[31:24];
        if (dmem_rmask[2])  dmem_rdata[23:16] = ufp_rdata_mem[23:16];
        if (dmem_rmask[1])  dmem_rdata[15:8] = ufp_rdata_mem[15:8];
        if (dmem_rmask[0])  dmem_rdata[7:0] = ufp_rdata_mem[7:0];

        dmem_resp = ufp_resp_mem;
    end

    always_comb begin : prep_decode_in
        dequeue_i = (!empty_o && !rst && !stall) || (full_o && (!rsv_stall)); 
        decode_struct_in = '0;

        if (!empty_o) begin
            decode_struct_in.inst = data_o[31:0];
            decode_struct_in.pc = data_o[63:32];
            decode_struct_in.order = data_o[127:64];      
            decode_struct_in.prediction = data_o[128];     
        end    

        decode_struct_in.valid = dequeue_i;

        decode_struct_in_early = '0;
        decode_struct_in_early.inst = data_i_comb[31:0];
        decode_struct_in_early.pc = data_i_comb[63:32];
        decode_struct_in_early.order = data_i_comb[127:64];  
  
    end   

    always_comb begin : update_line_buffer
        instr_enable = 1'b0;
        dmem_enable = 1'b0;
        curr_instr_addr = '0;
        curr_instr_data = '0;
        curr_dmem_addr = '0;
        curr_dmem_data = '0;

        if (ufp_resp) begin
            curr_instr_addr = pc;
            curr_instr_data = ufp_rcache_line;
            instr_enable = 1'b1;      
        end
        if (cdbus.flush) begin
            if (pc[31:5] != last_instr_addr[31:5]) begin
                curr_instr_addr = pc;
                curr_instr_data = '0;
            end
            instr_enable = 1'b1;            
        end else if (ufp_resp_mem && mem_stall && |dmem_wmask) begin
            curr_dmem_addr = dmem_addr;
            curr_dmem_data = last_dmem_data;
            curr_dmem_data[32*dmem_addr[4:2] +: 32] = ufp_wdata_mem;
            dmem_enable = 1'b1;            
        end else if (ufp_resp_mem && mem_stall) begin
            curr_dmem_addr = dmem_addr;
            curr_dmem_data = ufp_rcache_line_mem;
            dmem_enable = 1'b1;            
        end
    end

    always_ff @(posedge clk) begin : update_dispatch_str
        if (rst || cdbus.flush) begin
            dispatch_struct_in <= '0;
            next_execute <= '{NUM_FUNC_UNIT{default_reservation_station}};
            // next_writeback <= '{NUM_FUNC_UNIT{default_to_writeback}};
        end
        else begin
            dispatch_struct_in <= decode_struct_out;
            //dispatch_struct_in.prediction <= prediction && prediction_followed;
            next_execute[0] <= dispatch_struct_out[0];
            next_execute[1] <= dispatch_struct_out[1];
            next_execute[2] <= dispatch_struct_out[2];
            if (!mem_stall)
                next_execute[3] <= dispatch_struct_out[3];

            // next_writeback <= execute_output;

            // for (integer i = 0; i < 4; i++) begin
            //     if (execute_output[i].valid)
            //         next_writeback[i] <= execute_output[i];
            //     else
            //         next_writeback[i] <= '0;
            // end
        end
    end

    always_comb begin
        if (rst || cdbus.flush) begin
            // dispatch_struct_in <= '0;
            // next_execute = '{NUM_FUNC_UNIT{default_reservation_station}};
            next_writeback = '{NUM_FUNC_UNIT{default_to_writeback}};
        end
        else begin

            for (integer i = 0; i < 4; i++) begin
                if (execute_output[i].valid)
                    next_writeback[i] = execute_output[i];
                else
                    next_writeback[i] = '0;
            end
            // next_writeback = execute_output;
        end
    end

    to_writeback_t   next_writeback_prev [NUM_FUNC_UNIT]; 
    always_ff @(posedge clk) begin 
        if (rst) begin
            next_writeback_prev <= '{NUM_FUNC_UNIT{default_to_writeback}};
            gselect_taken_prev <= '0;
        end else begin
            next_writeback_prev <= next_writeback;
            gselect_taken_prev <= gselect_taken;
        end
    end
    logic[31:0] pc_plus_4;
    logic[31:0] imm_plus_pc;
    logic[31:0] rob_pc_plus_4;
    logic[31:0] flush_pc_registered;

    always_ff @(posedge clk) begin 
        if (rst) begin
            flush_registered <= '0;
            flush_pc_registered <= '0;
        end else begin
        if (rob_entry_o.valid && rob_entry_o.status == done && (!flush_registered)) begin
            if(rob_entry_o.br_en != rob_entry_o.prediction) begin
                if(rob_entry_o.br_en == 0) begin
                    flush_pc_registered <= rob_pc_plus_4;
                    flush_registered <= '1;
                end else begin
                    flush_pc_registered <= rob_entry_o.pc_new;
                    flush_registered <= '1;
                end
            end else flush_registered <= '0;
        end else flush_registered <= '0;
        end
    end

    always_comb begin : update_rs_we_cdbus
        rob_pc_plus_4 = {rob_entry_o.pc [31:2] + 1'b1, rob_entry_o.pc[1:0]};;
        cdbus = '0;
        pc_plus_4 = {pc[31:2] + 1'b1, pc[1:0]};
        pc_next = pc_plus_4;
        prediction_followed = '0;
        gselect_taken = '0;
        imm_plus_pc = decode_struct_out_early.imm + decode_struct_out_early.pc;
        if(!cdbus.flush) begin
            if(decode_struct_out_early.opcode == op_b_jal || decode_struct_out_early.opcode == op_b_br) begin
                if(prediction) begin
                    prediction_followed = '1;
                    pc_next = imm_plus_pc;
                    gselect_taken = '1;
                    if(pc == pc_next) begin
                        pc_next = pc_plus_4;
                    end
                end
            end
        end
        if (rst || stall) begin
            cdbus = '0;
        end 

        // broadcast writeback
        if (next_writeback[0].valid) begin 
            cdbus.alu_data = next_writeback[0].rd_data;
            cdbus.alu_rd_addr = next_writeback[0].rd_addr;
            cdbus.alu_rob_idx = next_writeback[0].rd_rob_idx;
            cdbus.alu_valid = next_writeback[0].valid;
        end 
        if (next_writeback[1].valid) begin 
            cdbus.mul_data = next_writeback[1].rd_data;
            cdbus.mul_rd_addr = next_writeback[1].rd_addr;
            cdbus.mul_rob_idx = next_writeback[1].rd_rob_idx;
            cdbus.mul_valid = next_writeback[1].valid;
        end
        if (next_writeback[2].valid) begin 
            cdbus.br_data = next_writeback[2].rd_data;
            cdbus.br_rd_addr = next_writeback[2].rd_addr;
            cdbus.br_rob_idx = next_writeback[2].rd_rob_idx;
            cdbus.br_valid = next_writeback[2].valid && (next_writeback[2] != next_writeback_prev[2]);
            cdbus.br_en = next_writeback[2].br_en;
            cdbus.pc_new = next_writeback[2].pc_new;
            cdbus.prediction = next_writeback[2].prediction;
        end 
        if (next_writeback[3].valid) begin 
            cdbus.mem_data = next_writeback[3].rd_data;
            cdbus.mem_rd_addr = next_writeback[3].rd_addr;
            cdbus.mem_rob_idx = next_writeback[3].rd_rob_idx;
            cdbus.mem_valid = next_writeback[3].valid && (next_writeback[3] != next_writeback_prev[3]);
            cdbus.mem_addr = next_writeback[3].mem_addr;
            cdbus.mem_rmask = next_writeback[3].mem_rmask;
            cdbus.mem_wmask = next_writeback[3].mem_wmask;
            cdbus.mem_rdata = next_writeback[3].mem_rdata;
            cdbus.mem_wdata = next_writeback[3].mem_wdata;
        end
        // commit - critical path
        if (rob_entry_o.valid && rob_entry_o.status == done && (!flush_registered)) begin
            cdbus.commit_data = rob_entry_o.rd_data;
            cdbus.commit_rd_addr = rob_entry_o.rd_addr;
            cdbus.commit_rob_idx = rob_entry_o.rd_rob_idx;
            // cdbus.regf_we = rob_entry_o.regf_we;
            cdbus.regf_we = 1'b1;
            cdbus.rs1_addr = rob_entry_o.rs1_addr;
            cdbus.rs2_addr = rob_entry_o.rs2_addr;
            cdbus.rs1_data = rob_entry_o.rs1_data;
            cdbus.rs2_data = rob_entry_o.rs2_data; 
            cdbus.pc = rob_entry_o.pc;
            cdbus.inst = rob_entry_o.inst;
            // if(rob_entry_o.br_en) begin
            //     pc_next = rob_entry_o.pc_new;
            //     cdbus.flush = '1;
            // end 
        end
            if(flush_registered) begin
                pc_next = flush_pc_registered;
                cdbus.flush = '1;
            end
    end

    logic stall_prev;
    always_ff @(posedge clk) begin
        if (rst) begin
            stall_prev <= 1'b0;
            pc_next_prev <= '0;
        end
        else begin
            pc_next_prev <= pc_next;
            stall_prev <= stall;
        end
    end

    always_comb begin : update_stall
        stall = 1'b0;
        stall_except_empty = 1'b0;
        rsv_stall = 1'b0;

        alu_stall_unit  = !int_alu_available && (decode_struct_out.op_type == alu || decode_struct_out.op_type == none);
        mult_stall_unit = !mul_alu_available && (decode_struct_out.op_type == mul || decode_struct_out.op_type == none);
        br_stall_unit   = !br_alu_available  && (decode_struct_out.op_type == br  || decode_struct_out.op_type == none);
        mem_stall_unit  = !mem_available     && (decode_struct_out.op_type == mem || decode_struct_out.op_type == none);

        if (empty_o || full_o || rob_full_o) stall = 1'b1;
        else if (alu_stall_unit | mult_stall_unit | br_stall_unit | mem_stall_unit) begin
            stall = 1'b1;
            stall_except_empty = 1'b1;
            rsv_stall = 1'b1;
        end else if (dispatch_struct_in.valid && (  (!int_alu_available && (dispatch_struct_in.op_type == alu || dispatch_struct_in.op_type == none)) 
                    || (!mul_alu_available &&  (dispatch_struct_in.op_type == mul || dispatch_struct_in.op_type == none))  
                    || (!mem_available && (dispatch_struct_in.op_type == mem  || dispatch_struct_in.op_type == none))
                    || (!br_alu_available &&  (dispatch_struct_in.op_type == br || dispatch_struct_in.op_type == none)) ))  begin
            stall = 1'b1;    
            rsv_stall = 1'b1;
            stall_except_empty = 1'b1;
        end 
        else if (dispatch_struct_in.valid && ( ((dispatch_struct_in.op_type == alu && decode_struct_out.op_type == alu)) 
                || ((dispatch_struct_in.op_type == mul && decode_struct_out.op_type == mul))  
                || ((dispatch_struct_in.op_type == mem  && decode_struct_out.op_type == mem))
                || ((dispatch_struct_in.op_type == br && decode_struct_out.op_type == br)) ))  begin
            if (stall_prev == 0) begin 
                stall = 1'b1;
                stall_except_empty = 1'b1;
            end
        end
        

        if (full_o || rob_full_o) stall_except_empty = 1'b1;

    end

    always_ff @(posedge clk) begin
        if (rst) begin
            m_order <= '0;
        end
        else if (cdbus.regf_we)
            m_order <= m_order + 1;
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

    assign monitor_valid     = cdbus.regf_we;
    assign monitor_order     = m_order; 
    assign monitor_inst      = cdbus.inst;
    assign monitor_rs1_addr  = cdbus.rs1_addr;
    assign monitor_rs2_addr  = cdbus.rs2_addr;
    assign monitor_rs1_rdata = rat_arf_table[cdbus.rs1_addr].data; // cdbus.rs1_data;
    assign monitor_rs2_rdata = rat_arf_table[cdbus.rs2_addr].data; // cdbus.rs2_data;
    assign monitor_rd_addr   = cdbus.commit_rd_addr;
    assign monitor_rd_wdata  = cdbus.commit_data;
    assign monitor_pc_rdata  = cdbus.pc;

    always_comb begin
        if (rob_entry_o.valid && rob_entry_o.status == done && rob_entry_o.br_en) 
            monitor_pc_wdata = rob_entry_o.pc_new;
        else 
            monitor_pc_wdata  = cdbus.pc + 4;
    end

    assign monitor_mem_addr  = rob_entry_o.mem_addr;
    assign monitor_mem_rmask = rob_entry_o.mem_rmask;
    assign monitor_mem_wmask = rob_entry_o.mem_wmask;
    assign monitor_mem_rdata = rob_entry_o.mem_rdata;
    assign monitor_mem_wdata = rob_entry_o.mem_wdata;

    logic dummy;
    assign dummy = bmem_rvalid && (bmem_raddr == 32'd0);

endmodule : cpu

// :'D