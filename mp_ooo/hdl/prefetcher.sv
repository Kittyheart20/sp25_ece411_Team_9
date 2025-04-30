module prefetcher (
    input   logic           clk,
    input   logic           rst,
    
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    output  logic   [255:0] ufp_rcache_line,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);
    logic[31:0] ufp_rdata_internal; 
    logic[255:0] ufp_rcache_line_internal; 

    logic ufp_resp_internal;
    logic[31:0] ufp_addr_internal;
    logic[3:0] ufp_rmask_internal;

    logic second_fetch;
    always_ff @(posedge clk) begin
        if(rst) second_fetch = 1'b0;
        if(ufp_resp_internal && (second_fetch == 1'b0)) begin
             second_fetch <= 1'b1;
        end else if (ufp_resp_internal) second_fetch <= 1'b0;
    end

    always_comb begin
        if(second_fetch == 1) begin
            ufp_resp = ufp_resp_internal;
            ufp_addr_internal = ufp_addr + 32'd128;
            ufp_rmask_internal = 4'b1111;
        end else begin
            ufp_addr_internal = ufp_addr;
            ufp_rmask_internal = ufp_rmask;
            ufp_rdata = ufp_rdata_internal;
            ufp_resp = 0;  
            ufp_rcache_line = ufp_rcache_line_internal;
        end
        // ufp_addr_internal = ufp_addr;
        // ufp_rmask_internal = ufp_rmask;
        // ufp_rdata = ufp_rdata_internal;
        // ufp_resp = ufp_resp_internal;
    end

    cache instruction_cache (
        .clk        (clk),
        .rst        (rst),
        
        .ufp_addr   (ufp_addr_internal),
        .ufp_rmask  (ufp_rmask_internal),
        .ufp_wmask  (ufp_wmask),
        .ufp_rdata  (ufp_rdata_internal),
        .ufp_rcache_line (ufp_rcache_line_internal),
        .ufp_wdata  (ufp_wdata),
        .ufp_resp   (ufp_resp_internal),

        .dfp_addr   (dfp_addr),
        .dfp_read   (dfp_read),
        .dfp_write  (dfp_write),
        .dfp_rdata  (dfp_rdata),
        .dfp_wdata  (dfp_wdata),
        .dfp_resp   (dfp_resp)
    );



endmodule