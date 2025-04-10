module writeback 
import rv32i_types::*;
(
    input  logic        clk,
    input  logic        rst,
    input  to_writeback_t   to_writeback,
    input cdb cdbus,
    // output logic [4:0]      rd,
    // output logic [31:0]     rd_data,
    output logic            regf_we
);

    always_comb begin    // Okay so writeback should send out the rd value through the bus- probably along with the ROB value. Reservation stations and the rat should be able to pick this value up
        regf_we = 1'b0;
        if(execute_output.valid) begin
            cdbus.valid = 1;
            cdbus.data = next_writeback.rd_data;
            cdbus.rd_addr = next_writeback.rd_addr;
            cdbus.rob_idx = next_writeback.rd_rob_idx;
            
        end
        // rd = '0;
        // rd_data = '0;
        // regf_we = 1'b0;

        // if (next_writeback.valid) begin
        //     rd = next_writeback.rd_addr;
        //     rd_data = next_writeback.rd_data;
        //     regf_we = 1'b1;
        // end
    end

endmodule