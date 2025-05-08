/*module decode_compressed
import rv32i_types::*;
(
    input if_id_stage_reg_t     decode_struct_in, // Will only contain instr, pc, order & valid
    output id_dis_stage_reg_t   decode_struct_out,
    output logic is_compressed_inst
);

    logic [31:0] inst;

    assign inst = decode_struct_in.inst;

    assign is_compressed_inst = (inst[1:0] != 2'b11);
    assign decode_struct_out = '0;  // temporary


endmodule*/