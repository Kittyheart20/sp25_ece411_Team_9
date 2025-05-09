module split_lsq
import rv32i_types::*;
# (
    parameter DEPTH = 8,
    parameter ROB_IDX_WIDTH = 5
)(
    //input  logic        is_load,
    input  logic        clk,
    input  logic        rst,
    input  reservation_station_t new_rs_entry,

    input  logic        store_no_mem,
    
    input  cdb          cdbus,
    input               dmem_resp,

    output logic rs_available,  // queue is not full
    output reservation_station_t next_execute
);
    localparam PTR_WIDTH = $clog2(DEPTH);
    
    reservation_station_t default_reservation_station;
    reservation_station_t ld_queue[DEPTH], st_queue[DEPTH];

    logic [PTR_WIDTH-1:0] ld_head, st_head;
    logic [PTR_WIDTH-1:0] ld_tail, st_tail;
    logic [PTR_WIDTH-1:0] ld_head_next, st_head_next;
    logic [PTR_WIDTH:0]   ld_count, st_count;
    logic ld_overflow_alert, st_overflow_alert;

    logic cdb_update;

    assign default_reservation_station = '0;
    assign cdb_update = (cdbus.alu_valid || cdbus.mul_valid || cdbus.br_valid || cdbus.mem_valid || cdbus.regf_we);

    always_ff @(posedge clk) begin
        if (rst || cdbus.flush) begin
            ld_queue <= '{DEPTH{default_reservation_station}};
            ld_head <= '0;
            ld_tail <= '0;
            ld_overflow_alert <= 1'b0;
            
            st_queue <= '{DEPTH{default_reservation_station}};
            st_head <= '0;
            st_tail <= '0;
            st_overflow_alert <= 1'b0;
        end
        else begin
            if (new_rs_entry.regf_we) begin               
                if (new_rs_entry.valid && rs_available) begin
                    ld_queue[ld_tail] <= new_rs_entry;
                    ld_tail <= ld_tail + PTR_WIDTH'(1);
                    if (ld_tail == ld_head-PTR_WIDTH'(1))
                        ld_overflow_alert <= 1'b1;
                end 
            end else begin
                if (new_rs_entry.valid && rs_available) begin : new_rs_entry_to_station
                    st_queue[st_tail] <= new_rs_entry;
                    st_tail <= st_tail + PTR_WIDTH'(1);
                    if (st_tail == st_head-PTR_WIDTH'(1))
                        st_overflow_alert <= 1'b1;
                end  
            end

            for (integer unsigned i = 0; i < DEPTH; i++) begin
                // update load queue
                if ((ld_queue[i].rs1_ready == 1'b0) && (ld_queue[i].rs1_addr != '0)) begin 
                    if (cdbus.alu_valid && (ld_queue[i].rs1_addr == cdbus.alu_rd_addr) && (ld_queue[i].rs1_rob_idx == cdbus.alu_rob_idx))begin
                        ld_queue[i].rs1_data <= cdbus.alu_data; 
                        ld_queue[i].rs1_ready <= 1'b1;                         
                    end
                    else if (cdbus.mul_valid && (ld_queue[i].rs1_addr == cdbus.mul_rd_addr) && (ld_queue[i].rs1_rob_idx == cdbus.mul_rob_idx))begin
                        ld_queue[i].rs1_data <= cdbus.mul_data; 
                        ld_queue[i].rs1_ready <= 1'b1;                         
                    end
                    else if (cdbus.mem_valid && !(&cdbus.mem_wmask) && (ld_queue[i].rs1_addr == cdbus.mem_rd_addr) && (ld_queue[i].rs1_rob_idx == cdbus.mem_rob_idx))begin
                        ld_queue[i].rs1_data <= cdbus.mem_data; 
                        ld_queue[i].rs1_ready <= 1'b1;                         
                    end
                end 
                    
                if ((ld_queue[i].rs2_ready == 1'b0) && (ld_queue[i].rs2_addr != '0)) begin
                    if (cdbus.alu_valid && (ld_queue[i].rs2_addr == cdbus.alu_rd_addr) && (ld_queue[i].rs2_rob_idx == cdbus.alu_rob_idx)) begin
                        ld_queue[i].rs2_data <= cdbus.alu_data; 
                        ld_queue[i].rs2_ready <= 1'b1;                         
                    end
                    else if (cdbus.mul_valid && (ld_queue[i].rs2_addr == cdbus.mul_rd_addr) && (ld_queue[i].rs2_rob_idx == cdbus.mul_rob_idx))begin 
                        ld_queue[i].rs2_data <= cdbus.mul_data; 
                        ld_queue[i].rs2_ready <= 1'b1;                         
                    end
                    else if (cdbus.mem_valid && !(&cdbus.mem_wmask) && (ld_queue[i].rs2_addr == cdbus.mem_rd_addr) && (ld_queue[i].rs2_rob_idx == cdbus.mem_rob_idx))begin
                        ld_queue[i].rs2_data <= cdbus.mem_data; 
                        ld_queue[i].rs2_ready <= 1'b1;                         
                    end
                end
  
                // Mark load queue entry as complete                    
                if (ld_queue[i].valid && ld_queue[i].rs1_ready && ld_queue[i].rs2_ready) begin
                    if (cdbus.mem_rob_idx == ld_queue[i].rd_rob_idx && cdbus.mem_valid && (|ld_queue[i].mem_rmask) ) begin
                        ld_queue[i].status <= COMPLETE;
                        ld_queue[i].valid <= 1'b0;

                        if (PTR_WIDTH'(i)==ld_head) begin
                            ld_head <= ld_head_next;
                            ld_overflow_alert <= 1'b0;
                        end else if (PTR_WIDTH'(i)==ld_tail) begin
                            ld_tail <= ld_tail - PTR_WIDTH'(1);
                            ld_overflow_alert <= 1'b0;
                        end
                    end
                end  
            end

            // Update existing stations with the cdbus
            for (integer unsigned i = 0; i < DEPTH; i++) begin
                if (cdb_update) begin : update_from_writeback
                   // if (new_rs_entry.regf_we) begin
                    // update store queue
                    if ((st_queue[i].rs1_ready == 1'b0) && (st_queue[i].rs1_addr != '0)) begin 
                        if (cdbus.alu_valid && (st_queue[i].rs1_addr == cdbus.alu_rd_addr) && (st_queue[i].rs1_rob_idx == cdbus.alu_rob_idx))begin
                            st_queue[i].rs1_data <= cdbus.alu_data; 
                            st_queue[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (st_queue[i].rs1_addr == cdbus.mul_rd_addr) && (st_queue[i].rs1_rob_idx == cdbus.mul_rob_idx))begin
                            st_queue[i].rs1_data <= cdbus.mul_data; 
                            st_queue[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && !(&cdbus.mem_wmask) && (st_queue[i].rs1_addr == cdbus.mem_rd_addr) && (st_queue[i].rs1_rob_idx == cdbus.mem_rob_idx))begin
                            st_queue[i].rs1_data <= cdbus.mem_data; 
                            st_queue[i].rs1_ready <= 1'b1;                         
                        end
                    end 
                    
                    if ((st_queue[i].rs2_ready == 1'b0) && (st_queue[i].rs2_addr != '0)) begin
                        if (cdbus.alu_valid && (st_queue[i].rs2_addr == cdbus.alu_rd_addr) && (st_queue[i].rs2_rob_idx == cdbus.alu_rob_idx)) begin
                            st_queue[i].rs2_data <= cdbus.alu_data; 
                            st_queue[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (st_queue[i].rs2_addr == cdbus.mul_rd_addr) && (st_queue[i].rs2_rob_idx == cdbus.mul_rob_idx))begin 
                            st_queue[i].rs2_data <= cdbus.mul_data; 
                            st_queue[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && !(&cdbus.mem_wmask) && (st_queue[i].rs2_addr == cdbus.mem_rd_addr) && (st_queue[i].rs2_rob_idx == cdbus.mem_rob_idx))begin
                            st_queue[i].rs2_data <= cdbus.mem_data; 
                            st_queue[i].rs2_ready <= 1'b1;                         
                        end
                    end      
                end
            end

            // Mark store queue entry as wait_store/complete
            if  (st_queue[st_head].valid && cdbus.commit_rob_idx == st_queue[st_head].rd_rob_idx && cdbus.regf_we && (|st_queue[st_head].mem_wmask) ) begin
                st_queue[st_head].status <= WAIT_STORE;
                st_queue[st_head].valid <= 1'b0;
            end 
            else if  ((st_queue[st_head].status == WAIT_STORE) && (dmem_resp || store_no_mem)) begin
                st_queue[st_head].status <= COMPLETE;
                st_head <= st_head + PTR_WIDTH'(1);;
                st_overflow_alert <= 1'b0;
            end
        end
    end 


    logic [PTR_WIDTH-1:0] j; 
    always_comb begin : update_count
        ld_count = {1'b0, ld_tail - ld_head};     
        if (ld_tail < ld_head || ld_overflow_alert)
            ld_count = {{1'b1, ld_tail} - {1'b0, ld_head}};   

        st_count = {1'b0, st_tail - st_head};     
        if (st_tail < st_head || st_overflow_alert)
            st_count = {{1'b1, st_tail} - {1'b0, st_head}};   
        
        ld_head_next = ld_head + PTR_WIDTH'(1); 

        next_execute = '0;        
        j = 'x;
        
        if (!cdbus.flush) begin
            if (st_count == (PTR_WIDTH+1)'(0)) begin    // if no stores pending
                // find any first available load instruction
                for (integer unsigned i = 0; i < DEPTH; i++) begin  // execute the next load ooo 
                    if ((PTR_WIDTH+1)'(i) == ld_count)
                        break;

                    j = ld_head + PTR_WIDTH'(i);
                    if (ld_queue[j].valid && ld_queue[j].rs1_ready && ld_queue[j].rs2_ready) begin
                        next_execute = ld_queue[j];
                        break;
                    end
                end
            end else begin
                if (ld_count == (PTR_WIDTH+1)'(0) || st_queue[st_head].order < ld_queue[ld_head].order) begin
                    if (st_queue[st_head].valid && st_queue[st_head].rs1_ready && st_queue[st_head].rs2_ready)
                        next_execute = st_queue[st_head];
                end else begin
                    for (integer unsigned i = 0; i < DEPTH; i++) begin
                        if ((PTR_WIDTH+1)'(i) == ld_count)
                            break;
                            
                        j = ld_head + PTR_WIDTH'(i);
                        if (ld_queue[j].order < st_queue[st_head].order) begin
                            if (ld_queue[j].valid && ld_queue[j].rs1_ready && ld_queue[j].rs2_ready) begin
                                next_execute = ld_queue[j];
                                break;
                            end
                        end else break;
                    end
                end
            end

            // find next head candidate
            for (integer unsigned i = 1; i<DEPTH; i++) begin
                j = ld_head + PTR_WIDTH'(i);

                if ((PTR_WIDTH+1)'(i) == ld_count) begin
                    ld_head_next = j;
                    break;
                end

                if (ld_queue[j].valid) begin
                    ld_head_next = j;
                    break;
                end
            end
        end
    end

    always_comb begin
        // rs_available = (st_count != (PTR_WIDTH+1)'($unsigned(DEPTH)));

        // if (new_rs_entry.regf_we)
        //     rs_available = (ld_count != (PTR_WIDTH+1)'($unsigned(DEPTH)));
        rs_available = (ld_count != (PTR_WIDTH+1)'($unsigned(DEPTH))) && (st_count != (PTR_WIDTH+1)'($unsigned(DEPTH)));

    //    rs_available = 1'b1;
    //    if (!st_queue[st_tail].valid || !ld_queue[ld_tail].valid)
    //        rs_available = 1'b0;

    end
    
endmodule