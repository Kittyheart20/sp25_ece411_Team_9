module cpu
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid
);

    logic [31:0] pc, pc_next, next, pc_branch, prev_pc;
    logic   inst_cache_hit;

    // Instr Queue
    logic full_o;
    logic [31:0] data_i, data_o;

    deserializer cache_line_adapter (
        .clk        (clk),
        .rst        (rst),
        .bmem_ready (bmem_ready),
        .bmem_raddr (bmem_raddr),
        .bmem_rdata (bmem_rdata),
        .bmem_rvalid(bmem_rvalid),
        .dfp_wdata(dfp_wdata),
        .dfp_write(dfp_write),
        .dfp_rdata  (dfp_rdata),
        .dfp_resp   (dfp_resp),
        .bmem_wdata(bmem_wdata)
    );

    cache instruction_cache (
        .clk(clk),
        .rst (rst),
        
        .ufp_addr(pc),  //.ufp_addr(ufp_addr),
        .ufp_rmask(ufp_rmask),
        .ufp_wmask(ufp_wmask),
        .ufp_rdata(ufp_rdata),
        .ufp_wdata(ufp_wdata),
        .ufp_resp(ufp_resp),

        .dfp_addr(dfp_addr),
        .dfp_read(dfp_read),
        .dfp_write(dfp_write),
        .dfp_rdata(dfp_rdata),
        .dfp_wdata(dfp_wdata),
        .dfp_resp(dfp_resp)
    );


    cache data_cache (
        .clk        (clk),
        .rst        (rst),
        .ufp_addr   (),
        .ufp_rmask  (),
        .ufp_wmask  (),
        .ufp_rdata  (),
        .ufp_wdata  (),
        .ufp_resp   (),
        .dfp_addr   (),
        .dfp_read   (),
        .dfp_write  (),
        .dfp_rdata  (),
        .dfp_wdata  (),
        .dfp_resp   ()
    );

    localparam WIDTH = 32;
    localparam DEPTH = 32;
    localparam LEN = 32;
    queue #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) instruction_queue (
        .clk(clk),
        .rst(rst),
        .data_i(data_i),
        .enqueue_i(enqueue_i),
        .full_o(full_o),
        .data_o(data_o),
        .dequeue_i(dequeue_i),
        .empty_o(empty_o)
    );

    assign bmem_addr = 32'hAAAAA000;
    assign bmem_read = 1;
    assign bmem_write = 0;
    assign bmem_wdata = 0;


    logic [255:0] line_buffer_i;
    logic line_buffer_valid;
    logic [255:0] line_buffer_o;

    register #(
        .LEN(LEN)
    ) line_buffer (
        .clk(clk),
        .rst(rst),
        .data_i(line_buffer_i),
        .data_valid(line_buffer_valid),
        .data_o(line_buffer_o)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            pc    <= 32'haaaaa000;
            order <= '0;
        end else if (ufp_resp && ufp_rmask && !full_o) begin   // fetch
            data_i = ufp_rdata;
            enqueue_i = 1'b1;
            pc_next = pc_next + 'd4;
        end
        else begin
            pc <= pc_next;
            if (commit)
                order <= order + 'd1;
        end
    end
    


    localparam RS_DEPTH = 3;
    localparam RS_ALU_WIDTH = 0; // valid(1) + inst decoding() + rs1(32) + rs1_ready(1) + rs2/imm(32) + rs2_ready(1) + rd_paddr(6?)
    queue rs_alu #(
        WIDTH = 
    )(
        .clk(clk),
        .rst(rst),
        .data_i(rs_alu_input),
        .enqueue_i(rs_alu_enqueue),
        .full_o(rs_alu_full),
        .data_o(rs_alu_output),
        .dequeue_i(rs_alu_dequeue),
        .empty_o(rs_alu_empty)
    );

    queue rs_br (
        .clk(clk),
        .rst(rst),
        .data_i(rs_br_input),
        .enqueue_i(rs_br_enqueue),
        .full_o(rs_br_full),
        .data_o(rs_br_output),
        .dequeue_i(rs_br_dequeue),
        .empty_o(rs_br_empty)
    );

    queue rs_mem (
        .clk(clk),
        .rst(rst),
        .data_i(rs_mem_input),
        .enqueue_i(rs_mem_enqueue),
        .full_o(rs_mem_full),
        .data_o(rs_mem_output),
        .dequeue_i(rs_mem_dequeue),
        .empty_o(rs_mem_empty)
    );

endmodule : cpu
