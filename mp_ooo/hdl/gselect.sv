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