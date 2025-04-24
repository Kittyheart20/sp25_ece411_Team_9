module rob 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input id_dis_stage_reg_t dispatch_struct_in,
    // output logic [4:0] current_rd_rob_idx,
    output  rob_entry_t rob_entry_o,

    input   logic       enqueue_i,  // Do we need this? We can just use dispatch_struct_in.valid
    // input   logic       update_i,
    input   logic       dequeue_i,
    input   cdb         cdbus,


    // output  logic [4:0] head_addr,
    output  logic [4:0] tail_addr,
    output  logic       full_o, // if full we need to stall
    output  rob_entry_t rob_table_o [32]
);
    localparam DEPTH = 32;

    rob_entry_t rob_table [DEPTH];
    rob_entry_t rob_entry_i;

    logic [4:0]  head, tail;
    logic [31:0] count; 
    logic        empty_o;//, full_o;
    logic debug;
    
    assign empty_o = (count == 32'd0);
    assign full_o = (count == DEPTH);
    assign rob_entry_o = rob_table[head];
    // assign current_rd_rob_idx = tail_addr;
    
    logic rob_update_mul, rob_update_alu;
    logic insert, remove;

    assign insert = (dispatch_struct_in.valid && enqueue_i && (!full_o || dequeue_i));
    assign remove = dequeue_i && !empty_o;

    always_comb begin
        rob_entry_i = '0;
        //rob_entry_i = dispatch_struct_in;
        rob_entry_i.valid = dispatch_struct_in.valid;
        rob_entry_i.pc = dispatch_struct_in.pc;
        rob_entry_i.inst = dispatch_struct_in.inst;
        rob_entry_i.status = rob_wait;
        rob_entry_i.op_type = dispatch_struct_in.op_type;
        rob_entry_i.rd_addr = dispatch_struct_in.rd_addr;
        rob_entry_i.rd_rob_idx = tail; //dispatch_struct_in.rd_rob_idx;
        rob_entry_i.rd_valid = 1'b0;
        rob_entry_i.rs1_addr = dispatch_struct_in.rs1_addr;
        rob_entry_i.rs2_addr = dispatch_struct_in.rs2_addr;
        rob_entry_i.regf_we = dispatch_struct_in.regf_we;

        rob_entry_i.mem_rmask = dispatch_struct_in.mem_rmask;
        rob_entry_i.mem_wmask = dispatch_struct_in.mem_wmask;
        
        // if (dispatch_struct_in.valid) 
        //     current_rd_rob_idx = tail;
    end

    always_ff @(posedge clk) begin  // causes a double cycle in dispatch? rob_entry_o needs to be updated at the same cycle it is allocated in
        if (rst || cdbus.flush) begin
            head <= '0;
            tail <= '0;
            tail_addr <= 0;
            count <= '0;
            rob_table <= '{default: 0}; // ss: initialize rob_table with 0s
            debug <= '0;
            // for (integer i = 0; i < DEPTH; i++) begin
            //     rob_table[i].status = empty;
            // end
        end
        //else if (dispatch_struct_in.valid) begin
        else begin
            // Check if rd is being written back to & update it
            // Writeback:
            // set status=done, update rd_data with write result
            // if (update_i) begin
            //     rob_table[rob_addr].status <= done;
            //     rob_table[rob_addr].rd_data <= rob_entry_i.rd_data;
            // end

            for (integer unsigned i = 0; i < DEPTH; i++) begin  // Writeback rd & status update
                if(cdbus.flush) begin
                    rob_table[i].status <= done;
                    rob_table[i].valid <= '0;
                    rob_table[i].regf_we <= '0;
                end else begin
                    if (cdbus.alu_valid && (rob_table[i].rd_addr == cdbus.alu_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.alu_rob_idx)) begin
                        rob_table[i].status <= done;
                        rob_table[i].rd_data <= cdbus.alu_data;
                        rob_table[i].rd_valid <= 1'b1;

                    end                  
                    if (cdbus.mul_valid && (rob_table[i].rd_addr == cdbus.mul_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.mul_rob_idx)) begin
                        rob_table[i].status <= done;
                        rob_table[i].rd_data <= cdbus.mul_data;
                        rob_table[i].rd_valid <= 1'b1;
                    end                
                    if (cdbus.mem_valid && (rob_table[i].rd_addr == cdbus.mem_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.mem_rob_idx)) begin
                        rob_table[i].status <= done;
                        rob_table[i].rd_data <= cdbus.mem_data;
                        rob_table[i].rd_valid <= 1'b1;

                        rob_table[i].mem_addr <= cdbus.mem_addr;
                        rob_table[i].mem_rdata <= cdbus.mem_rdata;
                        rob_table[i].mem_wdata <= cdbus.mem_wdata;
                    end
                    if (cdbus.br_valid && (rob_table[i].rd_addr == cdbus.br_rd_addr) && (rob_table[i].rd_rob_idx == cdbus.br_rob_idx)) begin
                        debug <= '1;
                        rob_table[i].status <= done;
                        rob_table[i].rd_data <= cdbus.br_data;
                        rob_table[i].rd_valid <= 1'b1;
                        rob_table[i].br_en <= cdbus.br_en;
                        rob_table[i].pc_new <= cdbus.pc_new;
                    end
                end
                // if (rob_table[head].status == done) begin // Commit stage only takes one cycle for cp2. I don't know if this will change
                //     rob_table[head].status <= empty;
                // end
            end
            
            if (rob_table[head].status == done) begin
                rob_table[head].status <= donex2;
                rob_table[head].valid <= '0;
            end else if (rob_table[head].status == donex2) begin
                rob_table[head].status <= empty;
                rob_table[head].valid <= '0;
                head <= (head == DEPTH-1) ? '0 : head + 1'b1;
            end else if (rob_table[head].status == empty) begin
                head <= (head == DEPTH-1) ? '0 : head + 1'b1;
            end
            // Rename: enqueue == 1'b1
            // set v=1, status = wait
            // fill in type, rd_data, and br_pred if necessary
            // tail ++    
            
            if (insert) begin
                rob_table[tail] <= rob_entry_i;
                tail_addr <= tail;
                tail <= (tail == /*'1'*/DEPTH-1) ? '0 : tail + 1'b1;     // DEPTH-1 = 31 = 5'b11111;
            end
            
            // Commmit: dequeue == 1'b1
            // output head rd_data to update regfile
            // v=0, head ++
            // if branch mispredicted: flush all inst after it
            // if (remove) begin
            //     // rob_table[head].valid <= '0;
            //     // head <= (head == DEPTH-1) ? '0 : head + 1'b1;
            // end
            
            
            if(cdbus.flush) begin
                count <= 0;
                 head <= 0;
                 tail <= 0;
            end else begin
                case ({insert, remove})
                    2'b10: count <= count + 1'b1; 
                    2'b01: count <= count - 1'b1; 
                    default: count <= count;      
                endcase
            end

        //end
        end
   end

    // assign head_addr = head;
    assign rob_table_o = rob_table;
    // assign tail_addr = tail;

endmodule