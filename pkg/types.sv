package rv32i_types;
    /* --- INSTRUCTION --- */
    typedef enum logic [1:0] { // ALU input A
        rs1_out  = 2'b00,
        pc_out   = 2'b01,
	    no_out   = 2'b10
    } alu_m1_sel_t;

    typedef enum logic [1:0] { // ALU input B
        rs2_out  = 2'b00,
        imm_out  = 2'b01,
	    four_out = 2'b10
    } alu_m2_sel_t;
        
    typedef enum logic [1:0] { 
        empty = 2'b00,
        rob_wait = 2'b01,
        done = 2'b10
    } status_t;

    typedef enum logic [2:0] {
        none = 3'b000,
        alu  = 3'b001,
        mul  = 3'b010,  // div rem included
        br   = 3'b011,
        mem  = 3'b100
    } types_t;

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        BUSY = 2'b01,
        COMPLETE = 2'b10
    } status_rs_t;

    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [3:0] {
        alu_op_add     = 4'b0000,
        alu_op_sll     = 4'b0001,
        alu_op_sra     = 4'b0010,
        alu_op_sub     = 4'b0011,
        alu_op_xor     = 4'b0100,
        alu_op_srl     = 4'b0101,
        alu_op_or      = 4'b0110,
        alu_op_and     = 4'b0111,
        alu_op_slt     = 4'b1000,
        alu_op_sltu    = 4'b1001,
	    alu_op_none    = 4'b1010
    } alu_ops;

    typedef enum logic [2:0] { 
        mult_op_mul    = 3'b000,
        mult_op_mulh  = 3'b001,
        mult_op_mulsu  = 3'b010,
        mult_op_mulu   = 3'b011,
        mult_op_div    = 3'b100,
        mult_op_divu   = 3'b101,
        mult_op_rem    = 3'b110,
        mult_op_remu   = 3'b111
    } mult_ops;

    typedef struct packed {
        logic           valid;
        logic   [31:0]  pc;
        logic   [4:0]   rd_addr;
        logic   [4:0]   rs1_addr;
        logic   [4:0]   rs2_addr;
        // logic   [4:0]   rd_paddr;
        // logic   [4:0]   rs1_paddr;
        // logic   [4:0]   rs2_paddr;
        
        // Register stuff
        logic   [31:0]  rs1_data;
        logic           rs1_ready;
        logic   [31:0]  rs2_data;
        logic           rs2_ready;
        logic   [31:0]  imm_sext;

        // Control Signals
        logic           regf_we;
        logic valid_out;
        alu_m1_sel_t    alu_m1_sel;
        alu_m2_sel_t    alu_m2_sel;
        //pc_sel_t        pc_sel;
        alu_ops         aluop;
        mult_ops        multop;

        logic [4:0]     rs1_rob_idx;
        logic [4:0]     rs2_rob_idx;
        logic [4:0]     rd_rob_idx;
        status_rs_t     status;
    } reservation_station_t;

    typedef struct packed {
        logic           valid;
        logic   [31:0]  pc;
        logic   [4:0]   rd_addr;
        logic   [4:0]   rs1_addr;
        logic   [4:0]   rs2_addr;
        // logic   [4:0]   rd_paddr;
        // logic   [4:0]   rs1_paddr;
        // logic   [4:0]   rs2_paddr;

        logic           regf_we;
        logic   [4:0]   rd_rob_idx;
        logic   [31:0]  rd_data;    
    } to_writeback_t;

    typedef struct packed {
        logic           valid;
        logic   [31:0]  pc;
        logic           regf_we;
        logic   [4:0]   rd_addr;
        logic   [4:0]   rd_rob_idx;
        logic   [31:0]  rd_data;    
    } to_commit_t;


    typedef struct packed {
        logic           valid;
        status_t        status;
        types_t         op_type;
        logic   [4:0]   rd_addr;
        logic   [31:0]  rd_data;
        logic   [4:0]   rd_rob_idx;
        // logic           br_pred;
        // logic           br_result;
    } rob_entry_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        //logic   [31:0]      pc_next;
        logic   [63:0]      order;
    	logic         	    valid;
    } if_id_stage_reg_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [31:0]      pc_next;
        logic   [63:0]      order;
    	logic         	    valid;
        logic   [6:0]       opcode;
        logic   [2:0]       funct3;
        logic   [6:0]       funct7;

        logic [4:0]         rd_addr;
        logic [4:0]         rd_rob_idx;
        logic [4:0]         rs1_addr;
        logic [4:0]         rs2_addr;
        logic [4:0]         rs1_rob_idx;
        logic [4:0]         rs2_rob_idx;
        // logic [31:0]        rs1_data;
        // logic [31:0]        rs2_data;
        logic [31:0]        imm;

	    logic               regf_we;
        alu_m1_sel_t        alu_m1_sel;
        alu_m2_sel_t        alu_m2_sel;
        //pc_sel_t            pc_sel;
        types_t             op_type;

        alu_ops		        aluop;
        mult_ops            multop;

        logic use_rs1;
        logic use_rs2;

    } id_dis_stage_reg_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [6:0] {
        base           = 7'b0000000,
        mult           = 7'b0000001,
        variant        = 7'b0100000
    } funct7_t;

    // typedef enum logic [2:0] { // memory operation w/h/b
    //     mem_op_none  = 3'b000,
    //     mem_op_b     = 3'b001,
    //     mem_op_bu    = 3'b010,
    //     mem_op_h     = 3'b011,
    //     mem_op_hu    = 3'b100,
    //     mem_op_w     = 3'b101
    // } mem_ops;
    
    typedef struct packed {
        // writeback 
        logic        alu_valid;  
        logic [31:0] alu_data; 
        logic [4:0]  alu_rob_idx;
        logic [4:0]  alu_rd_addr;  

        logic        mul_valid;  
        logic [31:0] mul_data; 
        logic [4:0]  mul_rob_idx;
        logic [4:0]  mul_rd_addr;  

        // commit
        logic        regf_we;   
        logic [31:0] commit_data; 
        logic [4:0]  commit_rob_idx;
        logic [4:0]  commit_rd_addr; 
    } cdb;

endpackage : rv32i_types