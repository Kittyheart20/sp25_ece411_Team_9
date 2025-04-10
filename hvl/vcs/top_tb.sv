import rv32i_types::*;
module top_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
    end

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;
    bit rst;

    // Queue signals
    localparam WIDTH = 8;
    localparam DEPTH = 4;
    logic [WIDTH-1:0] data_i;
    logic enqueue_i;
    logic full_o;
    logic [WIDTH-1:0] data_o;
    logic dequeue_i;
    logic empty_o;

    // Deserializer signals
    logic bmem_ready;
    logic [63:0] bmem_rdata;
    logic bmem_rvalid;
    logic [255:0] dfp_wdata;
    logic dfp_write;
    logic dfp_read;
    logic [255:0] dfp_rdata;
    logic dfp_resp;
    logic [63:0] bmem_wdata;
    logic [31:0] dfp_addr;
    // logic [31:0] bmem_addr;
    // logic bmem_write;
    // logic bmem_read;

    queue #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut_q (
        .clk(clk),
        .rst(rst),
        .data_i(data_i),
        .enqueue_i(enqueue_i),
        .full_o(full_o),
        .data_o(data_o),
        .dequeue_i(dequeue_i),
        .empty_o(empty_o)
    );

    deserializer dut_deserializer (
        .clk(clk),
        .rst(rst),
        .bmem_ready(bmem_ready),
        .bmem_rdata(bmem_rdata),
        .bmem_rvalid(bmem_rvalid),
        .dfp_wdata(dfp_wdata),
        .dfp_write(dfp_write),
        .dfp_rdata(dfp_rdata),
        .dfp_resp(dfp_resp),
        .bmem_wdata(bmem_wdata)
    );


    task fsdbDump();
        $fsdbDumpfile("dump.fsdb");
        if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
            $fsdbDumpvars(0, dut, "+all");
            $fsdbDumpoff();
        end else begin
            $fsdbDumpvars(0, "+all");
        end
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;
    endtask

    task queue_test();
        $display("Starting queue test.");
        @(posedge clk);
        rst = 1'b1;
        data_i = '0;
        enqueue_i = 1'b0;
        dequeue_i = 1'b0;
        @(posedge clk);
        
        rst = 1'b0;
        @(posedge clk);
        
        // Test Case 1: empty queue check
        if (!empty_o) $error("Queue should be empty after reset");
        if (full_o) $error("Queue should not be full after reset");
        
        // try dequeuing from empty queue
        dequeue_i = 1'b1;
        @(posedge clk);
        if (!empty_o) $error("Queue should still be empty after attempted dequeue");
        dequeue_i = 1'b0;
        
        // Test Case 2: normal queue operation
        // Enqueue first value
        data_i = 8'hA1;
        enqueue_i = 1'b1;
        @(posedge clk);
        enqueue_i = 1'b0;
        if (empty_o) $error("Queue should not be empty after enqueue");
        if (data_o != 8'hA1) $error("Expected first value A1, got %h", data_o);
        
        // enqueue more values
        data_i = 8'hB2;
        enqueue_i = 1'b1;
        @(posedge clk);
        data_i = 8'hC3;
        @(posedge clk);
        enqueue_i = 1'b0;
        
        // dequeue and check FIFO order
        dequeue_i = 1'b1;
        @(posedge clk);
        if (data_o != 8'hB2) $error("Expected second value B2, got %h", data_o);
        @(posedge clk);
        if (data_o != 8'hC3) $error("Expected third value C3, got %h", data_o);
        dequeue_i = 1'b0;
        @(posedge clk);
        
        // Test Case 3: full queue check
        @(posedge clk);

        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        
        // fill the queue
        enqueue_i = 1'b1;
        for (int i = 1; i <= DEPTH; i++) begin
            data_i = i[7:0];
            @(posedge clk);
        end
        
        if (!full_o) $error("Queue should be full");
        
        // try enqueuing when full
        data_i = 8'hFF;
        @(posedge clk);
        
        // verify last value wasn't enqueued
        //dequeue_i = 1;
        @(posedge clk);
        if (data_o != 1) $error("Expected first value 1, got %h", data_o);
        
        // Test Case 4: simultaneous enqueue/dequeue when full
        dequeue_i = 1'b1;
        enqueue_i = 1'b1;
        data_i = 8'hFF;
        @(posedge clk);
        
        // check values
        for (int i = 2; i <= DEPTH; i++) begin
            if (data_o != i[7:0]) $error("Expected value %d, got %h", i, data_o);
            @(posedge clk);
        end
        if (data_o != 8'hFF) $error("Expected new value FF, got %h", data_o);
        
        // End test
        dequeue_i = 1'b0;
        enqueue_i = 1'b0;
        @(posedge clk);
        $display("Queue tests completed");
    endtask

    task deserializer_test();
        // Test deserializer
        $display("Starting deserializer test.");
        @(posedge clk);
        rst = 1'b1;
        bmem_ready = 1'b0;
        bmem_rdata = 64'h0;
        bmem_rvalid = 1'b0;
        dfp_wdata = 256'h0;
        dfp_write = 1'b0;
        dfp_read = 1'b0;
        dfp_addr = 32'h0;
        @(posedge clk);
        
        rst = 1'b0;
        @(posedge clk);
        
        // Test Case 1: Read test with immediate response
        $display("Test Case 1: Read test with immediate response");
        bmem_ready = 1'b1;
        dfp_read = 1'b1;  // Initiate read operation
        dfp_addr = 32'h1000; // Base address for read
        @(posedge clk);
        
        // if (!bmem_read) $error("bmem_read signal should be asserted during read operation");
        dfp_read = 1'b0;  // Can deassert once operation begins
        
        // Simulate memory responding to read requests
        bmem_rvalid = 1'b1;
        
        // Send 4 consecutive 64-bit values
        bmem_rdata = 64'hAAAA_AAAA_AAAA_AAAA;
        @(posedge clk);
        // if (bmem_addr != 32'h1000) $error("Incorrect read address[0]: %h", bmem_addr);
        
        bmem_rdata = 64'hBBBB_BBBB_BBBB_BBBB;
        @(posedge clk);
        // if (bmem_addr != 32'h1008) $error("Incorrect read address[1]: %h", bmem_addr);
        
        bmem_rdata = 64'hCCCC_CCCC_CCCC_CCCC;
        @(posedge clk);
        // if (bmem_addr != 32'h1010) $error("Incorrect read address[2]: %h", bmem_addr);
        
        bmem_rdata = 64'hDDDD_DDDD_DDDD_DDDD;
        @(posedge clk);
        // if (bmem_addr != 32'h1018) $error("Incorrect read address[3]: %h", bmem_addr);
        
        bmem_rvalid = 1'b0;
        
        // Check response
        if (!dfp_resp) $error("Deserializer should have responded");
        if (dfp_rdata != 256'hDDDD_DDDD_DDDD_DDDD_CCCC_CCCC_CCCC_CCCC_BBBB_BBBB_BBBB_BBBB_AAAA_AAAA_AAAA_AAAA)
            $error("Incorrect read data: %h", dfp_rdata);
        // if (bmem_read) $error("bmem_read should be deasserted after operation completes");
        
        @(posedge clk);
        @(posedge clk);

        // Test Case 2: Read test with delay
        $display("Test Case 2: Read test with delay");
        bmem_ready = 1'b1;
        dfp_read = 1'b1;  // Initiate read operation
        @(posedge clk);
        bmem_rvalid = 1'b1;
        dfp_read = 1'b0;  // Initiate read operation

        // First word
        bmem_rdata = 64'h1111_1111_1111_1111;
        @(posedge clk);
        
        // Second word
        bmem_rdata = 64'h2222_2222_2222_2222;
        @(posedge clk);
        
        // Pause before third word
        bmem_rvalid = 1'b0;
        repeat(3) @(posedge clk);
        
        // Continue with third word
        bmem_rvalid = 1'b1;
        bmem_rdata = 64'h3333_3333_3333_3333;
        @(posedge clk);
        
        // Fourth word
        bmem_rdata = 64'h4444_4444_4444_4444;
        @(posedge clk);

        bmem_rvalid = 1'b0;
        
        // Check response
        if (!dfp_resp) $error("Deserializer should have responded");
        if (dfp_rdata != 256'h4444_4444_4444_4444_3333_3333_3333_3333_2222_2222_2222_2222_1111_1111_1111_1111)
            $error("Incorrect read data: %h", dfp_rdata);
        
        @(posedge clk);
        #10ps;
        
        // Test Case 3: Write test with immediate response
        $display("Test Case 3: Write test with immediate response");
        bmem_ready = 1'b1;
        dfp_wdata = 256'h8888_8888_8888_8888_7777_7777_7777_7777_6666_6666_6666_6666_5555_5555_5555_5555;
        dfp_write = 1'b1;
        dfp_addr = 32'h2000; // Base address for write
        @(posedge clk);
        
        // if (!bmem_write) $error("bmem_write signal should be asserted during write operation");
      //  dfp_write = 1'b0;  // Can deassert once operation begins
        
        // First word
        if (bmem_wdata != 64'h5555_5555_5555_5555) $error("Incorrect write data[0]: %h", bmem_wdata);
        // if (bmem_addr != 32'h2000) $error("Incorrect write address[0]: %h", bmem_addr);
        // if (!bmem_write) $error("bmem_write should be asserted during first word");
        
        // Second word
        @(posedge clk);
        if (bmem_wdata != 64'h6666_6666_6666_6666) $error("Incorrect write data[1]: %h", bmem_wdata);
        // if (bmem_addr != 32'h2008) $error("Incorrect write address[1]: %h", bmem_addr);
        // if (!bmem_write) $error("bmem_write should be asserted during second word");
        
        // Third word
        @(posedge clk);
        if (bmem_wdata != 64'h7777_7777_7777_7777) $error("Incorrect write data[2]: %h", bmem_wdata);
        // if (bmem_addr != 32'h2010) $error("Incorrect write address[2]: %h", bmem_addr);
        // if (!bmem_write) $error("bmem_write should be asserted during third word");
        
        // Fourth word
        @(posedge clk);
        if (bmem_wdata != 64'h8888_8888_8888_8888) $error("Incorrect write data[3]: %h", bmem_wdata);
        // if (bmem_addr != 32'h2018) $error("Incorrect write address[3]: %h", bmem_addr);
        // if (!bmem_write) $error("bmem_write should be asserted during fourth word");
        
        
        // Check response
        @(posedge clk);
        if (!dfp_resp) $error("Deserializer should have responded after write");
        // if (bmem_write) $error("bmem_write should be deasserted after operation completes");
        
        dfp_write = 1'b0;
        @(posedge clk);
        
        $display("Deserializer tests completed");
    endtask

    // Decode signals
    logic stall;
    if_id_stage_reg_t    id_in;
    id_dis_stage_reg_t   id_out;
    id_dis_stage_reg_t   id_out_old;

    decode dut_decode (
        .stall(stall),
        .decode_struct_in(id_in),
        .decode_struct_out(id_out)
    );

    task decode_test();
        $display("-----Starting Decode Test-----");
        
        @(posedge clk);
        stall = 0;
        id_in.inst = $random();
        id_in.pc = 32'hAAAAA000;
        id_in.order = 32'd0;
        id_in.valid = 1;
        
        // Test 1 Decode struct out has correct instruction data
        @(posedge clk);
        if (id_out.inst != id_in.inst) $error("Out's instruction does not match");
        if (id_out.pc != 32'hAAAAA000) $error("Out's pc does not match");
        if (id_out.order != 32'd0) $error("Out's order does not match");
        if (id_out.valid != 1'b1) $error("Out's valid does not match");
        if (id_out.opcode != id_in.inst[6:0]) $error("Out's opcode does not match");
        if (id_out.funct3 != id_in.inst[14:12]) $error("Out's funct3 does not match");
        if (id_out.funct7 != id_in.inst[31:25]) $error("Out's funct7 does not match");
        if (id_out.rs1_addr != id_in.inst[19:15]) $error("Out's rs1_addr does not match");
        if (id_out.rs2_addr != id_in.inst[24:20]) $error("Out's rs2_addr does not match");
        if (id_out.rd_addr != id_in.inst[11:7]) $error("Out's rd_addr does not match");
        $display("Test 1 Completed");

        // Test 2 Decode struct out does not execute at stall 
        id_out_old = id_out;        
        stall = 1;
        id_in.inst = 32'hFFFFF0B7;  // lui x1, 0xFFFFF0000
        @(posedge clk);
        if (id_out != id_out) $error("Decode executes at stall");
        $display("Test 2 Completed");
        
        // Test 3 Decode struct out has correct LUI specific instruction data
        stall = 0;
        @(posedge clk);
        if (id_out.imm != {id_in.inst[31:12], 12'b0}) $error("Wrong LUI imm");
        if (id_out.alu_m1_sel != 2'b10) $error("Wrong LUI alu_m1_sel value");
        if (id_out.alu_m2_sel != 2'b01) $error("Wrong LUI alu_m2_sel value");
        if (id_out.aluop != 4'd0) $error("Wrong LUI alu_op selection");
        $display("Test 3 Completed");

    endtask

    initial begin
        fsdbDump();
        // queue_test();
        // deserializer_test();
        // decode_test();
    end

    `include "top_tb.svh"

endmodule