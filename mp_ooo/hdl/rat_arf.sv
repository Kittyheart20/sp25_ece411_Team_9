module rat_arf 
import rv32i_types::*;
#(
    parameter ROB_IDX_WIDTH = 4,
    parameter TAG_WIDTH     = 3
)
(
    input   logic           clk,
    input   logic           rst,
    input   id_dis_stage_reg_t dispatch_struct_in,  // New Entry
    input   cdb             cdbus,                  // Writeback
    input   logic [ROB_IDX_WIDTH-1:0] rd_rob_idx,

    output rat_arf_entry_t rat_arf_table [32],

    // output  logic   [31:0]  data    [32],
    // output  logic           ready   [32],
    // output  logic   [4:0]   rob_idx [32],

    output  logic           rs1_rdy,
    output  logic [4:0]     rs1_rob_idx,
    output  logic           rs2_rdy,
    output  logic [4:0]     rs2_rob_idx
);


    logic   [4:0]   rs1_addr, rs2_addr, rd_addr;

    assign rs1_addr = dispatch_struct_in.rs1_addr;
    assign rs2_addr = dispatch_struct_in.rs2_addr;
    assign rd_addr = dispatch_struct_in.rd_addr;
    
    // assign rs1_rob_idx = rat_arf_table[rs1_addr].rob_idx;
    // assign rs2_rob_idx = rat_arf_table[rs2_addr].rob_idx;

    logic [4:0]   ready_count [32]; // Counter array

    always_comb begin               // reading rs1 & rs2
        rs1_rdy = rat_arf_table[rs1_addr].ready;
        rs2_rdy = rat_arf_table[rs2_addr].ready;
        rs1_rob_idx = rat_arf_table[rs1_addr].rob_idx;
        rs2_rob_idx = rat_arf_table[rs2_addr].rob_idx;
    end

    always_ff @(posedge clk) begin      // handles rd
        if (rst) begin
            for (integer i = 0; i < 32; i++) begin
                rat_arf_table[i] <= '0;
                rat_arf_table[i].ready <= '1;
                ready_count[i] <= '0;
                // second_valid <= 1'b0;
            end
        end else if(cdbus.flush) begin
            for (integer i = 0; i < 32; i++) begin
                rat_arf_table[i].ready <= '1;
                ready_count[i] <= '0;
            end
            if (cdbus.regf_we && (cdbus.commit_rd_addr != 5'd0)) begin       // Filling in rd data
                rat_arf_table[cdbus.commit_rd_addr].data <= cdbus.commit_data;
            end
        end else begin
            if (dispatch_struct_in.valid) begin                 // there is a new instruction coming in that needs to read rs1 & rs2
                // rs1_rdy <= rat_arf_table[rs1_addr].ready;
                // rs2_rdy <= rat_arf_table[rs2_addr].ready;
                // rs1_rob_idx <= rob_idx[dispatch_struct_in.rs1_addr];
                // rs2_rob_idx <= rob_idx[dispatch_struct_in.rs2_addr];
            end
            
            if (cdbus.regf_we && (cdbus.commit_rd_addr != 5'd0)) begin       // Filling in rd data
                rat_arf_table[cdbus.commit_rd_addr].data <= cdbus.commit_data;
                rat_arf_table[cdbus.commit_rd_addr].ready <= 1'b1 && (ready_count[cdbus.commit_rd_addr] < 5'd2);
                ready_count[cdbus.commit_rd_addr] <= ready_count[cdbus.commit_rd_addr] - 5'd1;
            end

            if (dispatch_struct_in.valid && (rd_addr != 5'd0)/* && dispatch_struct_in.regf_we*/) begin           // Creating a new entry   
                rat_arf_table[rd_addr].ready <= 1'b0;
                rat_arf_table[rd_addr].rob_idx <= rd_rob_idx;
                ready_count[rd_addr] <= ready_count[rd_addr] + 5'd1;
            end
            
            case ({dispatch_struct_in.valid && (rd_addr != 5'd0), cdbus.regf_we && (cdbus.commit_rd_addr != 5'd0)})
                2'b10: ready_count[rd_addr] <= ready_count[rd_addr] + 1'b1; 
                2'b01: ready_count[cdbus.commit_rd_addr] <= ready_count[cdbus.commit_rd_addr] - 1'b1; 
                2'b11: begin
                    if(cdbus.commit_rd_addr == rd_addr) begin
                        ready_count <= ready_count;
                    end else begin
                        ready_count[rd_addr] <= ready_count[rd_addr] + 1'b1; 
                        ready_count[cdbus.commit_rd_addr] <= ready_count[cdbus.commit_rd_addr] - 1'b1; 
                    end
                end
                default: ready_count <= ready_count;   

            endcase
        end

    end

endmodule