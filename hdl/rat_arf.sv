module rat_arf 
import rv32i_types::*;
#(
    parameter ROB_IDX_WIDTH = 5,
    parameter TAG_WIDTH     = 3
)
(
    input   logic           clk,
    input   logic           rst,
    // New Entry
    input id_dis_stage_reg_t dispatch_struct_in,
    //input   logic           new_entry,
    // Writeback
    input cdb               cdbus,
    //input logic   [31:0]    rd_data,
    input logic   [4:0]     rd_wb_addr,
    input logic [ROB_IDX_WIDTH-1:0] rd_rob_idx,
    //input logic             regf_we,
    //input   logic           free_entry,

    // Read logic
    output  logic   [31:0]  data    [32],
    //output  logic           rs1_renamed, rs2_renamed,
    output  logic           ready   [32],
    output  logic   [4:0]   rob_idx [32],
    output  logic           rs1_rdy,
    output  logic           rs2_rdy
);

    logic   [31:0]            data    [32];
    //logic   [31:0]            tags    [32];     // I think the tags should be the same as the ROB idx
    //logic                     renamed [32];     
    logic                     ready   [32];
    logic [ROB_IDX_WIDTH-1:0] rob_idx [32];

    //logic curr_regf_we;
    logic   [4:0]   rs1_addr, rs2_addr, rd_wb_addr;
    //assign regf_we = '0;//dispatch_struct_in.regf_we;
    assign rs1_addr = dispatch_struct_in.rs1_addr;
    assign rs2_addr = dispatch_struct_in.rs2_addr;
    logic [4:0] rd_addr;
    assign rd_addr = dispatch_struct_in.rd_addr;

    logic [31:0] prev_pc; 
    
    always_ff @(posedge clk) begin      // handles rd
        if (rst) begin
            prev_pc <= '0;
            for (integer i = 0; i < 32; i++) begin
                data[i] <= '0;
                //tags[i] <= 'x;
                //renamed[i] <= 1'b0;
                rob_idx[i] <= '0;
                ready[i] <= 1'b1;
                // Have everything start empty
            end
        end else begin
        //  if (cdbus.valid && (cdbus.rd_addr != 5'd0) && (rob_idx[cdbus.rd_addr] == rd_rob_idx)) begin       // Filling in rd data // we should check for commit in writeback?
            if (dispatch_struct_in.valid) begin
                rs1_rdy = ready[dispatch_struct_in.rs1_addr];
                rs2_rdy = ready[dispatch_struct_in.rs1_addr];
            end
            
            if (cdbus.regf_we && (cdbus.commit_rd_addr != 5'd0)) begin       // Filling in rd data
                data[cdbus.commit_rd_addr] <= cdbus.commit_data;   // might have to change
                ready[cdbus.commit_rd_addr] <= 1'b1;
                prev_pc <= dispatch_struct_in.pc;

                if (dispatch_struct_in.valid) begin
                    rs1_rdy = ready[dispatch_struct_in.rs1_addr];
                    rs2_rdy = ready[dispatch_struct_in.rs1_addr];
                end
            end else if (dispatch_struct_in.valid && (rd_addr != 5'd0) && (dispatch_struct_in.pc != prev_pc)) begin           // Creating a new entry   
               // if (dispatch_struct_in.valid && (rd_addr != 5'd0) && (rd_addr != cdbus.commit_rd_addr)) begin
                    ready[rd_addr] <= 1'b0; // will have an error for cp3 because we never mark the second r# register as unready
            end
        end




            
            if (dispatch_struct_in.valid && (rd_addr != 5'd0)) begin           // Creating a new entry   
                rob_idx[rd_addr] <= rd_rob_idx;
                // ready[rd_addr] <= 1'b0;
            end

            // else if (free_entry) begin
                // is this needed?
            // end            
        

    end

endmodule