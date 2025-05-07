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
    input   logic           dfp_resp,
    output logic ufp_resp_prefetch
);
    logic[31:0] ufp_rdata_internal; 
    logic[255:0] ufp_rcache_line_internal; 

    logic ufp_resp_internal;
    logic[31:0] ufp_addr_internal, ufp_addr_internal_prev;
    logic[3:0]  ufp_rmask_internal, ufp_rmask_internal_prev;
 
    always_ff @(posedge clk/* or posedge rst*/) begin
        if (rst) begin
            ufp_addr_internal_prev  <= '0;
            ufp_rmask_internal_prev <= '0;
        end
        else begin
            ufp_addr_internal_prev  <= ufp_addr_internal;
            ufp_rmask_internal_prev <= ufp_rmask_internal;
        end
    end

    logic second_fetch;
    logic second_fetch_prev;
    always_ff @(posedge clk) begin
        second_fetch_prev <= second_fetch;
        if (rst) begin 
            second_fetch <= 1'b0;
        end
        if(ufp_resp_internal && (second_fetch == 1'b0)) begin
             second_fetch <= 1'b1;
        end else if (ufp_resp_internal) second_fetch <= 1'b0;
    end

    always_comb begin
        ufp_addr_internal = ufp_addr_internal_prev;
        ufp_rmask_internal = ufp_rmask_internal_prev;
        ufp_rdata = '0;
        ufp_rcache_line = '0;

        if(second_fetch && (!second_fetch_prev)) begin
            ufp_resp = 1'b0;
            ufp_resp_prefetch = ufp_resp_internal;
            ufp_addr_internal = ufp_addr + 32'd32;
            ufp_rmask_internal = 4'b1111;
        end else if (second_fetch) begin
            ufp_resp_prefetch = ufp_resp_internal;
            ufp_resp = 1'b0;
        end else if (!second_fetch) begin
            ufp_resp_prefetch = 1'b0;
            ufp_addr_internal = ufp_addr;
            ufp_rmask_internal = ufp_rmask;
            ufp_rdata = ufp_rdata_internal;
            ufp_resp = ufp_resp_internal;
            ufp_rcache_line = ufp_rcache_line_internal;
        end
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