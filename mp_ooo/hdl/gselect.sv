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



module perceptron_predictor #(
    parameter PC_W = 1,
    parameter HIST_W = 0,
    parameter NUM_WEIGHTS = 1,
    parameter WEIGHT_W = 1,
    parameter THETA = 1
)(
    input  logic           clk,
    input  logic           rst,
    input  logic [31:0]    pc_to_predict,
    input  logic [31:0]    pc_to_update,

    input  logic           branch_taken,
    input  logic           is_branch,
    output logic           prediction
);

    localparam PERCEPTRON_TABLE_ENTRIES = 2**PC_W;

    
    logic signed [WEIGHT_W-1:0] learning_weights_matrix [0:PERCEPTRON_TABLE_ENTRIES-1][0:NUM_WEIGHTS-1];
    logic [HIST_W-1:0]          global_branch_history_bits;
    logic signed [1:0]          history_features_predict [0:HIST_W-1];

    
    logic [PC_W-1:0]            idx_for_prediction_lookup;
    logic signed [WEIGHT_W+HIST_W+1:0] prediction_sum_raw;

    
    logic [PC_W-1:0]            idx_for_update_lookup;
    logic signed [1:0]          actual_outcome_signed_val;

    
    
    logic signed [WEIGHT_W+HIST_W+1:0] sum_for_weight_adjustment;
    logic signed [1:0]                 history_features_update [0:HIST_W-1];
    logic                              current_prediction_for_update;


    
    assign idx_for_prediction_lookup = pc_to_predict[PC_W-1:0];

    
    
    always_comb begin
        for (integer hist_conv_idx = 0; hist_conv_idx < HIST_W; hist_conv_idx = hist_conv_idx + 1) begin
            if (global_branch_history_bits[hist_conv_idx]) begin
                history_features_predict[hist_conv_idx] = 2'sd1; 
            end else begin
                history_features_predict[hist_conv_idx] = -2'sd1; 
            end
        end
    end

    
    always_comb begin
        
        if (NUM_WEIGHTS > 0) begin 
            prediction_sum_raw = 3'(learning_weights_matrix[idx_for_prediction_lookup][0]);
        end else begin
            prediction_sum_raw = '0; 
        end

        
        for (integer pred_loop_idx = 0; pred_loop_idx < HIST_W; pred_loop_idx = pred_loop_idx + 1) begin
            if ((pred_loop_idx + 1) < NUM_WEIGHTS) begin 
                prediction_sum_raw = prediction_sum_raw + (learning_weights_matrix[idx_for_prediction_lookup][pred_loop_idx+1] * history_features_predict[pred_loop_idx]);
            end
        end
    end

    
    assign prediction = (prediction_sum_raw >= 0);

    
    assign idx_for_update_lookup = pc_to_update[PC_W-1:0];

    
    
    always_comb begin
        if (branch_taken) begin
            actual_outcome_signed_val = 2'sd1; 
        end else begin
            actual_outcome_signed_val = -2'sd1; 
        end
    end

    
    integer table_reset_idx, weight_reset_idx;

    
    always_ff @(posedge clk) begin
        if (rst) begin
            global_branch_history_bits <= '0;
            
            for (table_reset_idx = 0; table_reset_idx < PERCEPTRON_TABLE_ENTRIES; table_reset_idx = table_reset_idx + 1) begin
                for (weight_reset_idx = 0; weight_reset_idx < NUM_WEIGHTS; weight_reset_idx = weight_reset_idx + 1) begin
                    learning_weights_matrix[table_reset_idx][weight_reset_idx] <= '0;
                end
            end
        end else if (is_branch) begin
            
        
            if (HIST_W > 2) begin
                // global_branch_history_bits <= 2'({global_branch_history_bits[HIST_W-2:0], branch_taken});
            end else begin
                global_branch_history_bits <= '0; 
            end
            
            for (integer hist_upd_conv_idx = 0; hist_upd_conv_idx < HIST_W; hist_upd_conv_idx = hist_upd_conv_idx + 1) begin
                if (global_branch_history_bits[hist_upd_conv_idx]) begin 
                    history_features_update[hist_upd_conv_idx] = 2'sd1;
                end else begin
                    history_features_update[hist_upd_conv_idx] = -2'sd1;
                end
            end

            
            if (NUM_WEIGHTS > 0) begin
                sum_for_weight_adjustment = (WEIGHT_W+HIST_W+2)'(learning_weights_matrix[idx_for_update_lookup][0]);
            end else begin
                sum_for_weight_adjustment = '0;
            end

            for (integer upd_sum_loop_idx = 0; upd_sum_loop_idx < HIST_W; upd_sum_loop_idx = upd_sum_loop_idx + 1) begin
                if ((upd_sum_loop_idx + 1) < NUM_WEIGHTS) begin
                    sum_for_weight_adjustment = sum_for_weight_adjustment + (learning_weights_matrix[idx_for_update_lookup][upd_sum_loop_idx+1] * history_features_update[upd_sum_loop_idx]);
                end
            end

            current_prediction_for_update = (sum_for_weight_adjustment >= 0);
            
            if ((current_prediction_for_update != branch_taken) || (sum_for_weight_adjustment < (WEIGHT_W+HIST_W+2)'(THETA))) begin
                logic signed [WEIGHT_W-1:0] new_bias_weight;
                new_bias_weight = WEIGHT_W'(learning_weights_matrix[idx_for_update_lookup][0] + actual_outcome_signed_val);

                
                if (NUM_WEIGHTS > 0) begin
                    if (new_bias_weight > WEIGHT_W'(2**(WEIGHT_W-1)-1)) begin
                        learning_weights_matrix[idx_for_update_lookup][0] <= WEIGHT_W'(2**(WEIGHT_W-1)-1);
                    end else if (new_bias_weight < WEIGHT_W'(-(2**(WEIGHT_W-1)))) begin
                        learning_weights_matrix[idx_for_update_lookup][0] <= WEIGHT_W'(-(2**(WEIGHT_W-1)));
                    end else begin
                        learning_weights_matrix[idx_for_update_lookup][0] <= new_bias_weight;
                    end
                end

                
                for (integer weight_adj_idx = 0; weight_adj_idx < HIST_W; weight_adj_idx = weight_adj_idx + 1) begin
                    if ((weight_adj_idx + 1) < NUM_WEIGHTS) begin
                        logic signed [WEIGHT_W-1:0] weight_delta_val;
                        logic signed [WEIGHT_W-1:0] new_hist_weight;

                        if (actual_outcome_signed_val == history_features_update[weight_adj_idx]) begin
                            weight_delta_val = WEIGHT_W'(2'sd1); 
                        end else begin
                            weight_delta_val = WEIGHT_W'(-2'sd1); 
                        end

                        new_hist_weight = learning_weights_matrix[idx_for_update_lookup][weight_adj_idx+1] + weight_delta_val;

                        if (new_hist_weight > WEIGHT_W'(2**(WEIGHT_W-1)-1)) begin
                            learning_weights_matrix[idx_for_update_lookup][weight_adj_idx+1] <= WEIGHT_W'(2**(WEIGHT_W-1)-1);
                        end else if (new_hist_weight < WEIGHT_W'(-(2**(WEIGHT_W-1)))) begin
                            learning_weights_matrix[idx_for_update_lookup][weight_adj_idx+1] <= WEIGHT_W'(-(2**(WEIGHT_W-1)));
                        end else begin
                            learning_weights_matrix[idx_for_update_lookup][weight_adj_idx+1] <= new_hist_weight;
                        end
                    end
                end
            end
        end
    end

endmodule