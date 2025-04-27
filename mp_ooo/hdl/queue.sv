module queue #(
    parameter WIDTH = 32,    
    parameter DEPTH = 8      
)(
    input  logic clk,
    input  logic rst,
    
    
    input  logic [WIDTH-1:0] data_i,
    input  logic enqueue_i,
    input  logic flush,
    output logic full_o,
    
    
    output logic [WIDTH-1:0] data_o,
    input  logic dequeue_i,
    output logic empty_o
);

    
    localparam PTR_WIDTH = $clog2(DEPTH);

    
    logic [WIDTH-1:0] data [DEPTH-1:0];
    // logic [PTR_WIDTH-1:0] head, tail;
    // logic [PTR_WIDTH:0] count; 
    logic [31:0] head, tail, count; 
    
    
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
            if (flush) begin
                head <= '0;
                tail <= '0;
                count <= '0;  
                data <= '{default: 0};
            end else begin

                if (enqueue_i && (!full_o || dequeue_i)) begin
                    data[tail] <= data_i;
                    tail <= tail == $unsigned((DEPTH-1)) ? 32'd0 : tail + 32'd1;
                end
                
                
                if (dequeue_i && !empty_o) begin
                    head <= (head == $unsigned(DEPTH-1)) ? 32'd0 : head + 32'd1;
                end
                
                
                case ({enqueue_i && (!full_o || dequeue_i), dequeue_i && !empty_o})
                    2'b10: count <= count + 1'b1; 
                    2'b01: count <= count - 1'b1; 
                    default: count <= count;      
                endcase
            end
        end
    end

endmodule
