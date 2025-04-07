module rat_arf
(
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we,
    input   logic   [31:0]  rd_data,
    input   logic   [4:0]   rs1_addr, rs2_addr, rd_wb_addr,

    input   logic           assign_paddr,
    input   logic   [4:0]   rd_paddr_i,

    output  logic   [31:0]  rs1_data, rs2_data,
    output  logic           rs1_renamed, rs2_renamed,
    output  logic   [4:0]   rs1_paddr_o, rs2_paddr_o
);

    logic   [31:0]  data [32];

    logic   [31:0]  renamed;
    logic   [4:0]   paddr [32];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < 32; i++) begin
                data[i] <= '0;

                renamed[i] <= 1'b0;
                paddr[i] <= '0;
            end
        
        end else if (regf_we && (rd_wb_addr != 5'd0)) begin
            data[rd_wb_addr] <= rd_data;
        
        end else if (assign_paddr) begin
            paddr[rd_data] <= rd_paddr_i;
            renamed[rd_data] <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rs1_data <= 'x;
            rs2_data <= 'x;

            rs1_renamed <= 1'b0;
            rs2_renamed <= 1'b0;
            rs1_paddr_o <= '0;
            rs2_paddr_o <= '0;
        end else begin
            rs1_data <= (rs1_addr != 5'd0) ? data[rs1_addr] : '0;
            rs2_data <= (rs2_addr != 5'd0) ? data[rs2_addr] : '0;

            rs1_renamed <= renamed[rs1_addr];
            rs2_renamed <= renamed[rs2_addr];
            rs1_paddr_o <= paddr[rs1_addr];
            rs2_paddr_o <= paddr[rs2_addr];
        end
    end

    // assign rs1_data = ((rs1_addr != 5'd0) && ~rst) ? data[rs1_addr] : '0;
    // assign rs2_data = ((rs2_addr != 5'd0) && ~rst) ? data[rs2_addr] : '0;

endmodule