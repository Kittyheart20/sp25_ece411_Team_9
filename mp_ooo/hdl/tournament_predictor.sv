module tournament_predictor #(
    parameter PC_W = 4,
    parameter HIST_W = 2,
    parameter SEL_W = 2 // selector table index width
)(
    input  logic           clk,
    input  logic           rst,
    input  logic [31:0]    pc_to_predict,
    input  logic [31:0]    pc_to_update,
    input  logic           branch_taken,
    input  logic           is_branch,
    output logic           prediction
);

    // Instantiate predictors
    logic prediction_gselect, prediction_perceptron;

    gselect_predictor #(
        .PC_W(PC_W),
        .HIST_W(HIST_W)
    ) gselect (
        .clk(clk), .rst(rst),
        .pc_to_predict(pc_to_predict),
        .pc_to_update(pc_to_update),
        .branch_taken(branch_taken),
        .is_branch(is_branch),
        .prediction(prediction_gselect)
    );

    perceptron_predictor #(
    ) perceptron (
        .clk(clk), .rst(rst),
        .pc_to_predict(pc_to_predict),
        .pc_to_update(pc_to_update),
        .branch_taken(branch_taken),
        .is_branch(is_branch),
        .prediction(prediction_perceptron)
    );

    localparam SEL_BITS = 4; // Number of bits per selector entry (stronger weighting)
    localparam SEL_ENTRIES = 2**SEL_W;
    logic [SEL_BITS-1:0] selector_table [0:SEL_ENTRIES-1];
    logic [SEL_W-1:0] sel_idx_predict, sel_idx_update;

    assign sel_idx_predict = pc_to_predict[SEL_W-1:0];
    assign sel_idx_update  = pc_to_update[SEL_W-1:0];

    // Use MSB of selector to choose predictor
    logic selection;
    assign selection = selector_table[sel_idx_predict][SEL_BITS-1];
    assign prediction = selection
                        ? prediction_perceptron
                        : prediction_gselect;
    integer i;
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < SEL_ENTRIES; i = i + 1)
                selector_table[i] <= '0; // weakly prefer gselect
        end else if (is_branch) begin
            // Update selector if predictors disagree
            if (prediction_gselect != prediction_perceptron) begin
                if (prediction_gselect == branch_taken && selector_table[sel_idx_update] != {SEL_BITS{1'b0}})
                    selector_table[sel_idx_update] <= selector_table[sel_idx_update] - SEL_BITS'(1);
                else if (prediction_perceptron == branch_taken && selector_table[sel_idx_update] != {SEL_BITS{1'b1}})
                    selector_table[sel_idx_update] <= selector_table[sel_idx_update] + SEL_BITS'(1);
            end
        end
    end

endmodule