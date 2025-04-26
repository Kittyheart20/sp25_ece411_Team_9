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


    output  logic [255:0] dfp_rdata,
    output  logic [31:0] dfp_raddr,
    output  logic dfp_resp,
    output  logic[63:0]  bmem_wdata,
    output logic bmem_write,
    input logic bmem_read,
    input logic dfp_read
);
    logic [255:0] accumulator;
    logic [1:0] word_count;
    logic [1:0] write_count;  
    logic bmem_write;
    logic[31:0] dfp_addr_prev;
    logic[255:0] dfp_wdata_prev;
    logic new_request;


    assign new_request = (!bmem_read && (dfp_addr != dfp_addr_prev) || ((dfp_wdata ^ dfp_wdata_prev) & ~(dfp_wdata ^ dfp_wdata_prev ^ dfp_wdata_prev) != 0));
    logic dfp_write_prev;
    logic[64:0] cycles_since_write;
    logic [31:0] expected_bmem_raddr;
    always_comb begin
        expected_bmem_raddr = {dfp_addr[31:5], 5'b0}; // Base address
        case (word_count)
            2'd0: expected_bmem_raddr = expected_bmem_raddr + 32'd0;
            2'd1: expected_bmem_raddr = expected_bmem_raddr + 32'd8;
            2'd2: expected_bmem_raddr = expected_bmem_raddr + 32'd16;
            2'd3: expected_bmem_raddr = expected_bmem_raddr + 32'd24;
            default: expected_bmem_raddr = 32'bX; // Undefined for other counts
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            accumulator <= 256'd0;
            word_count  <= 2'd0;
            write_count <= 2'd0;
            dfp_rdata   <= 256'd0;
            dfp_raddr   <= 32'd0;
            dfp_resp    <= 1'b0;
            dfp_addr_prev <= 32'd0;
            dfp_wdata_prev <= 256'd0;
            dfp_write_prev <= 1'b0;
            cycles_since_write <= 64'd0;
        end else begin
            if(dfp_write) begin
                cycles_since_write <= 64'd0;
            end else begin
                cycles_since_write <= cycles_since_write + 1;
            end
            dfp_write_prev <= dfp_write;
            dfp_addr_prev <= dfp_addr;
            dfp_wdata_prev <= dfp_wdata;
            dfp_resp <= 1'b0;
            if (bmem_rvalid && bmem_ready) begin
                if (word_count == 2'd0 && (bmem_raddr == bmem_addr)) begin
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
                dfp_raddr <= bmem_raddr;
            end
            
            if (dfp_write && bmem_ready) begin
                if (write_count == 2'd3) begin
                    dfp_resp <= 1'b1;
                end
                    
                write_count <= (write_count == 2'd3) ? 2'd0 : (write_count + 2'd1);
            end else write_count <= 2'd0;
        end
    end
    
    always_comb begin
        bmem_write = 1'b0;
        if (dfp_write && !bmem_read) begin
            case (write_count)
                2'd0: begin 
                    bmem_wdata = dfp_wdata[63:0];
                    if(!dfp_write_prev) begin
                        bmem_write = 1'b1;
                    end
                end
                2'd1: begin 
                    bmem_wdata = dfp_wdata[127:64];
                    bmem_write = 1'b1;
                end
                2'd2: begin 
                    bmem_wdata = dfp_wdata[191:128];
                    bmem_write = 1'b1;
                end
                2'd3: begin 
                    bmem_wdata = dfp_wdata[255:192];
                    bmem_write = 1'b1;
                end
                default: bmem_wdata = 64'h0;
            endcase
        end else begin
            bmem_wdata = 64'h0;
        end
        
         
    end


endmodule