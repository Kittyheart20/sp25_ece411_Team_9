module rat_arf #(
    parameter ROB_IDX_WIDTH = 5,
    parameter TAG_WIDTH     = 3
)
(
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we,
    input   logic   [31:0]  rd_data,
    input   logic   [4:0]   rs1_addr, rs2_addr, rd_wb_addr, rd_finished_addr,
    input   logic   [4:0]   rs1_paddr, rs2_paddr, rd_wb_paddr,
    input   logic           new_entry,
    input   logic           free_entry,

    //input   logic           assign_paddr,
    //input   logic   [4:0]   rd_paddr_i,
    input logic [ROB_IDX_WIDTH-1:0]     rd_rob_idx,

    output  logic   [31:0]  rs1_data, rs2_data,
    output  logic           rs1_renamed, rs2_renamed,
    output  logic           rs1_ready, rs2_ready,
    output  logic   [4:0]   rs1_rob_idx, rs2_rob_idx
);

    logic   [31:0]            data    [32];
    logic   [31:0]            paddr   [32];     
    logic                     renamed [32];
    logic                     ready   [32];
    logic [ROB_IDX_WIDTH-1:0] rob_idx [32];
    logic   [4:0]             free_paddr;           // We can probably make this into a stack

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < 32; i++) begin
                data[i] <= '0;
                paddr[i] <= 'x;
                renamed[i] <= 1'b0;
                rob_idx[i] <= '0;
                ready[i] <= 1'b1;
                // Have the free addr stack be full of ready paddr tags
            end
        
        end else if (regf_we && (rd_wb_addr != 5'd0) && (paddr[rd_wb_addr] == rd_wb_paddr)) begin   
            data[rd_wb_addr] <= rd_data;
            ready[rd_wb_addr] <= 1'b1;

        end else if (/*assign_paddr*/new_entry) begin           
            rob_idx[rd_wb_addr] <= rd_rob_idx;
            paddr[rd_wb_addr] <= free_paddr; 
            // and pop entry from free entry stack
            renamed[rd_wb_addr] <= 1'b1;
            ready[rd_wb_addr] <= 1'b0;

        end else if (free_entry) begin
            // add entry into free entry stack
        end
    end

    always_ff @(posedge clk) begin
        rs1_data <= '0;
        rs2_data <= '0;

        if (rst) begin
            rs1_data <= 'x;
            rs2_data <= 'x;

            rs1_renamed <= 1'b0;
            rs2_renamed <= 1'b0;
            rs1_rob_idx <= '0;
            rs2_rob_idx <= '0;
        end
        else begin
            rs1_ready <= ready[rs1_addr];
            rs1_rob_idx <= rob_idx[rs1_addr];
            if ((rs1_addr != 5'd0) && (paddr[rs1_addr] == rs1_paddr))
                rs1_data <= data[rs1_addr];

            rs2_ready <= ready[rs2_addr];
            rs2_rob_idx <= rob_idx[rs2_addr];
            if ((rs2_addr != 5'd0) && (paddr[rs2_addr] == rs2_paddr))
                rs2_data <= data[rs2_addr];

            rs1_renamed <= renamed[rs1_addr];
            rs2_renamed <= renamed[rs2_addr];
        end
    end

    // assign rs1_data = ((rs1_addr != 5'd0) && ~rst) ? data[rs1_addr] : '0;
    // assign rs2_data = ((rs2_addr != 5'd0) && ~rst) ? data[rs2_addr] : '0;

endmodule