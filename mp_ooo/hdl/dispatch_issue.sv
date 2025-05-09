module dispatch_issue
import rv32i_types::*;
# (
    parameter DEPTH = 5,
    parameter ROB_IDX_WIDTH = 5
)(
    input  logic        clk,
    input  logic        rst,
    // New Entry Input
    input  id_dis_stage_reg_t dispatch_struct_in,
    input  logic [4:0]  current_rd_rob_idx,

    // Updating register values
    input logic [31:0]  rs1_data_in,
    input logic         rs1_ready,
    input logic [31:0]  rs2_data_in,
    input logic         rs2_ready,
    
    input cdb cdbus,
    input logic dmem_resp,
    input rob_entry_t rob_table [32],

    input  logic [4:0] rs1_rob_idx,
    input  logic [4:0] rs2_rob_idx,
    input  logic store_no_mem,

    //output ready instructions
    output logic integer_alu_available,
    output logic mul_alu_available,
    output logic br_alu_available,
    output logic mem_available,

    output reservation_station_t next_execute_alu,
    output reservation_station_t next_execute_mult_div,
    output reservation_station_t next_execute_branch,
    output reservation_station_t next_execute_mem
);
    reservation_station_t default_reservation_station;
    assign default_reservation_station = '0;

    reservation_station_t       rs_entry;
    reservation_station_t       new_rs_entry;
    reservation_station_t       station_input[4];

    logic use_new_rs_entry;
    logic inserted;
    
    always_comb begin : fill_new_rs_entry
        new_rs_entry.valid = dispatch_struct_in.valid;
        new_rs_entry.pc = dispatch_struct_in.pc;
        new_rs_entry.order = dispatch_struct_in.order;
        new_rs_entry.inst = dispatch_struct_in.inst;
        new_rs_entry.opcode = dispatch_struct_in.opcode;
        new_rs_entry.rd_addr = dispatch_struct_in.rd_addr;
        new_rs_entry.rs1_addr = dispatch_struct_in.rs1_addr;
        new_rs_entry.rs2_addr = dispatch_struct_in.rs2_addr;

        new_rs_entry.rs1_data = 32'd0;
        new_rs_entry.rs1_ready = 1'b0;
        new_rs_entry.rs2_data = 32'd0;
        new_rs_entry.rs2_ready = 1'b0;
        new_rs_entry.imm_sext = dispatch_struct_in.imm;

        new_rs_entry.regf_we = dispatch_struct_in.regf_we;
        new_rs_entry.alu_m1_sel = dispatch_struct_in.alu_m1_sel;
        new_rs_entry.alu_m2_sel = dispatch_struct_in.alu_m2_sel;

        new_rs_entry.op_type = dispatch_struct_in.op_type;
        new_rs_entry.aluop = dispatch_struct_in.aluop;
        new_rs_entry.multop = dispatch_struct_in.multop;
        new_rs_entry.brop = dispatch_struct_in.brop;
        new_rs_entry.memop = dispatch_struct_in.memop;

        new_rs_entry.mem_rmask = dispatch_struct_in.mem_rmask;
        new_rs_entry.mem_wmask = dispatch_struct_in.mem_wmask;

        new_rs_entry.rs1_rob_idx = rs1_rob_idx;
        new_rs_entry.rs2_rob_idx = rs2_rob_idx;
        new_rs_entry.rd_rob_idx = current_rd_rob_idx;
        new_rs_entry.pc_new = 32'd0;

        new_rs_entry.status = BUSY;

        new_rs_entry.prediction = dispatch_struct_in.prediction;

        // Get rs1 rs2 data from ARF
        if (rs1_ready) begin                        
            new_rs_entry.rs1_data = rs1_data_in;
            new_rs_entry.rs1_ready = 1'b1;
        end

        if (rs2_ready) begin
            new_rs_entry.rs2_data = rs2_data_in;
            new_rs_entry.rs2_ready = 1'b1;
        end


        // Get rs1 rs2 data from ROB (Done w writeback, before commit)
        for (integer i = 0; i < 32; i++) begin
            if ((rob_table[i].rd_valid) && (rob_table[i].valid)) begin
                if ((!rs1_ready) && (rob_table[i].rd_addr == new_rs_entry.rs1_addr) && (rob_table[i].rd_rob_idx == new_rs_entry.rs1_rob_idx)) begin
                    new_rs_entry.rs1_data = rob_table[i].rd_data;
                    new_rs_entry.rs1_ready = 1'b1;
                end

                if ((!rs2_ready) && (rob_table[i].rd_addr == new_rs_entry.rs2_addr) && (rob_table[i].rd_rob_idx == new_rs_entry.rs2_rob_idx)) begin
                    new_rs_entry.rs2_data = rob_table[i].rd_data;
                    new_rs_entry.rs2_ready = 1'b1;
                end
            end
        end


        // Get rs1 rs2 data from CDB writeback
        if (!(|new_rs_entry.rs1_data)) begin
            if (cdbus.alu_valid && (new_rs_entry.rs1_addr == cdbus.alu_rd_addr) && (new_rs_entry.rs1_rob_idx == cdbus.alu_rob_idx)) begin
                new_rs_entry.rs1_data = cdbus.alu_data;
                new_rs_entry.rs1_ready = 1'b1;                
            end
            else if (cdbus.mul_valid && (new_rs_entry.rs1_addr == cdbus.mul_rd_addr) && (new_rs_entry.rs1_rob_idx == cdbus.mul_rob_idx))begin
                new_rs_entry.rs1_data = cdbus.mul_data; 
                new_rs_entry.rs1_ready = 1'b1;                         
            end
            else if (cdbus.mem_valid && (new_rs_entry.rs1_addr == cdbus.mem_rd_addr) && (new_rs_entry.rs1_rob_idx == cdbus.mem_rob_idx))begin
                new_rs_entry.rs1_data = cdbus.mem_data; 
                new_rs_entry.rs1_ready = 1'b1;                         
            end
        end
        
        if (!(|new_rs_entry.rs2_data)) begin
            if (cdbus.alu_valid && (new_rs_entry.rs2_addr == cdbus.alu_rd_addr) && (new_rs_entry.rs2_rob_idx == cdbus.alu_rob_idx)) begin
                new_rs_entry.rs2_data = cdbus.alu_data;
                new_rs_entry.rs2_ready = 1'b1;                
            end
            else if (cdbus.mul_valid && (new_rs_entry.rs2_addr == cdbus.mul_rd_addr) && (new_rs_entry.rs2_rob_idx == cdbus.mul_rob_idx))begin
                new_rs_entry.rs2_data = cdbus.mul_data; 
                new_rs_entry.rs2_ready = 1'b1;                         
            end
            else if (cdbus.mem_valid && (new_rs_entry.rs2_addr == cdbus.mem_rd_addr) && (new_rs_entry.rs2_rob_idx == cdbus.mem_rob_idx))begin
                new_rs_entry.rs2_data = cdbus.mem_data; 
                new_rs_entry.rs2_ready = 1'b1;                         
            end
        end
    end

    assign use_new_rs_entry = (dispatch_struct_in.valid && dispatch_struct_in.order != rs_entry.order);

    always_ff @(posedge clk) begin : set_rs_entry
        if (rst || cdbus.flush) begin
            rs_entry <= '1;
            inserted <= 1'b1;
        end
        else begin
            if (dispatch_struct_in.valid) begin
                if (use_new_rs_entry) begin
                    rs_entry <= new_rs_entry;
                    inserted <= 1'b0;
                end     
                else begin
                    rs_entry <= new_rs_entry;
                    rs_entry.rs1_rob_idx <= rs_entry.rs1_rob_idx;
                    rs_entry.rs2_rob_idx <= rs_entry.rs2_rob_idx;
                    if (rs_entry.rs1_ready) begin
                        rs_entry.rs1_ready <= rs_entry.rs1_ready;
                        rs_entry.rs1_data <= rs_entry.rs1_data;
                    end 
                    if (rs_entry.rs2_ready) begin
                        rs_entry.rs2_ready <= rs_entry.rs2_ready;
                        rs_entry.rs2_data <= rs_entry.rs2_data;
                    end 
                end             
            end

            unique case (dispatch_struct_in.op_type)
                alu : if (integer_alu_available) inserted <= 1'b1;
                mul : if (mul_alu_available)     inserted <= 1'b1;
                br  : if (br_alu_available)      inserted <= 1'b1;
                mem : if (mem_available)     inserted <= 1'b1;
                default : ;
            endcase   
        end
    end

    always_comb begin
        station_input = '{4{default_reservation_station}};
        
        // if (dispatch_struct_in.valid) begin : new_rs_entry_to_station
        if (!inserted || use_new_rs_entry) begin
            case (dispatch_struct_in.op_type)
                alu : station_input[0] = use_new_rs_entry ? new_rs_entry : rs_entry;
                mul : station_input[1] = use_new_rs_entry ? new_rs_entry : rs_entry;
                br  : station_input[2] = use_new_rs_entry ? new_rs_entry : rs_entry;
                mem : station_input[3] = use_new_rs_entry ? new_rs_entry : rs_entry;
                default : ;
            endcase
        end
    end


    reservation_station alu_rs (
        //.is_mem(1'b0),
        .clk(clk),
        .rst(rst),
        .new_rs_entry(station_input[0]),
        .cdbus(cdbus),
        // .dmem_resp(dmem_resp),
        .rs_available(integer_alu_available),
        .next_execute(next_execute_alu)
        // .store_no_mem(store_no_mem)
    );

    
    reservation_station mul_rs (
        //.is_mem(1'b0),
        .clk(clk),
        .rst(rst),
        .new_rs_entry(station_input[1]),
        .cdbus(cdbus),
        // .dmem_resp(dmem_resp),
        .rs_available(mul_alu_available),
        .next_execute(next_execute_mult_div)
        // .store_no_mem(store_no_mem)
    );

    reservation_station br_rs (
        //.is_mem(1'b0),
        .clk(clk),
        .rst(rst),
        .new_rs_entry(station_input[2]),
        .cdbus(cdbus),
        // .dmem_resp(dmem_resp),
        .rs_available(br_alu_available),
        .next_execute(next_execute_branch)
        // .store_no_mem(store_no_mem)
    );

    split_lsq mem_rs (
        .clk(clk),
        .rst(rst),
        .new_rs_entry(station_input[3]),
        .cdbus(cdbus),
        .dmem_resp(dmem_resp),
        .rs_available(mem_available),
        .next_execute(next_execute_mem),
        .store_no_mem(store_no_mem)
    );
    
endmodule