module rob 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input id_dis_stage_reg_t dispatch_struct_in,
    output  rob_entry_t rob_entry_o,

    input   logic       enqueue_i,  // = dispatch_struct_in.valid
    input   logic       dequeue_i,
    input   cdb         cdbus,
    input   reservation_station_t next_execute[4],

    output  logic [4:0] tail_addr,
    output  logic       full_o, // if full we need to stall
    output  rob_entry_t rob_table_o [32]
);
    localparam DEPTH = 32;

    rob_entry_t rob_table [DEPTH];
    rob_entry_t rob_table_comb [DEPTH];

    rob_entry_t rob_entry_i;

    logic [4:0]  head, tail;
    logic [31:0] count; 
    logic        empty_o;
    
    assign empty_o = (count == 32'd0);
    assign full_o = (count == DEPTH);
    assign rob_entry_o = rob_table[head];
    
    logic insert, remove;

    assign insert = (enqueue_i && (!full_o || dequeue_i));
    assign remove = dequeue_i && !empty_o;

    always_comb begin
        rob_entry_i = '0;
        rob_entry_i.valid = dispatch_struct_in.valid;
        rob_entry_i.pc = dispatch_struct_in.pc;
        rob_entry_i.inst = dispatch_struct_in.inst;
        rob_entry_i.status = rob_wait;
        rob_entry_i.op_type = dispatch_struct_in.op_type;
        rob_entry_i.rd_addr = dispatch_struct_in.rd_addr;
        rob_entry_i.rd_rob_idx = tail;
        rob_entry_i.rd_valid = 1'b0;
        rob_entry_i.rs1_addr = dispatch_struct_in.rs1_addr;
        rob_entry_i.rs2_addr = dispatch_struct_in.rs2_addr;
        rob_entry_i.regf_we = dispatch_struct_in.regf_we;
    end

    rob_entry_t empty_rob_entry;
    assign empty_rob_entry = '0;
    always_ff @(posedge clk) begin
        if (rst) begin
            head <= '0;
            tail <= '0;
            tail_addr <= '0;
            count <= '0;
            rob_table <= '{DEPTH{empty_rob_entry}};
        end
        else if (cdbus.flush) begin
            head <= head + 5'd1;
            tail <= head + 5'd1;
            tail_addr <= tail;
            count <= '0;
            rob_table <= rob_table_comb;
        end
        else begin
            rob_table <= rob_table_comb;
            if (remove) begin
                head <= head + 5'd1;
            end
            // if (rob_table_comb[head].status == done) begin // Commit stage only takes one cycle for cp2. I don't know if this will change
            //     rob_table_comb[head].status <= empty;
            // end
            
            if (rob_table_comb[head].status == done) begin   // critical path
                // rob_table_comb[head].valid <= '0;
                // head <= head + 5'd1;
            end


   
            
            if (insert) begin
                tail_addr <= tail;
                tail <= tail + 5'd1;
            end
            

            case ({insert, remove})
                2'b10: count <= count + 1'b1; 
                2'b01: count <= count - 1'b1; 
                default: count <= count;      
            endcase

            // Update rs1 and rs2 when next execute arrives
        end
   end
    always_comb begin 
        rob_table_comb = rob_table;
        if (rst) begin

            rob_table_comb = '{DEPTH{empty_rob_entry}};
        end
        else if (cdbus.flush) begin
 

            rob_table_comb[head].status = empty;
            rob_table_comb[head].valid = 1'b0;
            
            for (integer unsigned i = 1; i < 32; i++) begin
                if (i < count) rob_table_comb[(head+i)%32] = '0;
            end
        end
        else begin
   

            for (integer unsigned i = 0; i < DEPTH; i++) begin  // Writeback rd & status update
                if (cdbus.alu_valid && (rob_table[i].rd_addr == cdbus.alu_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.alu_rob_idx) && rob_table[i].valid) begin
                    rob_table_comb[i].status = done;
                    rob_table_comb[i].rd_data = cdbus.alu_data;
                    rob_table_comb[i].rd_valid = 1'b1;
                end                  
                if (cdbus.mul_valid && (rob_table[i].rd_addr == cdbus.mul_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.mul_rob_idx) && rob_table[i].valid) begin
                    rob_table_comb[i].status = done;
                    rob_table_comb[i].rd_data = cdbus.mul_data;
                    rob_table_comb[i].rd_valid = 1'b1;
                end                
                if (cdbus.mem_valid && (rob_table[i].rd_addr == cdbus.mem_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.mem_rob_idx) && rob_table[i].valid) begin
                    rob_table_comb[i].status = done;
                    rob_table_comb[i].rd_data = cdbus.mem_data;
                    rob_table_comb[i].rd_valid = 1'b1;

                    rob_table_comb[i].mem_addr = cdbus.mem_addr;
                    rob_table_comb[i].mem_rmask = cdbus.mem_rmask;
                    rob_table_comb[i].mem_wmask = cdbus.mem_wmask;
                    rob_table_comb[i].mem_rdata = cdbus.mem_rdata;
                    rob_table_comb[i].mem_wdata = cdbus.mem_wdata;
                end
                if (cdbus.br_valid && (rob_table[i].rd_addr == cdbus.br_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.br_rob_idx) && rob_table[i].valid) begin
                    rob_table_comb[i].status = done;
                    rob_table_comb[i].rd_data = cdbus.br_data;
                    rob_table_comb[i].rd_valid = 1'b1;
                    rob_table_comb[i].br_en = cdbus.br_en;
                    rob_table_comb[i].pc_new = cdbus.pc_new;
                    rob_table_comb[i].prediction = cdbus.prediction;
                end
            end
        

            if (remove) begin
                rob_table_comb[head].valid = '0;
            end
 
            
            if (rob_table[head].status == done) begin   // critical path
                rob_table_comb[head].status = empty;
                // rob_table_comb[head].valid = '0;
                // head = head + 5'd1;
            end


            // Rename: enqueue == 1'b1
            // set v=1, status = wait
            // fill in type, rd_data, and br_pred if necessary
            // tail ++    
            
            if (insert) begin
                rob_table_comb[tail] = rob_entry_i;
 
            end
            
            for (integer i = 0; i < 4; i++) begin
                if (next_execute[i].valid && rob_table[next_execute[i].rd_rob_idx].status==rob_wait) begin  // add this in deeper_rsv too
                    rob_table_comb[next_execute[i].rd_rob_idx].rs1_data = next_execute[i].rs1_data;
                    rob_table_comb[next_execute[i].rd_rob_idx].rs2_data = next_execute[i].rs2_data;
                end
            end
        end
   end

    assign rob_table_o = rob_table;

endmodule