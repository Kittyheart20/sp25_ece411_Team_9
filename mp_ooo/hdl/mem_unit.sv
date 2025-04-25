module mem_unit
    import rv32i_types::*;
    (
        input  logic            clk,
        input  logic            rst,
        output logic            mem_stall,

        output logic   [31:0]   dmem_addr,
        output logic   [3:0]    dmem_rmask,
        output logic   [3:0]    dmem_wmask,
        input  logic   [31:0]   dmem_rdata,
        output logic   [31:0]   dmem_wdata,
        input  logic            dmem_resp,

        input  reservation_station_t next_execute,
        output to_writeback_t   execute_output
        // output mem_commit_t     mem_commit_data
    );
        logic [31:0] next_addr;
        assign next_addr = next_execute.rs1_data + next_execute.imm_sext;

        logic is_load, is_store;
        assign is_load = (rv32i_opcode'(next_execute.inst[6:0]) == op_b_load);
        assign is_store = (rv32i_opcode'(next_execute.inst[6:0]) == op_b_store);
        
        logic   [31:0]   addr;
        logic   [3:0]    rmask;
        logic   [3:0]    wmask;
        logic   [31:0]   wdata;

        always_comb begin 
            addr = {next_addr[31:2], 2'd0};
            rmask = next_execute.mem_rmask << next_addr[1:0];
            wmask = next_execute.mem_wmask << next_addr[1:0];
            wdata = next_execute.rs2_data;
        end
        
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
                if (dmem_resp)
                    mem_stall <= '0;
                if (!(mem_stall) && next_execute.valid) begin
                    // dmem_addr <= {next_addr[31:2], 2'd0};

                    // // if (is_load) begin
                    // //     // dmem_rmask <= next_execute.mem_rmask << next_addr[1:0];
                    // // end else 
                    // if (is_store) begin
                    //     dmem_wmask <= next_execute.mem_wmask;
                    //     dmem_wdata <= next_execute.rs2_data;
                    // end
                    dmem_addr <= {next_addr[31:2], 2'd0};
                    // addr = {next_addr[31:2], 2'd0};
                    if (is_load) begin
                        dmem_rmask <= next_execute.mem_rmask << next_addr[1:0];
                        dmem_wmask <= '0;
                        dmem_wdata <= '0;
                        mem_stall <= '1;
                        // rmask <= next_execute.mem_rmask << next_addr[1:0];
                        // wmask <= '0;
                        // wdata <= '0;
                        
                    // end else if (is_store) begin
                    //     dmem_rmask <= '0;
                    //     dmem_wmask <= next_execute.mem_wmask << next_addr[1:0];
                    //     dmem_wdata <= next_execute.rs2_data;  
                    //     mem_stall <= '0;
                    //     // rmask <= '0;
                    //     // wmask <= next_execute.mem_wmask << next_addr[1:0];
                    //     // wdata <= next_execute.rs2_data;       
                    // end
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
                execute_output.mem_rmask = rmask; //dmem_rmask;
                execute_output.mem_wmask = '0; //wmask;
                execute_output.mem_rdata = execute_output.rd_data;
            end else if (is_store) begin
                execute_output.pc = next_execute.pc;
                execute_output.mem_addr = addr;
                execute_output.mem_rmask = '0; //dmem_rmask;
                execute_output.mem_wmask = wmask; //dmem_wmask;
                execute_output.mem_wdata = next_execute.rs2_data;
            end
        end

endmodule
