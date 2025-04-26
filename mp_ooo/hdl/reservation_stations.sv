module reservation_station
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
    // input  logic [4:0] head_addr,

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

    always_comb begin: default_values
        default_reservation_station = '0;
    end

    reservation_station_t       new_rs_entry;
    logic [ROB_IDX_WIDTH-1:0]   rob_idx [DEPTH];
    reservation_station_t       stations[5];
    logic cdb_update;

    assign cdb_update = (cdbus.alu_valid || cdbus.mul_valid || cdbus.br_valid || cdbus.mem_valid || cdbus.regf_we);
    
    always_comb begin : fill_new_rs_entry
        new_rs_entry.valid = dispatch_struct_in.valid;
        new_rs_entry.pc = dispatch_struct_in.pc;
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

        // Get rs1 rs2 data from ARF
        if (rs1_ready) begin                        
            new_rs_entry.rs1_data = rs1_data_in;
            new_rs_entry.rs1_ready = 1'b1;
        end

        if (rs2_ready) begin
            new_rs_entry.rs2_data = rs2_data_in;
            new_rs_entry.rs2_ready = 1'b1;
        end

        // Get rs1 rs2 data from ROB
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
    end


    always_ff @(posedge clk) begin

        if (rst || cdbus.flush) begin
            stations <= '{5{default_reservation_station}};
        end
        
        else if (dispatch_struct_in.valid) begin : new_rs_entry_to_station
            case (dispatch_struct_in.op_type)
                alu : stations[0] <= new_rs_entry;
                mul : stations[1] <= new_rs_entry;
                br  : stations[2] <= new_rs_entry;
                mem : stations[3] <= new_rs_entry;
                default : ;
            endcase

            // if (dispatch_struct_in.op_type != none)  // ss: same functionality
            //     stations[dispatch_struct_in.op_type] <= new_rs_entry;
        end

        if (cdb_update) begin : update_from_writeback
            for (integer i = 0; i < 4; i++) begin
                if (!(dispatch_struct_in.valid && dispatch_struct_in.op_type == types_t'(i)) ) begin
                    if (stations[i].rs1_ready == 1'b0) begin 
                        if(cdbus.alu_valid && (stations[i].rs1_addr == cdbus.alu_rd_addr) && (stations[i].rs1_rob_idx == cdbus.alu_rob_idx))begin
                            stations[i].rs1_data <= cdbus.alu_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (stations[i].rs1_addr == cdbus.mul_rd_addr) && (stations[i].rs1_rob_idx == cdbus.mul_rob_idx))begin
                            stations[i].rs1_data <= cdbus.mul_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && (stations[i].rs1_addr == cdbus.mem_rd_addr) && (stations[i].rs1_rob_idx == cdbus.mem_rob_idx))begin
                            stations[i].rs1_data <= cdbus.mem_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                    end 
                    
                    if (stations[i].rs2_ready == 1'b0) begin
                        if(cdbus.alu_valid && (stations[i].rs2_addr == cdbus.alu_rd_addr) && (stations[i].rs2_rob_idx == cdbus.alu_rob_idx)) begin
                            stations[i].rs2_data <= cdbus.alu_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (stations[i].rs2_addr == cdbus.mul_rd_addr) && (stations[i].rs2_rob_idx == cdbus.mul_rob_idx))begin 
                            stations[i].rs2_data <= cdbus.mul_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && (stations[i].rs2_addr == cdbus.mem_rd_addr) && (stations[i].rs2_rob_idx == cdbus.mem_rob_idx))begin
                            stations[i].rs2_data <= cdbus.mem_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                    end

                    if (cdbus.alu_rob_idx == stations[i].rd_rob_idx  && cdbus.alu_valid) begin
                        stations[i].status <= COMPLETE;
                    end     
                    else if  (cdbus.mul_rob_idx == stations[i].rd_rob_idx  && cdbus.mul_valid) begin
                        stations[i].status <= COMPLETE;                         
                    end      
                    else if  (cdbus.br_rob_idx == stations[i].rd_rob_idx  && cdbus.br_valid) begin
                        stations[i].status <= COMPLETE;                
                    end            
                    else if  (cdbus.mem_rob_idx == stations[i].rd_rob_idx  && cdbus.mem_valid && (|stations[i].mem_rmask) ) begin
                        stations[i].status <= COMPLETE;
                    end 
                    else if  (cdbus.commit_rob_idx == stations[i].rd_rob_idx && cdbus.regf_we && (|stations[i].mem_wmask) ) begin
                        stations[i].status <= WAIT_STORE;
                    end 
                    else if  ((stations[i].status == WAIT_STORE) && dmem_resp ) begin
                        stations[i].status <= COMPLETE;
                    end
                end
                else begin
                    if (new_rs_entry.rs1_ready == 0) begin 
                        if(cdbus.alu_valid && (new_rs_entry.rs1_addr == cdbus.alu_rd_addr) && (new_rs_entry.rs1_rob_idx == cdbus.alu_rob_idx))begin
                            stations[i].rs1_data <= cdbus.alu_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (new_rs_entry.rs1_addr == cdbus.mul_rd_addr) && (new_rs_entry.rs1_rob_idx == cdbus.mul_rob_idx))begin
                            stations[i].rs1_data <= cdbus.mul_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && (new_rs_entry.rs1_addr == cdbus.mem_rd_addr) && (new_rs_entry.rs1_rob_idx == cdbus.mem_rob_idx))begin
                            stations[i].rs1_data <= cdbus.mem_data; 
                            stations[i].rs1_ready <= 1'b1;                         
                        end
                    end 
                    
                    if (new_rs_entry.rs2_ready == 0) begin
                        if(cdbus.alu_valid && (new_rs_entry.rs2_addr == cdbus.alu_rd_addr) && (new_rs_entry.rs2_rob_idx == cdbus.alu_rob_idx)) begin
                            stations[i].rs2_data <= cdbus.alu_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mul_valid && (new_rs_entry.rs2_addr == cdbus.mul_rd_addr) && (new_rs_entry.rs2_rob_idx == cdbus.mul_rob_idx))begin 
                            stations[i].rs2_data <= cdbus.mul_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                        else if (cdbus.mem_valid && (new_rs_entry.rs2_addr == cdbus.mem_rd_addr) && (new_rs_entry.rs2_rob_idx == cdbus.mem_rob_idx))begin
                            stations[i].rs2_data <= cdbus.mem_data; 
                            stations[i].rs2_ready <= 1'b1;                         
                        end
                    end

                    if (cdbus.alu_rob_idx == new_rs_entry.rd_rob_idx  && cdbus.alu_valid  ) begin
                        stations[i].status <= COMPLETE;                         // This complete will move on to the next instruction even if next instruction should be busy
                    end     
                    else if  (cdbus.mul_rob_idx == new_rs_entry.rd_rob_idx  && cdbus.mul_valid ) begin
                        stations[i].status <= COMPLETE;                         
                    end      
                    else if  (cdbus.br_rob_idx == new_rs_entry.rd_rob_idx  && cdbus.br_valid ) begin
                        stations[i].status <= COMPLETE;             
                    end            
                    else if  (cdbus.mem_rob_idx == new_rs_entry.rd_rob_idx  && cdbus.mem_valid && (|new_rs_entry.mem_rmask) ) begin
                        stations[i].status <= COMPLETE;
                    end else if  (cdbus.commit_rob_idx == new_rs_entry.rd_rob_idx && cdbus.regf_we && (|new_rs_entry.mem_wmask) ) begin
                        stations[i].status <= WAIT_STORE;
                    end else if  ((new_rs_entry.status == WAIT_STORE) && dmem_resp ) begin
                        stations[i].status <= COMPLETE;
                    end
                end
            end
        end
    end

    always_comb begin
        if ((stations[0].status == IDLE) || (stations[0].status == COMPLETE)) begin
            integer_alu_available = 1'b1;
        end else begin
            integer_alu_available = 1'b0;
        end

        if ((stations[1].status == IDLE) || (stations[1].status == COMPLETE)) begin
            mul_alu_available = 1'b1;
        end else begin
            mul_alu_available = 1'b0;
        end

        if ((stations[2].status == IDLE) || (stations[2].status == COMPLETE)) begin
            br_alu_available = 1'b1;
        end else begin
            br_alu_available = 1'b0;
        end

        if ((stations[3].status == IDLE) || (stations[3].status == COMPLETE)) begin
            mem_available = 1'b1;
        end else begin
            mem_available = 1'b0;
        end
    end

    always_comb begin
        next_execute_alu = '0;
        next_execute_mult_div = '0;
        next_execute_branch = '0;
        next_execute_mem = '0;

        if (stations[0].valid && stations[0].rs1_ready && stations[0].rs2_ready) begin
            next_execute_alu = stations[0];
        end
        if (stations[1].valid && stations[1].rs1_ready && stations[1].rs2_ready) begin
            next_execute_mult_div = stations[1];
        end
        if (stations[2].valid && stations[2].rs1_ready && stations[2].rs2_ready) begin
            next_execute_branch = stations[2];
        end
        if (stations[3].valid && stations[3].rs1_ready && stations[3].rs2_ready) begin
            next_execute_mem = stations[3];
        end
    end
    
endmodule