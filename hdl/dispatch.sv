module dispatch 
import rv32i_types::*;
(
    input  logic        clk,
    input  logic        rst,
    input  id_dis_stage_reg_t dispatch_struct_in,
    input logic [31:0]  rs1_data,
    input logic [31:0]  rs2_data,
    input logic         rs1_ready,
    input logic         rs2_ready,
    output logic station_assignment,
);

// Register Renaming -> assign a spot in ROB
// Dispatch to free corresponding reservation station
//      Reservation Station needs to hold valid bit, destination information (ROB index), control bits for execution (from decode)
//      Reservation stations need their own control bits rs1&2_ready, stats (busy/executing/free)

// We might not actually need this seperate dispatch modules we could probably handle it all in the reservation station module

endmodule