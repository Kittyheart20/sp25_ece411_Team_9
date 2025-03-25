module memory_stage 
import rv32i_types::*;
(
    input  logic        clk,
    input  logic        rst,
    output logic       stall,
    input  logic [31:0] dmem_rdata,
    output logic [31:0] dmem_wdata,
    input  logic        dmem_resp,
    input  ex_mem_stage_reg_t ex_mem_reg,
    output mem_wb_stage_reg_t  mem_wb_reg_next
);


/*    typedef enum logic [1:0] {
        mem_idle,
        mem_progress
    } mem_state_t;*/


    logic [31:0] rd_v;

    logic [1:0]  byte_offset;
    assign byte_offset = ex_mem_reg.mem_addr[1:0];
    logic mem_op_in_progress;

    assign stall = (ex_mem_reg.valid && (ex_mem_reg.load || |ex_mem_reg.mem_wmask) && !dmem_resp) || 
               (mem_op_in_progress && !dmem_resp);

    always_ff @(posedge clk) begin
        if (rst) begin
            mem_op_in_progress <= 1'b0;
        end 
        else begin
            if (ex_mem_reg.valid && (ex_mem_reg.load || |ex_mem_reg.mem_wmask) && !dmem_resp) begin
                // Start tracking a new memory operation
                mem_op_in_progress <= 1'b1;
            end else if (dmem_resp) begin
                // Memory response received, operation complete
                mem_op_in_progress <= 1'b0;
            end
        end
    end

/*    mem_state_t mem_state, mem_state_next;
    assign stall = (ex_mem_reg.valid && (ex_mem_reg.load || |ex_mem_reg.mem_wmask) && (mem_state_next == mem_progress));

    always_comb begin
        mem_state_next = mem_state;
    
        case (mem_state)
            mem_idle: begin
                if (ex_mem_reg.valid && (ex_mem_reg.load || |ex_mem_reg.mem_wmask)) begin
                    mem_state_next = mem_progress;
                end
            end
            mem_progress: begin
                if (dmem_resp) begin
                    mem_state_next = mem_idle;
                end
            end
            default: mem_state_next = mem_idle;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mem_state <= mem_idle;
        end else begin
            mem_state <= mem_state_next;
        end
    end*/

//    always_comb begin
//         if (rst)
//             stall = 1'b0;
//         else
//             stall = (ex_mem_reg.valid && (ex_mem_reg.load || |ex_mem_reg.mem_wmask) && !dmem_resp);
//     end

    always_comb begin
        mem_wb_reg_next = '0;
        mem_wb_reg_next.valid = 1'b0;
        dmem_wdata = '0;
        rd_v = '0;

        if (ex_mem_reg.valid && !rst) begin

	        mem_wb_reg_next.inst = ex_mem_reg.inst;
            mem_wb_reg_next.pc = ex_mem_reg.pc;
            mem_wb_reg_next.pc_next = ex_mem_reg.pc_next;
            mem_wb_reg_next.order = ex_mem_reg.order;
            mem_wb_reg_next.valid = ex_mem_reg.valid;

            mem_wb_reg_next.rd = ex_mem_reg.rd;
            mem_wb_reg_next.rs1_addr = ex_mem_reg.rs1_addr;
            mem_wb_reg_next.rs2_addr = ex_mem_reg.rs2_addr;
            mem_wb_reg_next.rs1_data = ex_mem_reg.rs1_data;
            mem_wb_reg_next.rs2_data = ex_mem_reg.rs2_data;
	        mem_wb_reg_next.mem_addr = ex_mem_reg.mem_addr;

            mem_wb_reg_next.regf_we = ex_mem_reg.regf_we;
            mem_wb_reg_next.rd_data = ex_mem_reg.aluout;
            mem_wb_reg_next.mem_rmask = ex_mem_reg.mem_rmask;
            mem_wb_reg_next.mem_wmask = ex_mem_reg.mem_wmask;

            // loads and stores
            if (ex_mem_reg.load) begin	// load
                rd_v = '0;
                mem_wb_reg_next.rd_data = '0;
                mem_wb_reg_next.mem_rdata = '0;
                if (dmem_resp) begin
                    unique case (ex_mem_reg.memop)
                        mem_op_none: rd_v = '0;
                        mem_op_bu: begin
                            unique case (byte_offset)
                                2'b00: rd_v = {24'b0, dmem_rdata[7:0]};
                                2'b01: rd_v = {24'b0, dmem_rdata[15:8]};
                                2'b10: rd_v = {24'b0, dmem_rdata[23:16]};
                                2'b11: rd_v = {24'b0, dmem_rdata[31:24]};
                            endcase
                        end
                        mem_op_b: begin
                            unique case (byte_offset)
                                2'b00: rd_v = {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
                                2'b01: rd_v = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                                2'b10: rd_v = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                                2'b11: rd_v = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
                            endcase
                        end
                        mem_op_hu: begin
                            unique case (byte_offset[1])
                                1'b0: rd_v = {16'b0, dmem_rdata[15:0]};
                                1'b1: rd_v = {16'b0, dmem_rdata[31:16]};
                            endcase
                        end
                        mem_op_h: begin
                            unique case (byte_offset[1])
                                1'b0: rd_v = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                                1'b1: rd_v = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
                            endcase
                        end
                        mem_op_w : rd_v = dmem_rdata;
                        default  : rd_v = ex_mem_reg.aluout;
                    endcase
                    mem_wb_reg_next.rd_data = rd_v;
                    mem_wb_reg_next.mem_rdata = dmem_rdata | 32'b0;
                end 
            end
            else if (ex_mem_reg.regf_we) begin
                mem_wb_reg_next.rd_data = ex_mem_reg.aluout;
            end
            if (ex_mem_reg.mem_wmask > 0) begin	// store
                unique case (ex_mem_reg.memop)
                    mem_op_b: begin
                        unique case (byte_offset)
                            2'b00: dmem_wdata = {24'b0, ex_mem_reg.rs2_data[7:0]};
                            2'b01: dmem_wdata = {16'b0, ex_mem_reg.rs2_data[7:0], 8'b0};
                            2'b10: dmem_wdata = {8'b0, ex_mem_reg.rs2_data[7:0], 16'b0};
                            2'b11: dmem_wdata = {ex_mem_reg.rs2_data[7:0], 24'b0};
                        endcase
                    end
                    mem_op_h: begin
                        unique case (byte_offset[1])
                            1'b0: dmem_wdata = {16'b0, ex_mem_reg.rs2_data[15:0]};
                            1'b1: dmem_wdata = {ex_mem_reg.rs2_data[15:0], 16'b0};
                        endcase
                    end
                    mem_op_w: dmem_wdata = ex_mem_reg.rs2_data;
                    default : dmem_wdata = '0;
                endcase
            mem_wb_reg_next.mem_wdata = dmem_wdata;
            mem_wb_reg_next.rd = '0;
            end
        end
    end

endmodule
