module register #( 
    parameter A_LEN = 256,
    parameter B_LEN = 32      
      
)(
    input  logic clk,
    input  logic rst,
    
    input  logic [A_LEN-1:0] data_a_input,
    input  logic [B_LEN-1:0] data_b_input,
    input  logic data_valid,
    output logic [A_LEN-1:0] data_a_output,
    output logic [B_LEN-1:0] data_b_output

);

    always_ff @(posedge clk) begin
        if (rst) begin
            data_a_output <= '0;
            data_b_output <= '0;
        end
        else begin
            if (data_valid) begin
                data_a_output <= data_a_input;
                data_b_output <= data_b_input;
            end
        end
    end


endmodule



