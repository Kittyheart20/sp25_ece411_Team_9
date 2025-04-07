import rv32i_types::*;

module rob #(
    parameter DEPTH = 32
) (
    ports
    //input rob_entry; // Create a type for this in types
    //input entry_flag // indicates to store new entry
    // 
    input   logic [PTR_WIDTH-1:0] rob_addr,  // = paddr in rat arf
    
    input   logic [WIDTH-1:0]     data_i,    // must contain all info for regs below
    input   logic enqueue_i,
    input   logic dequeue_i,

    output  logic [PTR_WIDTH-1:0] head_addr,
    output  logic [PTR_WIDTH-1:0] tail_addr,

);
    localparam PTR_WIDTH = $clog2(DEPTH);

    logic    [DEPTH-1:0] valid;
    status_t [DEPTH-1:0] status;
    type_t   [DEPTH-1:0] inst_type;
    logic    [PTR_WIDTH-1:0]    rd_data [DEPTH];
    logic    [DEPTH-1:0] br_pred;
    logic    [DEPTH-1:0] br_result;


endmodule