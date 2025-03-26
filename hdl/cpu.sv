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

    // cache cache (
    //     .clk(clk),
    //     .rst(rst),

    // input   logic   [31:0]  ufp_addr,
    // input   logic   [3:0]   ufp_rmask,
    // input   logic   [3:0]   ufp_wmask,
    // output  logic   [31:0]  ufp_rdata,
    // input   logic   [31:0]  ufp_wdata,
    // output  logic           ufp_resp,

    
    // .dfp_addr(),
    // output  logic           dfp_read,
    // output  logic           dfp_write,
    // input   logic   [255:0] dfp_rdata,
    // output  logic   [255:0] dfp_wdata,
    // input   logic           dfp_resp
    // );

    assign bmem_addr = 32'hAAAAA000;
    assign bmem_read = 1;
    assign bmem_write = 0;
    assign bmem_wdata = 0;

    logic [255:0] line_buffer;


endmodule : cpu
