module cpu
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,	// instr addr
    output  logic   [3:0]   imem_rmask,	// instr read mask
    input   logic   [31:0]  imem_rdata,	// instr data
    input   logic           imem_resp,	// instruction data ready

    output  logic   [31:0]  dmem_addr,	// data addr
    output  logic   [3:0]   dmem_rmask,	// data read mask
    output  logic   [3:0]   dmem_wmask,	// data write mask
    input   logic   [31:0]  dmem_rdata,	// read data
    output  logic   [31:0]  dmem_wdata,	// write data
    input   logic           dmem_resp	// data ready
);


    // Pipeline Registers
    if_id_stage_reg_t    if_id_reg, if_id_reg_next;
    id_ex_stage_reg_t    id_ex_reg, id_ex_reg_next;
    ex_mem_stage_reg_t   ex_mem_reg, ex_mem_reg_next;
    mem_wb_stage_reg_t   mem_wb_reg, mem_wb_reg_next;

    // Interal Signals
    logic [31:0] pc, pc_next, next, pc_branch, prev_pc;
    logic        commit;
    logic [63:0] order;
    logic [31:0] rs1_v, rs2_v; // reg 1 & 2 output
    logic [4:0]  rs1_addr, rs2_addr;
    logic [4:0]  rd, prev_wb_rd_addr;
    logic [31:0] rd_data, prev_wb_rd_data;
    logic        regf_we;
    logic        stall;
    logic        load_use_hazard;
    logic [31:0] rdata_temp;
    logic        branch;

    logic [2:0] pending_instr_count;
    logic instruction_valid;
    assign instruction_valid = (pending_instr_count == 3'b000) && imem_resp;

    assign imem_addr = pc_next;
    assign imem_rmask = 4'b1111;
    assign commit = mem_wb_reg.valid && !rst;
   
    assign rs1_addr = if_id_reg.inst[19:15];
    assign rs2_addr = if_id_reg.inst[24:20];
    assign next = mem_wb_reg.pc + 4;

    regfile regfile(
        .clk,
        .rst,
        .regf_we,
        .rd_v(rd_data),
        .rs1_s(rs1_addr),
        .rs2_s(rs2_addr),
        .rd_s(rd),
        .rs1_v,
        .rs2_v
    );

    // Stages
    fetch_stage fetch (
	    //.clk,
	    .rst,
	    .stall,
    	.load_use_hazard,
	    .pc,
        .pc_branch,
        .branch,
    	.order,
        .instruction_valid,
	    //.imem_rmask,
    	.imem_rdata,
	    //.imem_resp,
    	.pc_next,
	    .if_id_reg_next
    );

    decode_stage decode (
        //.clk,
        .rst,
	    .stall,
        .load_use_hazard,
        .if_id_reg,
        .rs1_data(rs1_v),
        .rs2_data(rs2_v),
        .id_ex_reg_next
    );

    execute_stage execute (
        //.clk,
        .rst,
	    .stall,	
        .id_ex_reg,
	    .ex_mem_reg,
	    .mem_wb_reg,
        .mem_wb_reg_next,
        .prev_wb_rd_data,
        .prev_wb_rd_addr,
        .ex_mem_reg_next,
	    .load_use_hazard,
        .br_en(branch),
        .pc_branch
    );

    memory_stage memory (
        .clk,
        .rst,
	    .stall,
	    .dmem_rdata,
    	.dmem_wdata,
	    .dmem_resp,
        .ex_mem_reg,
        .mem_wb_reg_next
    );

    writeback_stage writeback (
        //.clk,
        .rst,
        .mem_wb_reg,
    	.rd,
	    .rd_data,
    	.regf_we
    );

    always_comb begin
        dmem_addr = '0;
        dmem_rmask = '0;
        dmem_wmask = '0;

        rdata_temp = '0;

        if (!rst) begin
            priority case (1'b1)
                    (|ex_mem_reg.mem_rmask) | (|ex_mem_reg.mem_wmask): begin
                    dmem_addr = {ex_mem_reg.mem_addr[31:2], 2'b00};
                    dmem_rmask = ex_mem_reg.mem_rmask;
                    dmem_wmask = ex_mem_reg.mem_wmask;
                end
                
                    (|ex_mem_reg_next.mem_rmask) | (|ex_mem_reg_next.mem_wmask): begin
                    dmem_addr = {ex_mem_reg_next.mem_addr[31:2], 2'b00};
                    dmem_rmask = ex_mem_reg_next.mem_rmask;
                    dmem_wmask = ex_mem_reg_next.mem_wmask;
                end

                default: begin
                    dmem_addr = '0;
                    dmem_rmask = '0;
                    dmem_wmask = '0;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            if_id_reg <= '0;
            id_ex_reg <= '0;
            ex_mem_reg <= '0;
            mem_wb_reg <= '0;
            prev_wb_rd_data <= '0;
            prev_wb_rd_addr <= '0;
        end 
	    else if (load_use_hazard && !stall) begin
            ex_mem_reg <= ex_mem_reg_next;
            mem_wb_reg <= mem_wb_reg_next;
            if (regf_we && rd != 0) begin
                prev_wb_rd_data <= rd_data;
                prev_wb_rd_addr <= rd;
            end
            //ex_mem_reg <= '0;
        end
        else if (branch && !stall) begin
            ex_mem_reg <= ex_mem_reg_next;
            mem_wb_reg <= mem_wb_reg_next;
            if (regf_we && rd != 0) begin
                prev_wb_rd_data <= rd_data;
                prev_wb_rd_addr <= rd;
            end
            if_id_reg <= '0;
            id_ex_reg <= '0;
        end
	    else if (!stall) begin
            if_id_reg <= if_id_reg_next;
            id_ex_reg <= id_ex_reg_next;
            ex_mem_reg <= ex_mem_reg_next;
            mem_wb_reg <= mem_wb_reg_next;
            if (regf_we && rd != 0) begin
                prev_wb_rd_data <= rd_data;
                prev_wb_rd_addr <= rd;
            end
        end 
    end

    logic pc_changed;
    assign pc_changed = (pc != prev_pc);

    always_ff @(posedge clk) begin
        if (rst) begin
            pending_instr_count <= 3'b000;
        end else if (!stall) begin
            case ({pc_changed, imem_resp})
                2'b10: pending_instr_count <= pending_instr_count + 3'b010;
                2'b01: if (pending_instr_count > 3'b000) begin
                    pending_instr_count <= pending_instr_count - 1'b1;
                end
                default: pending_instr_count <= pending_instr_count;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            prev_pc <= 32'haaaaa000;
        end else if (!stall) begin
            prev_pc <= pc; 
        end
    end

    // reg updates
    always_ff @(posedge clk) begin
        if (rst) begin
            pc    <= 32'haaaaa000;
            order <= '0;
        end else begin
            if (!stall) begin
                if (!load_use_hazard) begin
                    pc <= pc_next;
                    if (branch) begin
                        pc <= pc_branch;
                    end
                end
                if (commit) begin
                    order <= order + 'd1;
                end
            end
        end
    end

	logic valid;

	assign valid = stall ? 1'b0 : mem_wb_reg.valid;

endmodule : cpu

