module cache (
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


    logic [255:0]  dfp_rdata_stored;
    
    localparam TAG_BITS = 23;  
    localparam SET_BITS = 4;   
    localparam WAY_COUNT = 4;

    
    typedef enum logic [2:0] {
        IDLE,       
        COMPARE,    
        ALLOCATE,   
        AIDLE,
        AHIT,
        WRITEBACK   
    } cache_state_t;
    
    cache_state_t state, next_state;

    cache_state_t prev_state;
    always_ff @(posedge clk) begin
        if (rst) begin
            prev_state <= IDLE;
        end
        else begin
            prev_state <= state;  
        end
    end
    
    
    logic [3:0] prev_rmask, prev_wmask;
    logic [31:0] prev_addr;
    logic new_request;
    
    
    logic load_tag [WAY_COUNT];
    logic load_data [WAY_COUNT];
    logic load_valid [WAY_COUNT];
    logic load_dirty [WAY_COUNT];
    logic load_plru;
    logic [1:0] hit_way;
    logic [1:0] victim_way;
    logic hit;
    logic dirty_victim;
    logic [255:0] data_word_mask;
    
    
    logic [2:0] plru_bits;
    logic [2:0] next_plru_bits;
    
    
    logic [TAG_BITS-1:0] tag_out [WAY_COUNT];
    logic [255:0] data_out [WAY_COUNT];
    logic valid_out [WAY_COUNT];
    logic dirty_out [WAY_COUNT];
    
    
    logic [255:0] data_write [WAY_COUNT];
    logic [31:0] mask_offset; 
    logic [31:0] write_offset; 
    logic [4:0] addr_offset;

    
    logic [TAG_BITS-1:0] addr_tag;
    logic [SET_BITS-1:0] addr_set;

    logic [31:0] ufp_addr_prev;
    logic [3:0] ufp_rmask_prev, ufp_wmask_prev;
    logic dfp_resp_prev;
    logic [255:0] dfp_rdata_prev;
    logic first_trans;

    assign addr_tag = ufp_addr_prev[31:9];
    assign addr_set = ufp_addr_prev[8:5];
    assign addr_offset = ufp_addr_prev[4:0];

    logic [4:0] addr_instant;

    
    logic [TAG_BITS-1:0] addr_tag_instant;
    logic [SET_BITS-1:0] addr_set_instant;
        logic [4:0] addr_offset_instant;

    assign addr_tag_instant = ufp_addr[31:9];
    assign addr_set_instant = ufp_addr[8:5];
    assign addr_offset_instant = ufp_addr[4:0];

    logic data_written_cache;
    assign data_written_cache = ~((|ufp_rmask) | (|ufp_wmask));

    logic[31:0] wmask_test;
    logic dirty_in;

    always_comb begin

            wmask_test = 32'hFFFFFFFF;
    end

    logic   [31:0]  cache_debug_addr;
    assign cache_debug_addr = 32'haaab0000;
    logic cache_debug_hit;
    assign debug_hit = (ufp_addr == cache_debug_addr);
    logic [31:9] cache_debug_tag;
    assign cache_debug_tag = cache_debug_addr[31:9];
    logic cache_debug_tag_hit;
    always_comb begin
        cache_debug_tag_hit = 1'b0;
        if(ufp_addr[31:9] == cache_debug_tag && ((state == ALLOCATE || (state == WRITEBACK)) || (|ufp_wmask))) begin
            cache_debug_tag_hit = 1'b1;
        end
    end

    generate for (genvar i = 0; i < WAY_COUNT; i++) begin : arrays
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (~((|ufp_rmask) | (|ufp_wmask))), 
            .web0       (~load_tag[i]), 
            .addr0      (addr_set_instant),      
            .din0       (addr_tag_instant),      
            .dout0      (tag_out[i])
        );
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       ((~load_data[i])),
            
            .wmask0     (wmask_test),
            .addr0      (addr_set_instant),
            .din0       (data_write[i]),
            .dout0      (data_out[i])
        );
        
        sp_ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (~load_valid[i]),
            .addr0      (addr_set_instant),
            .din0       (1'b1),          
            .dout0      (valid_out[i])
        );
        
        sp_ff_array #(.WIDTH(1)) dirty_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),          
            .web0       (~load_dirty[i]),
            .addr0      (addr_set_instant),      
            .din0       (dirty_in),    
            .dout0      (dirty_out[i])
        );
    end endgenerate

    
    sp_ff_array #(
        .WIDTH      (3)
    ) lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),            
        .web0       (~load_plru),      
        .addr0      (addr_set_instant),        
        .din0       (next_plru_bits),  
        .dout0      (plru_bits)        
    );
    
    
    always_comb begin
        new_request = ((ufp_rmask != prev_rmask) || (ufp_wmask != prev_wmask) || 
                      (ufp_addr != prev_addr)) || first_trans;
    end
    
    
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            prev_rmask <= 4'b0;
            prev_wmask <= 4'b0;
            prev_addr <= 32'b0;
        end
        else begin
            state <= next_state;
            
            
            if (next_state == IDLE && (state == COMPARE || state == AHIT)) begin
                prev_rmask <= ufp_rmask_prev;
                prev_wmask <= ufp_wmask_prev;
                prev_addr <= ufp_addr_prev;
            end
        end
    end
    
    
    always_comb begin
        hit = 1'b0;
        hit_way = 2'b00;
        
        if (valid_out[0] && (tag_out[0] == addr_tag)) begin
            hit = 1'b1;
            hit_way = 2'b00;
        end
        else if (valid_out[1] && (tag_out[1] == addr_tag)) begin
            hit = 1'b1;
            hit_way = 2'b01;
        end
        else if (valid_out[2] && (tag_out[2] == addr_tag)) begin
            hit = 1'b1;
            hit_way = 2'b10;
        end
        else if (valid_out[3] && (tag_out[3] == addr_tag)) begin
            hit = 1'b1;
            hit_way = 2'b11;
        end
    end
    
    
    always_comb begin
        
        victim_way = 2'b00;
        
        
        
        
        
        
        unique casez (plru_bits)
            3'b0?0: victim_way = 2'd3;  
            3'b0?1: victim_way = 2'd2; 
            3'b10?: victim_way = 2'd1;  
            3'b11?: victim_way = 2'd0;  
            
            
            
            
            default: victim_way = 2'd0; 
        endcase
        
        
        dirty_victim = dirty_out[victim_way];
    end
    
    
    always_comb begin
        
        next_plru_bits = plru_bits;
        
        if (load_plru) begin
            
            case (hit ? hit_way : victim_way)
                2'd0: next_plru_bits = {1'b0, 1'b0, plru_bits[0]}; 
                2'd1: next_plru_bits = {1'b0, 1'b1, plru_bits[0]}; 
                2'd2: next_plru_bits = {1'b1, plru_bits[1], 1'b0}; 
                2'd3: next_plru_bits = {1'b1, plru_bits[1], 1'b1}; 
                
                
                
                
            endcase
        end
    end
    
    
    always_comb begin
        
        data_word_mask = 256'b0;
        mask_offset = 32'b0; 
        if (|ufp_wmask) begin
            mask_offset = addr_offset[4:2] * 32; 
            
            if (ufp_wmask[0]) data_word_mask[mask_offset +: 8] = 8'hFF;
            if (ufp_wmask[1]) data_word_mask[mask_offset + 8 +: 8] = 8'hFF;
            if (ufp_wmask[2]) data_word_mask[mask_offset + 16 +: 8] = 8'hFF;
            if (ufp_wmask[3]) data_word_mask[mask_offset + 24 +: 8] = 8'hFF;
        end
    end
    
    
    always_comb begin
        
        data_write[0] = data_out[0];
        data_write[1] = data_out[1];
        data_write[2] = data_out[2];
        data_write[3] = data_out[3];
        
        
        if (state == AIDLE) begin
            data_write[0] = dfp_rdata_stored;
            data_write[1] = dfp_rdata_stored;
            data_write[2] = dfp_rdata_stored;
            data_write[3] = dfp_rdata_stored;
        end
        
    if(state == COMPARE && hit && |ufp_wmask_prev) begin
        write_offset = addr_offset[4:2] * 32; 
        if (ufp_wmask[0]) begin
            data_write[hit_way][write_offset +: 8] = ufp_wdata[7:0];
        end
        if (ufp_wmask[1]) begin
            data_write[hit_way][write_offset + 8 +: 8] = ufp_wdata[15:8];
        end
        if (ufp_wmask[2]) begin
            data_write[hit_way][write_offset + 16 +: 8] = ufp_wdata[23:16];
        end
        if (ufp_wmask[3]) begin
            data_write[hit_way][write_offset + 24 +: 8] = ufp_wdata[31:24];
        end
    end else if ((state == AIDLE) && |ufp_wmask_prev) begin
        write_offset = addr_offset[4:2] * 32; 
        if (ufp_wmask[0]) begin
            data_write[victim_way][write_offset +: 8] = ufp_wdata[7:0];
        end
        if (ufp_wmask[1]) begin
            data_write[victim_way][write_offset + 8 +: 8] = ufp_wdata[15:8];
        end
        if (ufp_wmask[2]) begin
            data_write[victim_way][write_offset + 16 +: 8] = ufp_wdata[23:16];
        end
        if (ufp_wmask[3]) begin
            data_write[victim_way][write_offset + 24 +: 8] = ufp_wdata[31:24];
        end
    end

    end
    
    logic [31:0] word;
    always_comb begin
        ufp_rdata = 32'b0;
        ufp_rcache_line = 256'd0;
        
        if (state == COMPARE && hit && |ufp_rmask_prev) begin
            ufp_rdata = data_out[hit_way][addr_offset[4:2] * 32 +: 32]; 
            ufp_rcache_line = data_out[hit_way];
        end else if (state == AHIT && |ufp_rmask_prev) begin
            ufp_rdata = dfp_rdata_stored[addr_offset[4:2] * 32 +: 32];
            ufp_rcache_line = dfp_rdata_stored;
        end
    // if (state == COMPARE && hit && |ufp_rmask_prev) begin
    //     word = data_out[hit_way][addr_offset[4:2] * 32 +: 32]; 
    // end else if (state == ALLOCATE && dfp_resp_prev && |ufp_rmask_prev) begin
    //     word = dfp_rdata_prev[addr_offset[4:2] * 32 +: 32];
    // end else word = 32'b0; // Default to zero if no valid data is available
    
    // // Apply read mask
    // if (ufp_rmask_prev[0]) ufp_rdata[7:0] = word[7:0];
    // if (ufp_rmask_prev[1]) ufp_rdata[15:8] = word[15:8];
    // if (ufp_rmask_prev[2]) ufp_rdata[23:16] = word[23:16];
    // if (ufp_rmask_prev[3]) ufp_rdata[31:24] = word[31:24];
    end
    
    
    always_comb begin
        
        next_state = state;
        ufp_resp = 1'b0;
        dfp_read = 1'b0;
        dfp_write = 1'b0;
        dfp_addr = 32'b0;
        dfp_wdata = 256'b0;
        load_plru = 1'b0;
        
        
        load_tag[0] = 1'b0;
        load_data[0] = 1'b0;
        load_valid[0] = 1'b0;
        load_dirty[0] = 1'b0;
        
        load_tag[1] = 1'b0;
        load_data[1] = 1'b0;
        load_valid[1] = 1'b0;
        load_dirty[1] = 1'b0;
        
        load_tag[2] = 1'b0;
        load_data[2] = 1'b0;
        load_valid[2] = 1'b0;
        load_dirty[2] = 1'b0;
        
        load_tag[3] = 1'b0;
        load_data[3] = 1'b0;
        load_valid[3] = 1'b0;
        load_dirty[3] = 1'b0;

        dirty_in = 1'b0;
        
        case (state)
            IDLE: begin
                
                if ((|ufp_rmask || |ufp_wmask)) begin
                    next_state = COMPARE;
                end
            end
            
            COMPARE: begin
                if (hit) begin
                    load_plru = 1'b1;
                    ufp_resp = 1'b1;
                    
                    if (|ufp_wmask) begin
                        load_data[hit_way] = 1'b1;
                        load_dirty[hit_way] = 1'b1;
                        dirty_in = 1'b1; 
                    end
                    
                    next_state = IDLE;
                end else begin
                    if (dirty_victim) begin
                        next_state = WRITEBACK;
                    end else begin
                        next_state = ALLOCATE;
                    end
                end
            end
            
            WRITEBACK: begin
                
                dfp_write = 1'b1;
                dfp_wdata = data_out[victim_way];
                dfp_addr = {tag_out[victim_way], addr_set, 5'b0}; 
                
                if (dfp_resp) begin
                    
                    next_state = ALLOCATE;
                    load_dirty[victim_way] = 1'b1; 
                    dirty_in = 1'b0;
                end
            end
            
            ALLOCATE: begin
                dfp_read = 1'b1;
                dfp_addr = {ufp_addr_prev[31:5], 5'b0}; 
                
                if (dfp_resp) begin
                    // ufp_resp = 1'b1;
                    
                    // load_tag[victim_way] = 1'b1;
                    // load_valid[victim_way] = 1'b1;
                    // load_data[victim_way] = 1'b1;
                    // load_plru = 1'b1;
                    
                    // if (|ufp_wmask) begin
                    //     load_dirty[victim_way] = 1'b1; 
                    // end 
                    next_state = AIDLE;
                end
            end
            AIDLE: begin
                    load_tag[victim_way] = 1'b1;
                    load_valid[victim_way] = 1'b1;
                    load_data[victim_way] = 1'b1;
                    load_plru = 1'b1;
                    
                    if (|ufp_wmask) begin
                        load_dirty[victim_way] = 1'b1; 
                        dirty_in = 1'b1;
                    end 
                next_state = AHIT;
            end
            AHIT: begin
                next_state = IDLE;
                ufp_resp = 1'b1;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end



    always_ff @(posedge clk) begin
        if (rst) begin
            ufp_addr_prev <= 32'b0;
            ufp_rmask_prev <= 4'b0;
            ufp_wmask_prev <= 4'b0;
            dfp_resp_prev <= 1'b0;
            dfp_rdata_prev <= 256'b0;
            first_trans <= 1'b1;
            dfp_rdata_stored <= 256'b0;
        end
        else begin
            if ((|ufp_rmask || |ufp_wmask)) begin
                    if(state == IDLE) begin
                        ufp_addr_prev <= ufp_addr;
                        ufp_rmask_prev <= ufp_rmask;
                        ufp_wmask_prev <= ufp_wmask;
                        dfp_resp_prev <= dfp_resp;
                        dfp_rdata_prev <= dfp_rdata;
                    end
            end
            first_trans <= first_trans && (state != COMPARE);
            if(dfp_resp && (state == WRITEBACK || state == ALLOCATE)) begin
                 dfp_rdata_stored <= dfp_rdata;
            end
        end
    end



endmodule