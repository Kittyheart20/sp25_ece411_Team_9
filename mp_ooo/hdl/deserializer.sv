module deserializer (
    input   logic clk,
    input   logic rst,

    input   logic bmem_ready,
    input   logic [31:0] bmem_raddr,
    input   logic [63:0] bmem_rdata,
    input   logic bmem_rvalid,
    input   logic[255:0]  dfp_wdata,
    input   logic dfp_write,
    input logic   [31:0]  dfp_addr,
    input  logic   [31:0]      bmem_addr,
    input logic new_write,


    output  logic [255:0] dfp_rdata,
    output  logic dfp_resp,
    output  logic[63:0]  bmem_wdata,
    output logic bmem_write,
    input logic bmem_read,
    input logic bmem_flag
);
    logic [255:0] accumulator;
    logic [1:0] word_count;
    logic [2:0] write_count;  
    logic[31:0] dfp_addr_prev;
    logic[255:0] dfp_wdata_prev;

    logic dfp_write_prev;
    logic [31:0] past_bmem_addr;

    logic   [31:0]  bmem_debug_addr;
    assign bmem_debug_addr = 32'hefffd7f0;
    logic bmem_debug_hit;
    assign bmem_debug_hit = (bmem_addr == bmem_debug_addr);
    logic [31:9] bmem_debug_tag;
    assign bmem_debug_tag = bmem_debug_addr[31:9];
    logic bmem_debug_tag_hit;
    always_comb begin
        bmem_debug_tag_hit = 1'b0;
        if(bmem_addr[31:9] == bmem_debug_tag) begin
            bmem_debug_tag_hit = 1'b1;
        end
    end

    logic bmem_dfp_debug_tag_hit;
    always_comb begin
        bmem_dfp_debug_tag_hit = 1'b0;
        if(dfp_addr[31:9] == bmem_debug_tag) begin
            bmem_dfp_debug_tag_hit = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            accumulator <= 256'd0;
            word_count  <= 2'd0;
            write_count <= 3'd0;
            dfp_rdata   <= 256'd0;
            dfp_resp    <= 1'b0;
            dfp_addr_prev <= 32'd0;
            dfp_wdata_prev <= 256'd0;
            dfp_write_prev <= 1'b0;
            past_bmem_addr <= '0;
        end else begin
            past_bmem_addr <= bmem_addr;
            dfp_write_prev <= dfp_write;
            dfp_addr_prev <= dfp_addr;
            dfp_wdata_prev <= dfp_wdata;
            dfp_resp <= 1'b0;
            if (bmem_rvalid && bmem_ready) begin
                if (word_count == 2'd0 && ((bmem_raddr == bmem_addr) || bmem_raddr == past_bmem_addr)) begin
                    accumulator[63:0] <= bmem_rdata;
                    word_count <= (word_count == 2'd3) ? 2'd0 : (word_count + 2'd1);
                end
                else if (word_count == 2'd1) begin
                    accumulator[127:64] <= bmem_rdata;
                    word_count <= (word_count == 2'd3) ? 2'd0 : (word_count + 2'd1);
                end
                else if (word_count == 2'd2) begin
                    accumulator[191:128] <= bmem_rdata;
                    word_count <= (word_count == 2'd3) ? 2'd0 : (word_count + 2'd1); 
                end
                else if (word_count == 2'd3) begin
                    dfp_rdata <= {bmem_rdata, accumulator[191:0]};
                    dfp_resp  <= 1'b1;
                    word_count <= (word_count == 2'd3) ? 2'd0 : (word_count + 2'd1);
                end
                // dfp_raddr <= bmem_raddr;
            end
            
            if (dfp_write && bmem_ready && !bmem_flag) begin
                if (write_count == 3'd3) begin
                    dfp_resp <= 1'b1;
                end
                if (bmem_write || (dfp_write && !bmem_read && !bmem_flag))
                    write_count <= (write_count == 3'd4) ? 2'd0 : (write_count + 3'd1);
            end else write_count <= 3'd0;
        end
    end
    
    always_comb begin
        bmem_write = 1'b0;
        if (dfp_write && !bmem_read && !bmem_flag) begin
            case (write_count)
                3'd0: begin 
                    bmem_wdata = dfp_wdata[63:0];
                    //if(!dfp_write_prev) begin
                    bmem_write = 1'b1;
                    //end
                end
                3'd1: begin 
                    bmem_wdata = dfp_wdata[127:64];
                    bmem_write = 1'b1;
                end
                3'd2: begin 
                    bmem_wdata = dfp_wdata[191:128];
                    bmem_write = 1'b1;
                end
                3'd3: begin 
                    bmem_wdata = dfp_wdata[255:192];
                    bmem_write = 1'b1;
                end
                3'd4: begin 
                    bmem_wdata = '0;
                    bmem_write = 1'b0;
                end
                default: bmem_wdata = 64'h0;
            endcase
        end else begin
            bmem_wdata = 64'h0;
        end
        
         
    end


endmodule