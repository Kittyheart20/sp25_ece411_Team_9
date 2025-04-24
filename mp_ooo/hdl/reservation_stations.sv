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
    // input logic [4:0]   rs1_paddr_data_in,
    input logic [31:0]  rs2_data_in,
    input logic         rs2_ready,
    
    input cdb cdbus,
    input rob_entry_t rob_table [32],

    input  logic [4:0] rs1_rob_idx,
    input  logic [4:0] rs2_rob_idx,
    // input  logic [4:0] head_addr,
    //output ready instructions
    output logic integer_alu_available,
    output logic mul_alu_available,
    output logic br_alu_available,

    // output logic branch_alu_available,
    // output logic mem_alu_available,
    output reservation_station_t next_execute_alu,
    output reservation_station_t next_execute_mult_div,
    output reservation_station_t next_execute_branch
    // output reservation_station_t next_execute_mem,

    // output logic valid_out
);

    //reservation_station_t rs_entry [DEPTH];
    reservation_station_t new_rs_entry;
    logic [ROB_IDX_WIDTH-1:0]   rob_idx [DEPTH];
    logic debug;
    assign debug = cdbus.mul_valid && (stations[1].rs1_ready == 0 && stations[1].rs1_addr == cdbus.mul_rd_addr);
    reservation_station_t stations[5];
    logic[31:0] debug_1, debug_2;

    logic update;
    assign cdb_update = (cdbus.alu_valid || cdbus.mul_valid || cdbus.regf_we);

    logic [31:0] debug_array;

    // logic update_rs1_ready;
    // logic[31:0] update_rs1_data;
    // logic update_rs2_ready;
    // logic[31:0] update_rs2_data;
    // logic[31:0] rs1_ready_pc;    
    // logic [31:0] prev_pc;
    // logic update_rs1_ready_prev;
    // logic rs1_ready_prev;
    // logic rs2_ready_prev;
    // logic [4:0] rs1_rob_idx_prev;
    // logic [4:0] rs2_rob_idx_prev;

    // always_ff @(posedge clk) begin
    //     rs1_rob_idx_prev <= rs1_rob_idx;
    //     rs2_rob_idx_prev <= rs2_rob_idx;

    //     if(update_rs2_ready) begin
    //  //       new_rs_entry.rs2_ready <= 1'b1;
    //  //       new_rs_entry.rs2_data <= update_rs2_data;
    //     end
    //     if(rst) begin 
    //         prev_pc <= 0;
    //         update_rs1_ready_prev <= 0;
    //        // update_rs1_ready <= 0;
    //     end
    //     else begin 
    //         prev_pc <= dispatch_struct_in.pc;
    //         if (update_rs1_ready_prev) begin
    //             rs1_ready_pc <= new_rs_entry.pc;
    //         end 
    //     end
    //     update_rs1_ready_prev <= update_rs1_ready;
    // end
    
    
    always_comb begin
            debug_array = '0;
            new_rs_entry = '0;

            new_rs_entry.valid = dispatch_struct_in.valid;
            new_rs_entry.pc = dispatch_struct_in.pc;
            new_rs_entry.inst = dispatch_struct_in.inst;
            new_rs_entry.rd_addr = dispatch_struct_in.rd_addr;
            new_rs_entry.rs1_addr = dispatch_struct_in.rs1_addr;
            new_rs_entry.rs2_addr = dispatch_struct_in.rs2_addr;
            new_rs_entry.imm_sext = dispatch_struct_in.imm;
            new_rs_entry.regf_we = dispatch_struct_in.regf_we;
            new_rs_entry.alu_m1_sel = dispatch_struct_in.alu_m1_sel;
            new_rs_entry.alu_m2_sel = dispatch_struct_in.alu_m2_sel;
            // new_rs_entry.pc_sel = dispatch_struct_in.pc_sel;

            new_rs_entry.aluop = dispatch_struct_in.aluop;
            new_rs_entry.multop = dispatch_struct_in.multop;
            new_rs_entry.brop = dispatch_struct_in.brop;
            //new_rs_entry.memop = dispatch_struct_in.memop;
            //new_rs_entry.mem_rmask = dispatch_struct_in.mem_rmask;
            //new_rs_entry.mem_wmask = dispatch_struct_in.mem_wmask;

            new_rs_entry.rs1_rob_idx = rs1_rob_idx;
            new_rs_entry.rs2_rob_idx = rs2_rob_idx;
            new_rs_entry.rd_rob_idx = current_rd_rob_idx;

            new_rs_entry.opcode = dispatch_struct_in.opcode;

            // new_rs_entry.rs1_data = 1'b0;
            // new_rs_entry.rs2_data = 1'b0;
           // if(prev_pc == dispatch_struct_in.pc && (!())) begin
              
           // end 
            new_rs_entry.rs1_ready = 1'b0 /*|| (rs1_ready_pc == dispatch_struct_in.pc)*/;
            new_rs_entry.rs2_ready = 1'b0 /*|| (rs1_ready_pc == dispatch_struct_in.pc)*/;
            //  update_rs1_ready = 0;
            // update_rs2_ready = 0;
            // update_rs1_data = 0;
            // update_rs2_data = 0;
            

            if (rs1_ready) begin                        
                new_rs_entry.rs1_data = rs1_data_in;
                new_rs_entry.rs1_ready = 1'b1;
            //  update_rs1_ready = 1'b1;
                //update_rs1_data = rs1_data_in;
            end // else if((cdbus.commit_rd_addr == dispatch_struct_in.rs1_addr) && cdbus.regf_we) begin /*&& (cdbus.commit_rob_idx == stations[0].rs1_rob_idx)*/ 
            //     new_rs_entry.rs1_data = cdbus.commit_data; 
            //     new_rs_entry.rs1_ready = 1'b1;                         
            // end

            if (rs2_ready) begin
                new_rs_entry.rs2_data = rs2_data_in;
                new_rs_entry.rs2_ready = 1'b1;
            // update_rs2_ready = 1'b1;
            // update_rs2_data = rs2_data_in;
            end // else if((cdbus.commit_rd_addr == dispatch_struct_in.rs2_addr) && cdbus.regf_we) begin /*&& (cdbus.commit_rob_idx == stations[0].rs2_rob_idx)*/ 
            //     new_rs_entry.rs2_data = cdbus.commit_data; 
            //     new_rs_entry.rs2_ready = 1'b1;                         
            // end

            new_rs_entry.status = BUSY;
            
            for (integer i = 0; i < 32; i++) begin
                if ((rob_table[i].rd_valid) && (rob_table[i].valid)) begin
                    if ((!rs1_ready) && (rob_table[i].rd_addr == new_rs_entry.rs1_addr) && (rob_table[i].rd_rob_idx == new_rs_entry.rs1_rob_idx)) begin //&& (rob_table[i].rd_rob_idx == new_rs_entry.rs1_rob_idx)
                        new_rs_entry.rs1_data = rob_table[i].rd_data;
                        new_rs_entry.rs1_ready = 1'b1;
                    end

                if( (!rs2_ready) && (rob_table[i].rd_addr == new_rs_entry.rs2_addr) && (rob_table[i].rd_rob_idx == new_rs_entry.rs2_rob_idx)) begin // && (rob_table[i].rd_rob_idx == new_rs_entry.rs2_rob_idx) // && (rob_table[i].rd_rob_idx == ((rs2_rob_idx == 31) ? '0 : rs2_rob_idx + 1'b1) )
                        new_rs_entry.rs2_data = rob_table[i].rd_data;
                        new_rs_entry.rs2_ready = 1'b1;
                    end

                end
            end

            debug_1 = 9999;
            debug_2 = 9999;
            for (integer i = 0 ; i < 32; i++) begin
            //  if ((rob_table[i].rd_valid) && (rob_table[i].valid)) begin
                    if ((!rs1_ready) && (rob_table[i].rd_addr == new_rs_entry.rs1_addr) && rob_table[i].valid && rob_table[i].rd_valid) begin
                        debug_array[i] = 1;
                        debug_1 = i;
                    end
                    // else if (cdbus.alu_valid && (new_rs_entry.rs1_addr == cdbus.alu_rd_addr)) begin
                    // end

                    if ((!rs2_ready) && (rob_table[i].rd_addr == new_rs_entry.rs2_addr) && rob_table[i].valid && rob_table[i].rd_valid) begin
                        debug_2 = i;
                    end
            //   end
            end

   //     end
    end

    logic debug_status, debug_3;
    assign debug_status = (cdbus.br_rob_idx == stations[2].rd_rob_idx  && cdbus.br_valid);
    always_ff @(posedge clk) begin

        if (rst || cdbus.flush) begin
            stations <= '{default: '0};     // ss: initialize with 0s -- status and valid will be automatically set
            debug_3 <= '0;
        end
        
        else if (dispatch_struct_in.valid) begin        // creates new entry
            case (dispatch_struct_in.op_type)
                alu:   stations[0] <= new_rs_entry;
                mul:   stations[1] <= new_rs_entry;
                br:  stations[2] <= new_rs_entry;
                //mem: stations[3] <= new_rs_entry;
                default: ;
            endcase
        end

        else if (cdb_update) begin                  // updates rs1 and rs2 according to the writeback cdbus
            for (integer i = 0; i < 3; i++) begin
                if (stations[i].rs1_ready == 0) begin 
                    if(cdbus.alu_valid && (stations[i].rs1_addr == cdbus.alu_rd_addr) && (stations[i].rs1_rob_idx == cdbus.alu_rob_idx))begin
                        stations[i].rs1_data <= cdbus.alu_data; 
                        stations[i].rs1_ready <= 1'b1;                         
                    end
                    else if (cdbus.mul_valid && (stations[i].rs1_addr == cdbus.mul_rd_addr) && (stations[i].rs1_rob_idx == cdbus.mul_rob_idx))begin
                        stations[i].rs1_data <= cdbus.mul_data; 
                        stations[i].rs1_ready <= 1'b1;                         
                    end
                    // else if (cdbus.regf_we && (stations[i].rs1_addr == cdbus.commit_rd_addr)/* && (stations[i].rs1_rob_idx == cdbus.commit_rob_idx)*/)begin
                    //     stations[i].rs1_data <= cdbus.commit_data; 
                    //     stations[i].rs1_ready <= 1'b1;                         
                    // end
                end 
                
                if (stations[i].rs2_ready == 0) begin
                    if(cdbus.alu_valid && (stations[i].rs2_addr == cdbus.alu_rd_addr) && (stations[i].rs2_rob_idx == cdbus.alu_rob_idx)) begin
                        stations[i].rs2_data <= cdbus.alu_data; 
                        stations[i].rs2_ready <= 1'b1;                         
                    end
                    else if (cdbus.mul_valid && (stations[i].rs2_addr == cdbus.mul_rd_addr) && (stations[i].rs2_rob_idx == cdbus.mul_rob_idx))begin 
                        stations[i].rs2_data <= cdbus.mul_data; 
                        stations[i].rs2_ready <= 1'b1;                         
                    end
                    // else if(cdbus.regf_we && (stations[i].rs2_addr == cdbus.commit_rd_addr)/* && (stations[i].rs2_rob_idx == cdbus.commit_rob_idx)*/)begin
                    //     stations[i].rs2_data <= cdbus.commit_data; 
                    //     stations[i].rs2_ready <= 1'b1;                         
                    // end
                end

                if (cdbus.alu_rob_idx == stations[i].rd_rob_idx  && cdbus.alu_valid  ) begin
                    stations[i].status <= COMPLETE;                         // This complete will move on to the next instruction even if next instruction should be busy
                 //   stations[i].valid <= 1'b0;
                end     
                else if  (cdbus.mul_rob_idx == stations[i].rd_rob_idx  && cdbus.mul_valid ) begin
                    stations[i].status <= COMPLETE;                         // This complete will move on to the next instruction even if next instruction should be busy
                 //   stations[i].valid <= 1'b0;
                end      
                else if  (cdbus.br_rob_idx == stations[i].rd_rob_idx  && cdbus.br_valid ) begin
                    stations[i].status <= COMPLETE;
                    debug_3 <= '1;                         // This complete will move on to the next instruction even if next instruction should be busy
                 //   stations[i].valid <= 1'b0;
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

        // if ((stations[2].status == IDLE) || (stations[2].status == COMPLETE)) begin
        //     branch_alu_available = 1'b1;
        // end else begin
        //     branch_alu_available = 1'b0;
        // end

        // if ((stations[3].status == IDLE) || (stations[3].status == COMPLETE)) begin
        //     mem_alu_available = 1'b1;
        // end else begin
        //     mem_alu_available = 1'b0;
        // end
    end

    always_comb begin
        next_execute_alu = '0;
        next_execute_mult_div = '0;
        next_execute_branch = '0;
        // next_execute_mem = '0;

        if (stations[0].valid && stations[0].rs1_ready && stations[0].rs2_ready) begin
            next_execute_alu = stations[0];
        end
        if (stations[1].valid && stations[1].rs1_ready && stations[1].rs2_ready) begin
            next_execute_mult_div = stations[1];
        end
        if (stations[2].valid && stations[2].rs1_ready && stations[2].rs2_ready) begin
            next_execute_branch = stations[2];
        end
        // if (stations[3].valid && stations[3].rs1_ready && stations[3].rs2_ready) begin
        //     next_execute_mem = stations[3];
        // end
    end
    
endmodule