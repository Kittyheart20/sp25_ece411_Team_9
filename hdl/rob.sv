module rob 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input   logic [4:0] rob_addr,
    input id_dis_stage_reg_t dispatch_struct_in,
    //input   rob_entry_t rob_entry_i,
    output  rob_entry_t rob_entry_o,

    input   logic       enqueue_i,  // Do we need this? We can just use dispatch_struct_in.valid
    input   logic       update_i,
    input   logic       dequeue_i,
    input cdb cdbus,

    output  logic [4:0] head_addr,
    output  logic [4:0] tail_addr,
    output logic full_o // if full we need to stall
);
    localparam DEPTH = 32;

    rob_entry_t rob_table [DEPTH];
    rob_entry_t rob_entry_i;

    logic [4:0]  head, tail;
    logic [31:0] count; 
    logic        empty_o;//, full_o;
    
    assign empty_o = (count == '0);
    assign full_o = (count == DEPTH);
    assign rob_entry_o = rob_table[head];

    always_comb begin
        //rob_entry_i = dispatch_struct_in;
        rob_entry_i.valid = dispatch_struct_in.valid;
        rob_entry_i.status = rob_wait;
        //rob_entry_i.op_type = ; maybe we should add in op_type to id_dis_stage_reg_t from decode stage
        rob_entry_i.rd_addr = dispatch_struct_in.rd_addr;
        rob_entry_i.rd_rob_idx = dispatch_struct_in.rd_rob_idx;
        rob_entry_i.rd_data = 'x;

        for (int i = 0; i < DEPTH; i++) begin
            if ((rob_table[i].rd_addr == cdb.rd_addr) && (rob_table[i].rd_rob_idx == cdb.rob_idx))
                rob_table[i].status = done;
                rob_entry_i.rd_data = cdb.data;
        end
    end

    always_ff @(posedge clk) begin  // If we make this always_ff- we can't also do the rat_arf in the same cycle? (we need the new ROB tail addr)
        if (rst) begin
            head <= '0;
            tail <= '0;
            count <= '0;
        end
        else begin

            // Rename: enqueue == 1'b1
            // set v=1, status = wait
            // fill in type, rd_data, and br_pred if necessary
            // tail ++    
            if (enqueue_i && (!full_o || dequeue_i)) begin
                rob_table[tail] <= rob_entry_i;
                tail <= tail;
                tail <= (tail == '1) ? '0 : tail + 1'b1;     // DEPTH-1 = 31 = 5'b11111;
            end
            
            // Writeback: update == 1'b1
            // set status=done, update rd_data with write result
            if (update_i) begin
                rob_table[rob_addr].status <= done;
                rob_table[rob_addr].rd_data <= rob_entry_i.rd_data;
            end
            
            // Commmit: dequeue == 1'b1
            // output head rd_data to update regfile
            // v=0, head ++
            // if branch mispredicted: flush all inst after it

            if (dequeue_i && !empty_o) begin
                rob_table[head].valid <= '0;
                head <= (head == DEPTH-1) ? '0 : head + 1'b1;
            end
            
            
            case ({enqueue_i && (!full_o || dequeue_i), dequeue_i && !empty_o})
                2'b10: count <= count + 1'b1; 
                2'b01: count <= count - 1'b1; 
                default: count <= count;      
            endcase
        end
    end

    assign head_addr = head;
    assign tail_addr = tail;

endmodule