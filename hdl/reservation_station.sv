module reservation_station
import rv32i_types::*;
(
    input  logic        clk,
    input  logic        rst,
    input  id_dis_stage_reg_t dispatch_struct_in,
    input logic [31:0]  rs1_data_in,
    input logic [31:0]  rs2_data_in,
    input logic         rs1_new,
    input logic         rs2_new,
);

    logic valid;
    logic [31:0]    pc;
    logic [4:0]     rd_addr, rs1_addr, rs2_addr;
    logic [31:0]    rs1_data, rs2_data;
    logic           rs1_ready, rs2_ready;
    logic [1:0]     state; // idle, in execution, free
    logic rob_idx; // size TBH
    logic tag;     // size TBH

    // Control Signals
    // logic               regf_we;  This one should be an ROB signal
    alu_m1_sel_t    alu_m1_sel;
    alu_m2_sel_t    alu_m2_sel;
    pc_sel_t        pc_sel;
    alu_ops		    aluop;

endmodule