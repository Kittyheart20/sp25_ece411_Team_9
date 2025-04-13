module reservation_station
import rv32i_types::*;
# (
    parameter DEPTH = 8,
    parameter ROB_IDX_WIDTH = 5
)(
    input  logic        clk,
    input  logic        rst,
    //input  logic        we,         // write enable
    // New Entry Input
    input  id_dis_stage_reg_t dispatch_struct_in,
    input  logic [4:0]  current_rd_rob_idx,

    // Updating register values
    input logic [31:0]  rs1_data_in,
    input logic         rs1_ready,
    //input logic [4:0]   rs1_paddr_data_in,
    input logic [31:0]  rs2_data_in,
    input logic         rs2_ready,
   // input logic [4:0]   rs2_paddr_data_in,
   // input logic ready [32],
    // input logic         rs1_new,
    // input logic         rs2_new,
    input cdb cdbus,

    input  logic [4:0] rs1_rob_idx,
    input  logic [4:0] rs2_rob_idx,
    //output ready instructions
    output logic integer_alu_available,
    output logic mul_alu_available,
    // output logic branch_alu_available,
    output logic load_store_alu_available,
    // output logic mul_div_alu_available
    output reservation_station_t next_execute_alu,
    output reservation_station_t next_execute_mult_div

    //output logic valid_out
);

    reservation_station_t rs_entry [DEPTH];
    logic [ROB_IDX_WIDTH-1:0]   rob_idx [DEPTH];
    // logic [31:0]                paddr [DEPTH];
    // logic [31:0] open_station;
    // logic [31:0] open_station_mult_div;
    logic debug;
    assign debug = cdbus.mul_valid && (stations[1].rs1_ready == 0 && stations[1].rs1_addr == cdbus.mul_rd_addr);
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


    /*
        // originally
        // if (cdbus.mul_valid) begin
        //     if(stations[1].rs1_ready == 0 && stations[1].rs1_addr == cdbus.mul_rd_addr) begin
        //         stations[1].rs1_data <= cdbus.mul_data;  
        //         stations[1].rs1_ready <= 1'b1;  
        //     end else if(stations[1].rs2_ready == 0 && stations[1].rs2_addr == cdbus.mul_rd_addr) begin
        //         stations[1].rs2_data <= cdbus.mul_data; 
        //         stations[1].rs2_ready <= 1'b1; 
        //     end
            
        //     if(stations[1].valid && cdbus.mul_rob_idx == stations[1].rd_rob_idx) begin
        //         stations[1].status <= COMPLETE;
        //     end
        // end
    */

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
        else if (dispatch_struct_in.valid && dispatch_struct_in.op_type == alu) begin 
            stations[0].valid <= dispatch_struct_in.valid;
            stations[0].pc <= dispatch_struct_in.pc;
            stations[0].inst <= dispatch_struct_in.inst;
            stations[0].rd_addr <= dispatch_struct_in.rd_addr;
            stations[0].rs1_addr <= dispatch_struct_in.rs1_addr;
            stations[0].rs2_addr <= dispatch_struct_in.rs2_addr;
            stations[0].imm_sext <= dispatch_struct_in.imm;
            stations[0].regf_we <= dispatch_struct_in.regf_we;
            stations[0].alu_m1_sel <= dispatch_struct_in.alu_m1_sel;
            stations[0].alu_m2_sel <= dispatch_struct_in.alu_m2_sel;
            //stations[open_station].pc_sel <= dispatch_struct_in.pc_sel;
            stations[0].multop <= dispatch_struct_in.multop;
            stations[0].aluop <= dispatch_struct_in.aluop;
            
            // stations[0].rs1_paddr <= new_rs1_paddr;
            // stations[0].rs2_paddr <= new_rs2_paddr;
            // stations[0].rd_paddr <= new_rd_paddr;

            stations[0].rs1_rob_idx <= rs1_rob_idx;
            stations[0].rs2_rob_idx <= rs2_rob_idx;
            stations[0].rd_rob_idx <= current_rd_rob_idx;

            stations[0].rs1_ready <= 1'b0;
            stations[0].rs2_ready <= 1'b0;

            if (rs1_ready) begin                        
                stations[0].rs1_data <= rs1_data_in;
                stations[0].rs1_ready <= 1'b1;
            end else if((cdbus.commit_rd_addr == dispatch_struct_in.rs1_addr) && cdbus.regf_we) begin /*&& (cdbus.commit_rob_idx == stations[0].rs1_rob_idx)*/ 
                stations[0].rs1_data <= cdbus.commit_data; 
                stations[0].rs1_ready <= 1'b1;                         
            end

            if (rs2_ready) begin
                stations[0].rs2_data <= rs2_data_in;
                stations[0].rs2_ready <= 1'b1;
            end else if((cdbus.commit_rd_addr == dispatch_struct_in.rs2_addr) && cdbus.regf_we) begin /*&& (cdbus.commit_rob_idx == stations[0].rs1_rob_idx)*/ 
                stations[0].rs1_data <= cdbus.commit_data; 
                stations[0].rs1_ready <= 1'b1;                         
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

            stations[0].status <= BUSY;
            
        end else if (dispatch_struct_in.valid && dispatch_struct_in.op_type == mul) begin 
            stations[1].valid <= dispatch_struct_in.valid;
            stations[1].pc <= dispatch_struct_in.pc;
            stations[1].inst <= dispatch_struct_in.inst;
            stations[1].rd_addr <= dispatch_struct_in.rd_addr;
            stations[1].rs1_addr <= dispatch_struct_in.rs1_addr;
            stations[1].rs2_addr <= dispatch_struct_in.rs2_addr;
            stations[1].imm_sext <= dispatch_struct_in.imm;
            stations[1].regf_we <= dispatch_struct_in.regf_we;
            stations[1].alu_m1_sel <= dispatch_struct_in.alu_m1_sel;
            stations[1].alu_m2_sel <= dispatch_struct_in.alu_m2_sel;
            stations[1].aluop <= dispatch_struct_in.aluop;

            //stations[1].pc_sel <= dispatch_struct_in.pc_sel;
            stations[1].multop <= dispatch_struct_in.multop;
            // stations[1].rs1_paddr <= new_rs1_paddr;
            // stations[1].rs2_paddr <= new_rs2_paddr;
            // stations[1].rd_paddr <= new_rd_paddr;

            stations[1].rs1_rob_idx <= rs1_rob_idx;
            stations[1].rs2_rob_idx <= rs2_rob_idx;
            stations[1].rd_rob_idx <= current_rd_rob_idx;

            stations[1].rs1_ready <= 1'b0;
            stations[1].rs2_ready <= 1'b0;
            
            if (rs1_ready) begin                        
                stations[1].rs1_data <= rs1_data_in;
                stations[1].rs1_ready <= 1'b1;
            end else if((cdbus.commit_rd_addr == dispatch_struct_in.rs1_addr) && cdbus.regf_we) begin /*&& (cdbus.commit_rob_idx == stations[0].rs1_rob_idx)*/ 
                stations[1].rs1_data <= cdbus.commit_data; 
                stations[1].rs1_ready <= 1'b1;                         
            end
            if (rs2_ready) begin
                stations[1].rs2_data <= rs2_data_in;
                stations[1].rs2_ready <= 1'b1;
            end else if((cdbus.commit_rd_addr == dispatch_struct_in.rs2_addr) && cdbus.regf_we) begin /*&& (cdbus.commit_rob_idx == stations[0].rs1_rob_idx)*/ 
                stations[1].rs2_data <= cdbus.commit_data; 
                stations[1].rs2_ready <= 1'b1;                         
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

            stations[1].status <= BUSY;
        end
        else if (cdbus.alu_valid || cdbus.mul_valid || cdbus.regf_we) begin
            for (integer i = 0; i < 2; i++) begin
                if(stations[i].rs1_ready == 0) begin //&& stations[0].rd_rob_idx == cdbus.rob_idx) begin
                    if(cdbus.alu_valid && stations[i].rs1_addr == cdbus.alu_rd_addr)begin
                        stations[i].rs1_data <= cdbus.alu_data; 
                        stations[i].rs1_ready <= 1'b1;                         
                    end
                    else if (cdbus.mul_valid && stations[i].rs1_addr == cdbus.mul_rd_addr)begin
                        stations[i].rs1_data <= cdbus.mul_data; 
                        stations[i].rs1_ready <= 1'b1;                         
                    end
                    else if (cdbus.regf_we && stations[i].rs1_addr == cdbus.commit_rd_addr)begin
                        stations[i].rs1_data <= cdbus.commit_data; 
                        stations[i].rs1_ready <= 1'b1;                         
                    end
                end 
                
                if(stations[i].rs2_ready == 0) begin/*&& stations[i].rs2_addr == cdbus.alu_rd_addr */ //&& stations[0].rd_rob_idx == cdbus.rob_idx) begin
                    //stations[0].rs2_data <= cdbus.alu_data; 
                    if(cdbus.alu_valid && stations[i].rs2_addr == cdbus.alu_rd_addr) begin
                        stations[i].rs2_data <= cdbus.alu_data; 
                        stations[i].rs2_ready <= 1'b1;                         
                    end
                    else if (cdbus.mul_valid && stations[i].rs2_addr == cdbus.mul_rd_addr)begin
                        stations[i].rs2_data <= cdbus.mul_data; 
                        stations[i].rs2_ready <= 1'b1;                         
                    end
                    else if(cdbus.regf_we && stations[i].rs2_addr == cdbus.commit_rd_addr)begin
                        stations[i].rs2_data <= cdbus.commit_data; 
                        stations[i].rs2_ready <= 1'b1;                         
                    end
                end

                if (cdbus.alu_rob_idx == stations[i].rd_rob_idx  && cdbus.alu_valid  ) begin
                    stations[i].status <= COMPLETE;                         // This complete will move on to the next instruction even if next instruction should be busy
                end     
                else if  (cdbus.mul_rob_idx == stations[i].rd_rob_idx  && cdbus.mul_valid ) begin
                    stations[i].status <= COMPLETE;                         // This complete will move on to the next instruction even if next instruction should be busy
                end                
            end

        end

    
        /*if(cdbus.alu_valid) begin
            if(stations[0].rs1_ready == 0 && stations[0].rs1_addr == cdbus.alu_rd_addr) begin //&& stations[0].rd_rob_idx == cdbus.rob_idx) begin
                stations[0].rs1_data <= cdbus.alu_data;  
                stations[0].rs1_ready <= 1'b1;  
            end else if(stations[0].rs2_ready == 0 && stations[0].rs2_addr == cdbus.alu_rd_addr) begin //&& stations[0].rd_rob_idx == cdbus.rob_idx) begin
                stations[0].rs2_data <= cdbus.alu_data; 
                stations[0].rs2_ready <= 1'b1; 
            end

            if(cdbus.alu_rob_idx == stations[0].rd_rob_idx) begin
                stations[0].status <= COMPLETE;                         // This complete will move on to the next instruction even if next instruction should be busy
            end 
        end

        if (cdbus.mul_valid) begin
            if(stations[1].rs1_ready == 0 && stations[1].rs1_addr == cdbus.mul_rd_addr) begin
                stations[1].rs1_data <= cdbus.mul_data;  
                stations[1].rs1_ready <= 1'b1;  
            end else if(stations[1].rs2_ready == 0 && stations[1].rs2_addr == cdbus.mul_rd_addr) begin
                stations[1].rs2_data <= cdbus.mul_data; 
                stations[1].rs2_ready <= 1'b1; 
            end
            
            if(stations[1].valid && cdbus.mul_rob_idx == stations[1].rd_rob_idx) begin
                stations[1].status <= COMPLETE;
            end
        end*/

    end

    always_comb begin
        if ((stations[0].status == IDLE) || (stations[0].status == COMPLETE)) begin
            integer_alu_available = 1;
        end else begin
            integer_alu_available = 0;
        end
        
        if ((stations[1].status == IDLE) || (stations[1].status == COMPLETE)) begin
            mul_alu_available = 1;
        end else begin
            mul_alu_available = 0;
        end
        // end else if((stations[1].status == IDLE) || (stations[1].status == COMPLETE)) begin
        //     open_station = 1;
        //     integer_alu_available = 1;
    end

    always_comb begin
        next_execute_alu = '0;
        next_execute_mult_div = '0;

        if (stations[0].valid && stations[0].rs1_ready && stations[0].rs2_ready) begin
            next_execute_alu = stations[0];
        end
        if (stations[1].valid && stations[1].rs1_ready && stations[1].rs2_ready) begin
            next_execute_mult_div = stations[1];
        end
    end
    
endmodule