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

    logic [31:0] pc, pc_next;
    logic [63:0] order;
    logic        commit;

    assign pc_next = pc + 32'd4;

    // Cache
    logic   [31:0]  ufp_addr;
    logic   [3:0]   ufp_rmask;
    logic   [3:0]   ufp_wmask;
    logic   [31:0]  ufp_rdata;
    logic   [255:0] ufp_rcache_line;
    logic   [31:0]  ufp_wdata;
    logic           ufp_resp;

    logic   [31:0]  dfp_addr;
    logic           dfp_read;
    logic           dfp_write;
    logic   [255:0] dfp_rdata;
    logic   [255:0] dfp_wdata;
    logic           dfp_resp;
    logic           reached_loop; // debug value

    assign ufp_wmask = '0;
    assign ufp_wdata = '0;

    // Instr Queue
    logic full_o, empty_o;
    logic enqueue_i, dequeue_i;
    logic [31:0] data_i, data_o;

    deserializer cache_line_adapter (
        .clk        (clk),
        .rst        (rst),
        .bmem_ready (bmem_ready),
        .bmem_raddr (bmem_raddr),
        .bmem_rdata (bmem_rdata),
        .bmem_rvalid(bmem_rvalid),
        .dfp_wdata  (dfp_wdata),
        .dfp_write  (dfp_write),
        .dfp_rdata  (dfp_rdata),
        .dfp_resp   (dfp_resp),
        .bmem_wdata (bmem_wdata)
    );

    cache instruction_cache (
        .clk        (clk),
        .rst        (rst),
        
        .ufp_addr   (ufp_addr),
        .ufp_rmask  (ufp_rmask),
        .ufp_wmask  (ufp_wmask),
        .ufp_rdata  (ufp_rdata),
        .ufp_rcache_line (ufp_rcache_line),
        .ufp_wdata  (ufp_wdata),
        .ufp_resp   (ufp_resp),

        .dfp_addr   (dfp_addr),
        .dfp_read   (dfp_read),
        .dfp_write  (dfp_write),
        .dfp_rdata  (dfp_rdata),
        .dfp_wdata  (dfp_wdata),
        .dfp_resp   (dfp_resp)
    );

    localparam WIDTH = 32;
    localparam DEPTH = 8;
    localparam ALEN = 256;
    localparam BLEN = 32;
    queue #(
        .WIDTH      (WIDTH),
        .DEPTH      (DEPTH)
    ) instruction_queue (
        .clk        (clk),
        .rst        (rst),
        .data_i     (data_i),
        .enqueue_i  (enqueue_i),
        .full_o     (full_o),
        .data_o     (data_o),
        .dequeue_i  (dequeue_i),
        .empty_o    (empty_o)
    );

    // assign bmem_addr = 32'hAAAAA000;
    // assign bmem_read = 1;
    // assign bmem_write = 0;

    logic [31:0] curr_instr_addr, last_instr_addr;
    logic [255:0] curr_instr_data, last_instr_data;
    logic enable;

    register #(
        .A_LEN          (ALEN),
        .B_LEN          (BLEN)
    ) line_buffer (
        .clk            (clk),
        .rst            (rst),
        .data_a_input   (curr_instr_data),
        .data_b_input   (curr_instr_addr),
        .data_valid     (enable),  // update line buffer if 1
        .data_a_output  (last_instr_data),
        .data_b_output  (last_instr_addr)
    );

    logic bmem_flag;
    always_ff @(posedge clk) begin
        reached_loop <= '0;
        if (rst) begin
            pc          <= 32'haaaaa000;
            order       <= '0;
            ufp_rmask   <= '0;
            data_i      <= '0;
            bmem_read   <= 1'b0;
            bmem_write  <= 1'b0;
            commit <= 1'b0;
            enqueue_i <= 1'b0;
            dequeue_i <= 1'b0;
            enable <= 1'b0;    
            bmem_flag <= 1'b0;   
        end else begin
            if (commit)     commit <= 1'b0;
            if (enqueue_i)  enqueue_i <= 1'b0;
            if (dequeue_i)  dequeue_i <= 1'b0;
            if (enable)     enable <= 1'b0;
            //ufp_rmask   <= '0;

            if (pc[31:5] == last_instr_addr[31:5]) begin       // line buffer
                ufp_rmask <= '0;
                reached_loop <= '1;
                data_i <= last_instr_data[32*pc[4:2] +: 32];
                if (!full_o) begin
                    enqueue_i <= 1'b1;
                    pc <= pc_next;
                    order <= order + 'd1;
                    commit <= 1'b1;
                end
            end

            else begin                                  // cache
                if (ufp_rmask == 4'd0) begin
                    ufp_addr <= pc;
                    ufp_rmask <= '1;                   
                end else if (ufp_resp) begin
                    data_i <= ufp_rdata[32*pc[4:2] +: 32];
                    if (!full_o) begin
                        ufp_rmask <= '0;
                        enqueue_i <= 1'b1;
                        curr_instr_addr <= pc;
                        curr_instr_data <= ufp_rcache_line;
                        enable <= 1'b1;
                        pc <= pc_next;
                        order <= order + 'd1;
                        commit <= 1'b1;
                    end
                end else if (dfp_write) begin
                    bmem_addr <= dfp_addr;
                    bmem_write <= 1'b1;
                    if (bmem_write && bmem_wdata == 64'h0) begin 
                        bmem_write <= 1'b0;
                    end
                end else if (dfp_read) begin
                    bmem_addr <= dfp_addr;
                    if (bmem_flag == 0) begin
                        bmem_read <= 1'b1;
                        bmem_flag <= 1'b1;
                    end else begin
                        bmem_read <= 1'b0;
                    end
                    if (dfp_resp) begin    // need a counter?
                        bmem_read <= 1'b0;
                        bmem_flag <= 1'b0;
                    end
                end
            end
        end
    end
    

endmodule : cpu