module reservation_station
import rv32i_types::*;
# (
    parameter DEPTH = 8,
    parameter ROB_IDX_WIDTH = 5
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        we,         // write enable
    // New Entry Input
    input  id_dis_stage_reg_t dispatch_struct_in,
    input  [31:0]  new_rs1_paddr,
    input  [31:0]  new_rs2_paddr,
    input  [31:0]  new_rd_paddr,

    // Updating register values
    input logic [31:0]  rs1_data_in,
    input logic [4:0]   rs1_paddr_data_in,
    input logic [31:0]  rs2_data_in,
    input logic [4:0]   rs2_paddr_data_in,
    input logic         rs1_new,
    input logic         rs2_new,
    //output ready instructions
    output logic integer_alu_available,
    // output logic branch_alu_available,
    output logic load_store_alu_available
    // output logic mul_div_alu_available
);

    reservation_station_t rs_entry [DEPTH];
    logic [ROB_IDX_WIDTH-1:0] rob_idx [DEPTH];
    logic [31:0]                paddr [DEPTH];
    logic [31:0] open_station;
    reservation_station_t stations[5];
    // We probably want a stack here indicating what entries are free
    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         stations[0].status = IDLE;
    //         stations[0].valid = 1'b0;
    //         stations[1].status = IDLE;
    //         stations[1].valid = 1'b0;
    //     end
    // end
    always_ff @(posedge clk) begin
        if (rst) begin
            stations[0].status <= IDLE;
            stations[0].valid <= 1'b0;
            stations[1].status <= IDLE;
            stations[1].valid <= 1'b0;
            stations[2].status <= IDLE;
            stations[2].valid <= 1'b0;
            stations[3].status <= IDLE;
            stations[3].valid <= 1'b0;
            stations[4].status <= IDLE;
            stations[4].valid <= 1'b0;
        end
        else if (we) begin 
            stations[open_station].valid <= dispatch_struct_in.valid;
            stations[open_station].pc <= dispatch_struct_in.pc;
            stations[open_station].rd_addr <= dispatch_struct_in.rd_addr;
            stations[open_station].rs1_addr <= dispatch_struct_in.rs1_addr;
            stations[open_station].rs2_addr <= dispatch_struct_in.rs2_addr;
            stations[open_station].imm_sext <= dispatch_struct_in.imm;
            stations[open_station].regf_we <= dispatch_struct_in.regf_we;
            stations[open_station].alu_m1_sel <= dispatch_struct_in.alu_m1_sel;
            stations[open_station].alu_m2_sel <= dispatch_struct_in.alu_m2_sel;
            //stations[open_station].pc_sel <= dispatch_struct_in.pc_sel;
            stations[open_station].aluop <= dispatch_struct_in.aluop;
            stations[open_station].rs1_paddr <= new_rs1_paddr;
            stations[open_station].rs2_paddr <= new_rs2_paddr;
            stations[open_station].rd_paddr <= new_rd_paddr;
            if (new_rs1_paddr == rs1_paddr_data_in) begin
                stations[open_station].rs1_data <= rs1_data_in;
                stations[open_station].rs1_ready <= 1'b1;
            end
            else 
                stations[open_station].rs1_ready <= 1'b0;

            if (new_rs2_paddr == rs2_paddr_data_in) begin
                stations[open_station].rs2_data <= rs2_data_in;
                stations[open_station].rs2_ready <= 1'b1;
            end
            else 
                stations[open_station].rs2_ready <= 1'b0;

            stations[open_station].status <= 1;
        end
    end

    always_comb begin
        if((stations[0].status == IDLE) || (stations[0].status == COMPLETE)) begin
            open_station = 0;
            integer_alu_available = 1;
        end else if((stations[1].status == IDLE) || (stations[1].status == COMPLETE)) begin
            open_station = 1;
            integer_alu_available = 1;
        end else begin
            open_station = '0;
        end
    end
    
endmodule