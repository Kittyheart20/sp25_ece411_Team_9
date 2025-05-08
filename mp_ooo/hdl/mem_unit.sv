module mem_unit
import rv32i_types::*;
(
    input  logic            clk,
    input  logic            rst,
    input  cdb              cdbus,

    output logic            mem_stall,

    output logic   [31:0]   dmem_addr,
    output logic   [3:0]    dmem_rmask,
    output logic   [3:0]    dmem_wmask,
    input  logic   [31:0]   dmem_rdata,
    output logic   [31:0]   dmem_wdata,
    input  logic            dmem_resp,

    input rob_entry_t rob_entry_o,

    input  reservation_station_t next_execute,
    output to_writeback_t   execute_output,
    output logic store_no_mem
);
    logic [31:0] next_addr;
    assign next_addr = next_execute.rs1_data + next_execute.imm_sext;

        logic is_load, is_store, curr_store;
        assign is_load = (rv32i_opcode'(next_execute.inst[6:0]) == op_b_load);
        assign is_store = (rv32i_opcode'(next_execute.inst[6:0]) == op_b_store);
        
        // logic            store_done;
        // logic   [4:0]    next_store_rob_idx;

        logic   [31:0]   addr;
        logic   [3:0]    rmask;
        logic   [3:0]    wmask;
        logic   [31:0]   wdata;

        logic   [31:0]  prev_pc;
        logic           new_inst;

        localparam WIDTH = 64;  // order + inst addr + data    
        localparam DEPTH = 10;

        logic full_o, empty_o;
        logic enqueue_i, dequeue_i;
        store_buffer_entry data_i, data_o;
        store_buffer_entry data [DEPTH-1:0];
        logic[31:0]   prev_dmem_addr;
        //logic[31:0]   prev_dmem_rdata;

        //logic[31:0]   last_pc_on_dmem;
        logic was_read;
        logic dmem_addr_loaded;
        store_ring_buffer #(
            .DEPTH      (DEPTH)
        ) store_buffer (
            .clk        (clk),
            .rst        (rst),
            .flush      (1'b0),
            .data_i     (data_i),
            .enqueue_i  (enqueue_i),
            .full_o     (full_o),
            .data_o     (data_o),
            .dequeue_i  (dequeue_i),
            .empty_o    (empty_o),
            .data(data)
        );

    always_ff @(posedge clk) begin
        if (rst)
            prev_pc <= '0;
        else if (!mem_stall && !curr_store)
            prev_pc <= next_execute.pc;
    end
    logic [4:0]  prev_rd_rob_idx;

    assign new_inst = (prev_pc != next_execute.pc || prev_rd_rob_idx != next_execute.rd_rob_idx);

    always_comb begin 
        curr_store = rob_entry_o.valid && (rob_entry_o.status == done) && (|rob_entry_o.mem_wmask);
        addr = {next_addr[31:2], 2'd0};
        rmask = next_execute.mem_rmask << next_addr[1:0];
        wmask = next_execute.mem_wmask << next_addr[1:0];
       // wdata = next_execute.rs2_data;
    end
    
    logic addr_in_buffer;
    store_buffer_entry matching_entry; 
    store_buffer_entry entry_to_queue;

    always_comb begin
        addr_in_buffer = 1'b0;
        matching_entry = '0;
        entry_to_queue = '0;

        for(integer unsigned i = 0; i < DEPTH; i++) begin
            if (data[i].valid && (data[i].addr == addr)) begin
                addr_in_buffer = 1'b1;
                matching_entry = data[i];
            end
        end
        if (!(mem_stall) && (!cdbus.flush)) begin
            if (curr_store && (!rst)) begin
                entry_to_queue.addr = rob_entry_o.mem_addr; 
                entry_to_queue.wdata = rob_entry_o.mem_wdata;
                entry_to_queue.wmask = rob_entry_o.mem_wmask;
                entry_to_queue.valid = 1'b1;
                // data_i = entry_to_queue; 
            end
        end
    end
    always_ff @(posedge clk) begin
        if (rst) begin
            dmem_addr <= '0;
            dmem_rmask <= '0;
            dmem_wmask <= '0;
            dmem_wdata <= '0;
            mem_stall <= '0;
            enqueue_i <= 1'b0;
            dequeue_i <= 1'b0;
            store_no_mem <= 1'b0;
            //last_pc_on_dmem <= '0;
            prev_dmem_addr <= '0;
            was_read <= '0;
            dmem_addr_loaded <= '0;
            //prev_dmem_rdata <= '0;
            prev_rd_rob_idx <= '0;
        end else begin
            prev_rd_rob_idx <= next_execute.rd_rob_idx;
            if (dmem_resp) begin
                mem_stall <= '0;
                dmem_rmask <= '0;
                dmem_wmask <= '0;
                prev_dmem_addr <= dmem_addr;
                //last_pc_on_dmem <= next_execute.pc;
                was_read <= |dmem_rmask;
                dmem_addr_loaded <= '0;
                /*if(|dmem_rmask) begin
                    prev_dmem_rdata <= dmem_rdata;
                end*/
            end
            if (!(mem_stall) && (!cdbus.flush)) begin
                if (curr_store) begin
                    data_i <= entry_to_queue; 
                    enqueue_i <= 1'b1;

                    if(full_o && (!addr_in_buffer)) begin
                        dequeue_i <= 1'b1;
                        dmem_addr <= data_o.addr;
                        dmem_rmask <= '0;
                        dmem_wmask <= data_o.wmask;
                        dmem_wdata <= data_o.wdata;
                        mem_stall <= '1;
                        store_no_mem <= 1'b0;
                        dmem_addr_loaded <= 1'b1;
                    end else begin
                        store_no_mem <= 1'b1;   // full_o && addr_in_buffer or !full_o or addr_in_buffer
                    end
                    // dmem_addr <= rob_entry_o.mem_addr;
                    // dmem_rmask <= '0;
                    // dmem_wmask <= rob_entry_o.mem_wmask;
                    // dmem_wdata <= rob_entry_o.mem_wdata;
                    // mem_stall <= '1;
                end else if (is_load && next_execute.valid && new_inst && (!(addr_in_buffer && matching_entry.wmask == 4'b1111))) begin
                    dmem_addr <= {next_addr[31:2], 2'd0};
                    dmem_rmask <= next_execute.mem_rmask << next_addr[1:0];
                    dmem_wmask <= '0;
                    dmem_wdata <= '0;
                    mem_stall <= '1;
                    dmem_addr_loaded <= 1'b1;
                end
            end else begin 
                enqueue_i <= 1'b0;
                dequeue_i <= 1'b0;
                store_no_mem <= 1'b0;
            end
        end
    end
        logic [31:0] wmask_expanded;
        logic [31:0] merged_load_data;

        always_comb begin
            execute_output = '0;
            execute_output.pc = next_execute.pc;
            execute_output.inst = next_execute.inst;
            execute_output.rd_addr = next_execute.rd_addr;
            execute_output.rs1_addr = next_execute.rs1_addr;
            execute_output.rs2_addr = next_execute.rs2_addr;
            execute_output.rd_rob_idx = next_execute.rd_rob_idx;

            for (integer unsigned j = 0; j < 4; j++) begin
                wmask_expanded[(j*8) +: 8] = matching_entry.wmask[j] ? 8'hFF : 8'h00;
            end

            // merge store‑buffer data with memory data
            if(addr_in_buffer) begin
                merged_load_data = (matching_entry.wdata & wmask_expanded)
                                | (dmem_rdata         & ~wmask_expanded);
                if(!dmem_resp && was_read && (prev_dmem_addr == dmem_addr) && dmem_addr_loaded) begin
                //    merged_load_data = (matching_entry.wdata & wmask_expanded)
                //                    | (prev_dmem_rdata         & ~wmask_expanded);
                end
            end else begin
                merged_load_data = dmem_rdata;
                if(!dmem_resp && was_read && (prev_dmem_addr == dmem_addr) && dmem_addr_loaded) begin
                 //   merged_load_data = prev_dmem_rdata;
                end
            end
            
            if(is_load && (addr_in_buffer && matching_entry.wmask == 4'b1111)) begin
                execute_output.valid = 1'b1;
                execute_output.regf_we = 1'b1;
                execute_output.pc = next_execute.pc;
                execute_output.mem_addr = matching_entry.addr;
                execute_output.mem_rmask = rmask;
                execute_output.mem_wmask = '0;
                execute_output.mem_rdata = matching_entry.wdata;

                unique case (next_execute.memop)
                    mem_op_b    : execute_output.rd_data = {{24{matching_entry.wdata[7 +8 *next_addr[1:0]]}}, matching_entry.wdata[8 *next_addr[1:0] +: 8 ]};
                    mem_op_bu   : execute_output.rd_data = {{24{1'b0}}                          , matching_entry.wdata[8 *next_addr[1:0] +: 8 ]};
                    mem_op_h    : execute_output.rd_data = {{16{matching_entry.wdata[15+8 *next_addr[1:0]]}}, matching_entry.wdata[8 *next_addr[1:0] +: 16]};
                    mem_op_hu   : execute_output.rd_data = {{16{1'b0}}                          , matching_entry.wdata[8 *next_addr[1:0] +: 16]};
                    mem_op_w    : execute_output.rd_data = matching_entry.wdata >> 8*next_addr[1:0];
                    default     : execute_output.rd_data = 'x;
                endcase
            end else if (is_load && (dmem_resp /*|| (last_pc_on_dmem == next_execute.pc && (prev_dmem_addr == dmem_addr) && was_read && dmem_addr_loaded)*/)) begin
                execute_output.valid = 1'b1;
                execute_output.regf_we = 1'b1;
                execute_output.pc = next_execute.pc;
                execute_output.mem_addr = dmem_addr;
                execute_output.mem_rmask = rmask;
                execute_output.mem_wmask = '0;
                execute_output.mem_rdata = merged_load_data;

                unique case (next_execute.memop)
                    mem_op_b    : execute_output.rd_data = {{24{merged_load_data[7 +8 *next_addr[1:0]]}}, merged_load_data[8 *next_addr[1:0] +: 8 ]};
                    mem_op_bu   : execute_output.rd_data = {{24{1'b0}}                          , merged_load_data[8 *next_addr[1:0] +: 8 ]};
                    mem_op_h    : execute_output.rd_data = {{16{merged_load_data[15+8 *next_addr[1:0]]}}, merged_load_data[8 *next_addr[1:0] +: 16]};
                    mem_op_hu   : execute_output.rd_data = {{16{1'b0}}                          , merged_load_data[8 *next_addr[1:0] +: 16]};
                    mem_op_w    : execute_output.rd_data = merged_load_data >> 8*next_addr[1:0];
                    default     : execute_output.rd_data = 'x;
                endcase
            end else if (is_store) begin
                execute_output.valid = 1'b1;
                execute_output.pc = next_execute.pc;
                execute_output.mem_addr = addr;
                execute_output.mem_rmask = '0;
                execute_output.mem_wmask = wmask;
                execute_output.mem_wdata = next_execute.rs2_data << (8 * next_addr[1:0]);
            end
        end

endmodule
