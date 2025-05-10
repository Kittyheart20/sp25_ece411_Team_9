module br_unit // and jumps
    import rv32i_types::*;
    (
        input  reservation_station_t next_execute,
        output to_writeback_t   execute_output
    );

    // JAL, JALR, BR

    logic [31:0] a, b, rd_new, pc_new; 
    logic br_en;    // Since we assume all branches are not taken. This also acts as our flushing signal

    always_comb begin
        a = '0;
        b = '0;
        br_en = '0;
        rd_new = '0;
        pc_new = '0;

        if (next_execute.valid) begin
            unique case(next_execute.opcode)
                op_b_jal: begin
                    a = next_execute.pc;
                    b = next_execute.imm_sext;
                    br_en = 1'b1;
                    rd_new = next_execute.pc + 4;
                end
                op_b_jalr: begin
                    a = next_execute.imm_sext;
                    b = next_execute.rs1_data;
                    br_en = 1'b1;
                    rd_new = next_execute.pc + 4;
                end
                op_b_br: begin
                    a = next_execute.pc;
                    b = next_execute.imm_sext;
                    unique case (next_execute.brop)
                        branch_f3_beq : br_en = (next_execute.rs1_data == next_execute.rs2_data);
                        branch_f3_bne : br_en = (next_execute.rs1_data != next_execute.rs2_data);
                        branch_f3_blt : br_en = unsigned'(signed'(next_execute.rs1_data) <  signed'(next_execute.rs2_data));
                        branch_f3_bge : br_en = unsigned'(signed'(next_execute.rs1_data) >= signed'(next_execute.rs2_data));
                        branch_f3_bltu: br_en = (next_execute.rs1_data <  next_execute.rs2_data);
                        branch_f3_bgeu: br_en = (next_execute.rs1_data >= next_execute.rs2_data);
                        default       : ;
                    endcase
                end
                default: ;
            endcase

            if (br_en)
                pc_new = a + b;
        end
    end
    

    always_comb begin 
        execute_output = '0;
        
        if (next_execute.valid) begin
            execute_output.valid = next_execute.valid;
            execute_output.pc = next_execute.pc;
            execute_output.inst = next_execute.inst;
            execute_output.prediction = next_execute.prediction;

            execute_output.rd_addr = next_execute.rd_addr;
            execute_output.rs1_addr = next_execute.rs1_addr;
            execute_output.rs2_addr = next_execute.rs2_addr;

            execute_output.rd_rob_idx = next_execute.rd_rob_idx;
            execute_output.rd_data = rd_new;
            execute_output.regf_we = next_execute.regf_we;
            execute_output.br_en = br_en;
            
            if (br_en)
                execute_output.pc_new = pc_new;
            else 
                execute_output.pc_new = next_execute.pc_new;
        end 
    end

endmodule