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
    input  logic [4:0]  current_rd_rob_idx,
    input  [31:0]  new_rs1_paddr,
    input  [31:0]  new_rs2_paddr,
    input  [31:0]  new_rd_paddr,

    // Updating register values
    input logic [31:0]  rs1_data_in,
    input logic         rs1_ready,
    input logic [4:0]   rs1_paddr_data_in,
    input logic [31:0]  rs2_data_in,
    input logic         rs2_ready,
    input logic [4:0]   rs2_paddr_data_in,
    input logic         rs1_new,
    input logic         rs2_new,
    input cdb cdbus,
    //output ready instructions
    output logic integer_alu_available,
    // output logic branch_alu_available,
    output logic load_store_alu_available,
    // output logic mul_div_alu_available
    output reservation_station_t next_execute,
    output logic valid_out
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
        else if (dispatch_struct_in.valid) begin 
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

            stations[open_station].rs1_rob_idx <= dispatch_struct_in.rs1_rob_idx;
            stations[open_station].rs2_rob_idx <= dispatch_struct_in.rs2_rob_idx;
            stations[open_station].rd_rob_idx <= current_rd_rob_idx;

            stations[open_station].rs1_ready <= 1'b0;
            stations[open_station].rs2_ready <= 1'b0;
            if (rs1_ready) begin                        
                stations[open_station].rs1_data <= rs1_data_in;
                stations[open_station].rs1_ready <= 1'b1;
            end
            if (rs2_ready) begin
                stations[open_station].rs2_data <= rs2_data_in;
                stations[open_station].rs2_ready <= 1'b1;
            end

            // This will only check if rs1 & rs2 are ready when instuction is first assigned to reservation station
            // We also need to check if the bus will update with the corresponding updated values if it is not ready on the first try
            
            // if (new_rs1_paddr == rs1_paddr_data_in) begin
            //     stations[open_station].rs1_data <= rs1_data_in;
            //     stations[open_station].rs1_ready <= 1'b1;
            // end
            // else 
            //     stations[open_station].rs1_ready <= 1'b0;

            // if (new_rs2_paddr == rs2_paddr_data_in) begin
            //     stations[open_station].rs2_data <= rs2_data_in;
            //     stations[open_station].rs2_ready <= 1'b1;
            // end
            // else 
            //     stations[open_station].rs2_ready <= 1'b0;

            stations[open_station].status <= BUSY;
        end

        if(cdbus.valid) begin
            if(stations[0].rs1_ready == 0 && stations[0].rs1_addr == cdbus.rd_addr /*&& stations[0].rd_rob_idx == cdbus.rob_idx*/) begin
                stations[0].rs1_data <= cdbus.data;  
                stations[0].rs1_ready <= 1'b1;  
            end else if(stations[0].rs2_ready == 0 && stations[0].rs2_addr == cdbus.rd_addr /*&& stations[0].rd_rob_idx == cdbus.rob_idx*/) begin
                stations[0].rs2_data <= cdbus.data; 
                stations[0].rs2_ready <= 1'b1; 
            end

            if(stations[1].rs1_ready == 0 && stations[1].rs1_addr == cdbus.rd_addr /*&& stations[0].rd_rob_idx == cdbus.rob_idx*/) begin
                stations[1].rs1_data <= cdbus.data;  
                stations[1].rs1_ready <= 1'b1;  
            end else if(stations[1].rs2_ready == 0 && stations[1].rs2_addr == cdbus.rd_addr /*&& stations[0].rd_rob_idx == cdbus.rob_idx*/) begin
                stations[1].rs2_data <= cdbus.data; 
                stations[1].rs2_ready <= 1'b1; 
            end

            if(cdbus.rob_idx == stations[0].rd_rob_idx) begin
                stations[0].status <= COMPLETE;
            end else if(cdbus.rob_idx == stations[1].rd_rob_idx) begin
                stations[1].status <= COMPLETE;
            end
        end
    end

    always_comb begin
        if((stations[0].status == IDLE) || (stations[0].status == COMPLETE)) begin
            open_station = 0;
            integer_alu_available = 1;
        // end else if((stations[1].status == IDLE) || (stations[1].status == COMPLETE)) begin
        //     open_station = 1;
        //     integer_alu_available = 1;
        end else begin
            open_station = '0;
            integer_alu_available = 0;
        end
    end

    always_comb begin
        // stations[0].valid = 1'b0;
        // stations[1].valid = 1'b0;
        if(rst)
            next_execute = '0;
        else if (stations[0].valid && stations[0].rs1_ready && stations[0].rs2_ready) begin
            next_execute = stations[0];
        end
        else next_execute = '0;
    end
    
endmodule