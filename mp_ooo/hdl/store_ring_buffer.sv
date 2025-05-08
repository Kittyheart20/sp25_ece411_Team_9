module store_ring_buffer 
import rv32i_types::*;

#(
    parameter DEPTH = 8      
)(
    input  logic clk,
    input  logic rst,
    
    
    input  store_buffer_entry data_i,
    input  logic enqueue_i,
    input  logic flush,
    output logic full_o,
    
    
    output store_buffer_entry data_o,
    output store_buffer_entry data [DEPTH-1:0],
    input  logic dequeue_i,
    output logic empty_o
);

    
    localparam PTR_WIDTH = $clog2(DEPTH);

    
    // store_buffer_entry data [DEPTH-1:0];
    // logic [PTR_WIDTH-1:0] head, tail;
    // logic [PTR_WIDTH:0] count; 
    logic [31:0] head, tail, count; 
    
    
    assign empty_o = (count == 0);
    assign full_o = (count == DEPTH);
    assign data_o = data[head];
    
    logic addr_in_buffer;
    logic [PTR_WIDTH-1:0] index_match;
    store_buffer_entry merged_entry;
    logic [31:0] wmask_expanded;
    store_buffer_entry existing_entry;

    always_comb begin
        addr_in_buffer = 1'b0;
        index_match = '0;
        merged_entry = '0;
        
        for(integer unsigned i  = 0; i < DEPTH; i++) begin
            if (data[i].valid && (data[i].addr == data_i.addr)) begin
                addr_in_buffer = 1'b1;
                index_match = PTR_WIDTH'(i);


                existing_entry = data[i];

                wmask_expanded = 32'b0;
                for (integer unsigned j = 0; j < 4; j++) begin
                    if (data_i.wmask[j]) begin
                        wmask_expanded[(j*8) +: 8] = 8'hFF;
                    end
                end

                merged_entry.wdata = (data_i.wdata & wmask_expanded) | (existing_entry.wdata & ~wmask_expanded);

                merged_entry.wmask = existing_entry.wmask | data_i.wmask;

                merged_entry.valid = data_i.valid; 
                merged_entry.addr  = data_i.addr;  
                break; 
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            head <= '0;
            tail <= '0;
            count <= '0;
            data <= '{default: 0};
        end
        else begin
            if (flush) begin
                head <= '0;
                tail <= '0;
                count <= '0;  
                data <= '{default: 0};
            end else begin

                if (enqueue_i && (!full_o || dequeue_i || addr_in_buffer)) begin
                    if(addr_in_buffer) begin
                        data[index_match] <= merged_entry;
                    end else begin
                        data[tail] <= data_i;
                        tail <= tail == $unsigned((DEPTH-1)) ? 32'd0 : tail + 32'd1;
                    end
                end
                
                
                if (dequeue_i && !empty_o) begin
                    head <= (head == $unsigned(DEPTH-1)) ? 32'd0 : head + 32'd1;
                   // if(!(enqueue_i && (!full_o || dequeue_i))) data[head].valid <= 1'b0; 
                   //data[head].addr <= '0;
                end
                
                
                case ({enqueue_i && (!full_o || dequeue_i), dequeue_i && !empty_o, addr_in_buffer})
                    3'b100: count <= count + 1'b1; 
                    3'b010: count <= count - 1'b1; 
                    3'b110: count <= count; 
                    3'b101: count <= count; 
                    3'b011: count <= count - 1'b1; 
                    3'b111: count <= count - 1'b1;            
                    default: count <= count;      
                endcase
            end
        end
    end

endmodule
