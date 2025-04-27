module mem_unit
    import rv32i_types::*;
    (
        input  logic            clk,
        input  logic            rst,
        input cdb cdbus,
//        input logic inst_mem_stall, 

        output logic            mem_stall,

        output logic   [31:0]   dmem_addr,
        output logic   [3:0]    dmem_rmask,
        output logic   [3:0]    dmem_wmask,
        input  logic   [31:0]   dmem_rdata,
        output logic   [31:0]   dmem_wdata,
        input  logic            dmem_resp,

        input rob_entry_t rob_entry_o,

        input  reservation_station_t next_execute,
        output to_writeback_t   execute_output
        // output mem_commit_t     mem_commit_data
    );
        logic [31:0] next_addr;
        assign next_addr = next_execute.rs1_data + next_execute.imm_sext;

        logic is_load, is_store, curr_store;
        assign is_load = (rv32i_opcode'(next_execute.inst[6:0]) == op_b_load);
        assign is_store = (rv32i_opcode'(next_execute.inst[6:0]) == op_b_store);
        mem_commit_t store_commit;
        
        logic   [31:0]   addr;
        logic   [3:0]    rmask;
        logic   [3:0]    wmask;
        logic   [31:0]   wdata;

        logic   [31:0]  prev_pc;
        logic   [31:0]  debug_addr;
        assign debug_addr = 32'haaab0000;
        logic debug_hit;
        assign debug_hit = (dmem_addr == debug_addr);
        logic [31:9] debug_tag;
        assign debug_tag = debug_addr[31:9];
        logic debug_tag_hit;
        always_comb begin
            debug_tag_hit = 1'b0;
            if(dmem_addr[31:9] == debug_tag) begin
                debug_tag_hit = 1'b1;
            end
        end


        always_ff @(posedge clk) begin
            if (rst)
                prev_pc <= '0;
            else if (1)
                prev_pc <= next_execute.pc;
        end

        logic           new_inst;
        assign new_inst = (prev_pc != next_execute.pc);

        always_comb begin 
            curr_store = 1'b0;
            // if (rob_entry_o.valid !== 1'bx &&       // ss : from what i see, rob_table entries never have x
            //     rob_entry_o.status !== status_t'('x) &&
            //     rob_entry_o.mem_wmask !== 4'bx)
            // begin
            //     curr_store = rob_entry_o.valid &&
            //                 (rob_entry_o.status == done) &&
            //                 (|rob_entry_o.mem_wmask);
            // end
            curr_store = rob_entry_o.valid && (rob_entry_o.status == done) && (|rob_entry_o.mem_wmask);

            addr = {next_addr[31:2], 2'd0};
            rmask = next_execute.mem_rmask << next_addr[1:0];
            wmask = next_execute.mem_wmask << next_addr[1:0];
            wdata = next_execute.rs2_data;
        end
        logic debug_y2;
        assign debug_y2 = (curr_store) && mem_stall;
        // assign mem_stall = (addr != '0) && (addr == next_addr) && !(dmem_resp);

        // logic prev_inst;
        // always_ff @(posedge clk) begin
        //     if (rst) begin
        //         prev_inst <= '0;
        //     end else begin
        //         prev_inst <= next_execute.inst;
        //     end
        // end
        // assign mem_stall = (dmem_addr != '0) && (next_execute.inst == prev_inst) && !(dmem_resp);

        always_ff @(posedge clk) begin
            if (rst) begin
                dmem_addr <= '0;
                dmem_rmask <= '0;
                dmem_wmask <= '0;
                dmem_wdata <= '0;
                mem_stall <= '0;
            end else begin
                if (dmem_resp) begin
                    mem_stall <= '0;
                    dmem_rmask <= '0;
                    dmem_wmask <= '0;
                end
                if (!(mem_stall) && (!cdbus.flush)) begin
                    if (curr_store) begin
                        dmem_addr <= rob_entry_o.mem_addr;
                        dmem_rmask <= '0;
                        dmem_wmask <= rob_entry_o.mem_wmask;
                        dmem_wdata <= rob_entry_o.mem_wdata;
                        mem_stall <= '1;
                    end else if (is_load && next_execute.valid && new_inst) begin
                        dmem_addr <= {next_addr[31:2], 2'd0};
                        dmem_rmask <= next_execute.mem_rmask << next_addr[1:0];
                        dmem_wmask <= '0;
                        dmem_wdata <= '0;
                        mem_stall <= '1;
                    end
                end 
            end
        end

        always_comb begin
            execute_output = '0;
            execute_output.pc = next_execute.pc;
            execute_output.inst = next_execute.inst;
            execute_output.rd_addr = next_execute.rd_addr;
            execute_output.rs1_addr = next_execute.rs1_addr;
            execute_output.rs2_addr = next_execute.rs2_addr;
            execute_output.rd_rob_idx = next_execute.rd_rob_idx;

            if (is_load && dmem_resp) begin
                execute_output.valid = 1'b1;
                execute_output.regf_we = 1'b1;

                unique case (next_execute.memop)
                    mem_op_b    : execute_output.rd_data = {{24{dmem_rdata[7 +8 *next_addr[1:0]]}}, dmem_rdata[8 *next_addr[1:0] +: 8 ]};
                    mem_op_bu   : execute_output.rd_data = {{24{1'b0}}                          , dmem_rdata[8 *next_addr[1:0] +: 8 ]};
                    mem_op_h    : execute_output.rd_data = {{16{dmem_rdata[15+8 *next_addr[1:0]]}}, dmem_rdata[8 *next_addr[1:0] +: 16]};
                    mem_op_hu   : execute_output.rd_data = {{16{1'b0}}                          , dmem_rdata[8 *next_addr[1:0] +: 16]};
                    mem_op_w    : execute_output.rd_data = dmem_rdata >> 8*next_addr[1:0];
                    default     : execute_output.rd_data = 'x;
                endcase
            end 
            
            else if (is_store) begin
                execute_output.valid = 1'b1;
            end

            if (is_load && dmem_resp) begin
                execute_output.pc = next_execute.pc;
                execute_output.mem_addr = dmem_addr;
                execute_output.mem_rmask = rmask;
                execute_output.mem_wmask = '0;
                execute_output.mem_rdata = dmem_rdata;
            end else if (is_store) begin
                execute_output.pc = next_execute.pc;
                execute_output.mem_addr = addr;
                execute_output.mem_rmask = '0;
                execute_output.mem_wmask = wmask;
                execute_output.mem_wdata = next_execute.rs2_data << (8 * next_addr[1:0]);
            end
        end

endmodule
