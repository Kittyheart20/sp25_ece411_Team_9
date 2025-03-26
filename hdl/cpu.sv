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
        
        .ufp_addr(ufp_addr),
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



endmodule : cpu
