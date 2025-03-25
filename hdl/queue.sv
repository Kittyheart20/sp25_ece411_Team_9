module queue #(
    parameter WIDTH = 32,    
    parameter DEPTH = 8      
)(
    input  logic clk,
    input  logic rst,
    
    
    input  logic [WIDTH-1:0] data_i,
    input  logic enqueue_i,
    output logic full_o,
    
    
    output logic [WIDTH-1:0] data_o,
    input  logic dequeue_i,
    output logic empty_o
);

    
    localparam PTR_WIDTH = $clog2(DEPTH);

    
    logic [WIDTH-1:0] data [DEPTH-1:0];
    logic [PTR_WIDTH-1:0] head, tail;
    logic [PTR_WIDTH:0] count; 
    
    
    assign empty_o = (count == 0);
    assign full_o = (count == DEPTH);
    assign data_o = data[head];
    
    
    always_ff @(posedge clk) begin
        if (rst) begin
            head <= '0;
            tail <= '0;
            count <= '0;
        end
        else begin
            
            if (enqueue_i && (!full_o || dequeue_i)) begin
                data[tail] <= data_i;
                tail <= (tail == DEPTH-1) ? '0 : tail + 1'b1;
            end
            
            
            if (dequeue_i && !empty_o) begin
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
