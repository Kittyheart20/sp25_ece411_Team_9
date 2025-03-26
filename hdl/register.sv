module register #( 
    parameter LEN = 256      
)(
    input  logic clk,
    input  logic rst,
    
    input  logic [LEN-1:0] data_i,
    input  logic data_valid,
    output logic [LEN-1:0] data_o
);

    always_ff @(posedge clk) begin
        if (rst) begin
            data_o <= '0;
        end
        else begin
            if (data_valid) begin
                data_o <= data_i;
            end
        end
    end


endmodule



