module gselect_predictor #(
    parameter PC_W = 4,
    parameter HIST_W = 2,
    parameter IDX_W = PC_W + HIST_W
)(
    input  logic           clk,
    input  logic           rst,
    input  logic [32-1:0] pc_to_predict,
    input  logic [32-1:0] pc_to_update,

    input  logic           branch_taken,
    input  logic           is_branch,
    output logic           prediction
);

    logic [HIST_W-1:0] ghr;
    logic [1:0]        pht [0:(2**IDX_W)-1];
    logic [IDX_W-1:0]  idx_to_predict, idx_to_update;

    assign idx_to_predict = {ghr, pc_to_predict[PC_W-1:0]};
    assign idx_to_update = {ghr, pc_to_update[PC_W-1:0]};

    assign prediction = pht[idx_to_predict][1];

    integer j;

    always_ff @(posedge clk) begin
        if (rst) begin
            ghr <= '0;
            for (j = 0; j < 2**IDX_W; j = j + 1) begin
                pht[j] <= 2'b01;
            end
        end else if (is_branch) begin
            ghr <= {ghr[HIST_W-2:0], branch_taken};

            if (branch_taken) begin
                pht[idx_to_update] <= pht[idx_to_update] == 2'b11 ? 2'b11 : pht[idx_to_update] + 1'b1;
            end else begin
                pht[idx_to_update] <= pht[idx_to_update] == 2'b00 ? 2'b00 : pht[idx_to_update] - 1'b1;
            end
        end
    end

endmodule


module two_predictor #(
    parameter PC_W       = 4,
    parameter HIST_W     = 2, 
    localparam LHT_ENTRIES = 2**PC_W,      
    localparam PHT_ENTRIES = 2**HIST_W    
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [31:0]      pc_to_predict,
    input  logic [31:0]      pc_to_update,

    input  logic             branch_taken,
    input  logic             is_branch,   
    output logic             prediction 
);

    logic [HIST_W-1:0] lht [0:LHT_ENTRIES-1];

    logic [1:0]        pht [0:PHT_ENTRIES-1];

    logic [PC_W-1:0]   lht_idx_to_predict;
    logic [PC_W-1:0]   lht_idx_to_update;

    logic [HIST_W-1:0] local_history_to_predict;
    logic [HIST_W-1:0] local_history_to_update;

    assign lht_idx_to_predict = pc_to_predict[PC_W-1:0];
    assign lht_idx_to_update  = pc_to_update[PC_W-1:0];

    assign local_history_to_predict = lht[lht_idx_to_predict];

    assign local_history_to_update = lht[lht_idx_to_update];

    assign prediction = pht[local_history_to_predict][1]; 

    integer unsigned i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < LHT_ENTRIES; i = i + 1) begin
                lht[i] <= {HIST_W{1'b0}}; 
            end
            for (i = 0; i < PHT_ENTRIES; i = i + 1) begin
                pht[i] <= 2'b01; 
            end
        end else if (is_branch) begin
            if (branch_taken) begin
                if (pht[local_history_to_update] != 2'b11) begin
                    pht[local_history_to_update] <= pht[local_history_to_update] + 1'b1;
                end
            end else begin
                if (pht[local_history_to_update] != 2'b00) begin
                    pht[local_history_to_update] <= pht[local_history_to_update] - 1'b1;
                end
            end
            lht[lht_idx_to_update] <= {lht[lht_idx_to_update][HIST_W-2:0], branch_taken};
        end
    end

endmodule