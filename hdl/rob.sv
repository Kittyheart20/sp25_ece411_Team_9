module rob 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input   logic [4:0] rob_addr,
    input   rob_entry_t rob_entry_i,
    output  rob_entry_t rob_entry_o,

    input   logic       enqueue_i,
    input   logic       update_i,
    input   logic       dequeue_i,

    output  logic [4:0] head_addr,
    output  logic [4:0] tail_addr
    
);
    localparam DEPTH = 32;

    rob_entry_t rob_table [DEPTH];

    logic [4:0] head, tail, count; 
    logic       empty_o, full_o;
    
    assign empty_o = (count == 0);
    assign full_o = (count == DEPTH);
    assign rob_entry_o = rob_table[head];
    
    always_ff @(posedge clk) begin
        if (rst) begin
            head <= '0;
            tail <= '0;
            count <= '0;
        end
        else begin

            // Rename: enqueue == 1'b1
            // set v=1, status = wait
            // fill in type, rd_data, and br_pred if necessary
            // tail_addr ++    
            if (enqueue_i && (!full_o || dequeue_i)) begin
                rob_table[tail] <= rob_entry_i;
                tail <= (tail == DEPTH-1) ? '0 : tail + 1'b1;
            end
            
            // Writeback: update == 1'b1
            // set status=done, update rd_data with write result
            if (update_i) begin
                rob_table[rob_addr].status <= done;
                rob_table[rob_addr].rd_data <= rob_entry_i.rd_data;
            end
            
            // Commmit: dequeue == 1'b1
            // output head rd_data to update regfile
            // v=0, head_addr ++
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

endmodule