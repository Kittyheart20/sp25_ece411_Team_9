module reservation_station
import rv32i_types::*;
# (
    parameter DEPTH = 8,
    parameter ROB_IDX_WIDTH = 5
)(
    // input  logic        is_mem,
    input  logic        clk,
    input  logic        rst,
    input  reservation_station_t new_rs_entry,

    // input  logic        store_no_mem,
    
    input  cdb          cdbus,
    // input               dmem_resp,

    output logic rs_available,  // queue is not full and execute unit is not busy
    output reservation_station_t next_execute
);
    localparam PTR_WIDTH = $clog2(DEPTH);
    
    reservation_station_t default_reservation_station;
    reservation_station_t stations[DEPTH];
    logic [PTR_WIDTH-1:0] head, tail, next_head_idx; 
    logic [PTR_WIDTH:0]   count;
    logic cdb_update;
    logic valid [DEPTH];
    logic overflow_alert;

    assign default_reservation_station = '0;
    assign cdb_update = (cdbus.alu_valid || cdbus.mul_valid || cdbus.br_valid || cdbus.mem_valid || cdbus.regf_we);

    always_ff @(posedge clk) begin
        if (rst || cdbus.flush) begin
            stations <= '{DEPTH{default_reservation_station}};
            head <= '0;
            tail <= '0;
            overflow_alert <= 1'b0;
        end
        else begin
            if (new_rs_entry.valid && rs_available) begin : new_rs_entry_to_station
                stations[tail] <= new_rs_entry; 
                tail <= tail + PTR_WIDTH'(1);

                if (tail == head-PTR_WIDTH'(1))
                    overflow_alert <= 1'b1; 
            end 

            // Update existing stations with the cdbus
            for (integer unsigned i = 0; i < DEPTH; i++) begin
                if (cdb_update) begin : update_from_writeback
                    if (((stations[i].rs1_ready == 1'b0) && (stations[i].rs1_addr != '0))) begin 
                        if(cdbus.alu_valid && (stations[i].rs1_addr == cdbus.alu_rd_addr) && (stations[i].rs1_rob_idx == cdbus.alu_rob_idx))begin
                            stations[i].rs1_data <= cdbus.alu_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (stations[i].rs1_addr == cdbus.mul_rd_addr) && (stations[i].rs1_rob_idx == cdbus.mul_rob_idx))begin
                            stations[i].rs1_data <= cdbus.mul_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && !(&cdbus.mem_wmask) && (stations[i].rs1_addr == cdbus.mem_rd_addr) && (stations[i].rs1_rob_idx == cdbus.mem_rob_idx))begin
                            stations[i].rs1_data <= cdbus.mem_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.regf_we && (stations[i].rs1_addr == cdbus.commit_rd_addr) && (stations[i].rs1_rob_idx == cdbus.commit_rob_idx)) begin
                            stations[i].rs1_data <= cdbus.commit_data; 
                            stations[i].rs1_ready <= 1'b1;  
                        end 
                    end 
                    
                    if (((stations[i].rs2_ready == 1'b0) && (stations[i].rs2_addr != '0))) begin
                        if(cdbus.alu_valid && (stations[i].rs2_addr == cdbus.alu_rd_addr) && (stations[i].rs2_rob_idx == cdbus.alu_rob_idx)) begin
                            stations[i].rs2_data <= cdbus.alu_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (stations[i].rs2_addr == cdbus.mul_rd_addr) && (stations[i].rs2_rob_idx == cdbus.mul_rob_idx))begin 
                            stations[i].rs2_data <= cdbus.mul_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && !(&cdbus.mem_wmask) && (stations[i].rs2_addr == cdbus.mem_rd_addr) && (stations[i].rs2_rob_idx == cdbus.mem_rob_idx))begin
                            stations[i].rs2_data <= cdbus.mem_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.regf_we && (stations[i].rs2_addr == cdbus.commit_rd_addr) && (stations[i].rs2_rob_idx == cdbus.commit_rob_idx)) begin
                            stations[i].rs2_data <= cdbus.commit_data; 
                            stations[i].rs2_ready <= 1'b1;  
                        end 
                    end
                end
                // if (!is_mem) begin
                    if (stations[i].valid && stations[i].rs1_ready && stations[i].rs2_ready) begin
                        if (cdbus.alu_rob_idx == stations[i].rd_rob_idx && cdbus.alu_valid) begin
                            stations[i].status <= COMPLETE;
                            stations[i].valid <= 1'b0;
                            if (PTR_WIDTH'(i)==head) begin
                                head <= next_head_idx;
                                overflow_alert <= 1'b0;
                            end else if (PTR_WIDTH'(i)==tail) begin
                                tail <= tail - PTR_WIDTH'(1);
                                overflow_alert <= 1'b0;
                            end
                        end
                        else if  (cdbus.mul_rob_idx == stations[i].rd_rob_idx && cdbus.mul_valid) begin
                            stations[i].status <= COMPLETE;  
                            stations[i].valid <= 1'b0;  
                            if (PTR_WIDTH'(i)==head) begin
                                head <= next_head_idx;
                                overflow_alert <= 1'b0;
                            end else if (PTR_WIDTH'(i)==tail) begin
                                tail <= tail - PTR_WIDTH'(1);
                                overflow_alert <= 1'b0;
                            end   
                        end      
                        else if  (cdbus.br_rob_idx == stations[i].rd_rob_idx && cdbus.br_valid) begin
                            stations[i].status <= COMPLETE;   
                            stations[i].valid <= 1'b0;
                            if (PTR_WIDTH'(i)==head) begin
                                head <= next_head_idx;
                                overflow_alert <= 1'b0;
                            end else if (PTR_WIDTH'(i)==tail) begin
                                tail <= tail - PTR_WIDTH'(1);
                                overflow_alert <= 1'b0;
                            end
                        end            
                        // else if  (cdbus.mem_rob_idx == stations[i].rd_rob_idx && cdbus.mem_valid && (|stations[i].mem_rmask) ) begin
                        //     stations[i].status <= COMPLETE;
                        //     stations[i].valid <= 1'b0;
                        //     if (PTR_WIDTH'(i)==head) begin
                        //         head <= next_head_idx;
                        //         overflow_alert <= 1'b0;
                        //     end else if (PTR_WIDTH'(i)==tail) begin
                        //         tail <= tail - PTR_WIDTH'(1);
                        //         overflow_alert <= 1'b0;
                        //     end
                        // end                     
                        // else if  (stations[i].valid && cdbus.commit_rob_idx == stations[i].rd_rob_idx && cdbus.regf_we && (|stations[i].mem_wmask) ) begin
                        //     stations[i].status <= WAIT_STORE;
                        //     stations[i].valid <= 1'b0;
                        // end // skip here
                    end
                    // else if  ((stations[i].status == WAIT_STORE) && (dmem_resp || store_no_mem)) begin
                    //     stations[i].status <= COMPLETE;
                    //     stations[i].valid <= 1'b0;
                    //     if (PTR_WIDTH'(i)==head) begin
                    //         head <= next_head_idx;
                    //         overflow_alert <= 1'b0;
                    //     end else if (PTR_WIDTH'(i)==tail) begin
                    //         tail <= tail - PTR_WIDTH'(1);
                    //         overflow_alert <= 1'b0;
                    //     end
                    // end
                    if (!(stations[head].valid) && count > (PTR_WIDTH+1)'(0)) begin
                        head <= head + PTR_WIDTH'(1);
                        overflow_alert <= 1'b0;
                    end
               // end
                // else if (PTR_WIDTH'(i)==head) begin
                    // if (stations[i].valid && stations[i].rs1_ready && stations[i].rs2_ready && cdbus.alu_rob_idx == stations[i].rd_rob_idx && cdbus.alu_valid) begin
                    //     stations[i].status <= COMPLETE;
                    //     stations[i].valid <= 1'b0;
                    //     head <= head + PTR_WIDTH'(1);
                    //     overflow_alert <= 1'b0;
                    //     //executing_stall <= '0;
                    // end
                    // else if  (stations[i].valid && stations[i].rs1_ready && stations[i].rs2_ready && cdbus.mul_rob_idx == stations[i].rd_rob_idx && cdbus.mul_valid) begin
                    //     stations[i].status <= COMPLETE;  
                    //     stations[i].valid <= 1'b0;  
                    //     head <= head + PTR_WIDTH'(1);
                    //     overflow_alert <= 1'b0;
                    // end      
                    // else if  (stations[i].valid && stations[i].rs1_ready && stations[i].rs2_ready && cdbus.br_rob_idx == stations[i].rd_rob_idx && cdbus.br_valid) begin
                    //     stations[i].status <= COMPLETE;   
                    //     stations[i].valid <= 1'b0;
                    //     head <= head + PTR_WIDTH'(1);
                    //     overflow_alert <= 1'b0;
                    // end            
                    // else 
                //     if  (stations[i].valid && stations[i].rs1_ready && stations[i].rs2_ready && cdbus.mem_rob_idx == stations[i].rd_rob_idx && cdbus.mem_valid && (|stations[i].mem_rmask) ) begin
                //         stations[i].status <= COMPLETE;
                //         stations[i].valid <= 1'b0;
                //         head <= head + PTR_WIDTH'(1);
                //         overflow_alert <= 1'b0;
                //     end 
                //     else if  (stations[i].valid && cdbus.commit_rob_idx == stations[i].rd_rob_idx && cdbus.regf_we && (|stations[i].mem_wmask) ) begin
                //         stations[i].status <= WAIT_STORE;
                //         stations[i].valid <= 1'b0;
                //     end 
                //     else if  ((stations[i].status == WAIT_STORE) && (dmem_resp || store_no_mem) ) begin
                //         stations[i].status <= COMPLETE;
                //         stations[i].valid <= 1'b0;
                //         head <= head + PTR_WIDTH'(1);
                //         overflow_alert <= 1'b0;
                //     end
                // end
            end
        end
    end

    always_comb begin : mark_valid
        valid = '{DEPTH{1'b1}};

        for (integer unsigned i = 0; i < DEPTH; i++) begin
            if (stations[i].valid && stations[i].rs1_ready && stations[i].rs2_ready) begin
                if ((cdbus.alu_rob_idx == stations[i].rd_rob_idx && cdbus.alu_valid)
                    || (cdbus.mul_rob_idx == stations[i].rd_rob_idx && cdbus.mul_valid)
                    || (cdbus.br_rob_idx == stations[i].rd_rob_idx && cdbus.br_valid))           
                    valid[i] = 1'b0;
            end
        end
    end

    logic [PTR_WIDTH-1:0] j; 
    always_comb begin : update_count
        count = {1'b0, tail - head};     
        if (tail < head || overflow_alert)
            count = {{1'b1, tail} - {1'b0, head}};   

        next_execute = '0;
        j = 'x;
        next_head_idx = head + PTR_WIDTH'(1);
        
        // if (is_mem) begin
        //     if (stations[head].valid && stations[head].rs1_ready && stations[head].rs2_ready) begin
        //         next_execute = stations[head];
        //     end
        // end else 
        if (!cdbus.flush) begin
            for (integer unsigned i = 1; i<DEPTH; i++) begin
                j = head + PTR_WIDTH'(i);

                if ((PTR_WIDTH+1)'(i) == count) begin
                    next_head_idx = j;
                    break;
                end

                if (stations[j].valid) begin
                    next_head_idx = j;
                    break;
                end
            end
            
            for (integer unsigned i = 0; i < DEPTH; i++) begin
                if ((PTR_WIDTH+1)'(i) == count)
                    break;

                j = head + PTR_WIDTH'(i);
                if (valid[j] && stations[j].valid && stations[j].rs1_ready && stations[j].rs2_ready) begin
                    next_execute = stations[j];
                    break;
                end
            end

        end

    end

    assign rs_available = (count != (PTR_WIDTH+1)'($unsigned(DEPTH)));
    
endmodule