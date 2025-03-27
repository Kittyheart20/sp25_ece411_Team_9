module top_tb;

    timeunit 1ps;
    timeprecision 1ps;
    logic clk = 0; // initialize if needed
logic rst = 0;
    `include "top_tb.svh"

    int clock_half_period_ps;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
    end

    always #(clock_half_period_ps) clk <= ~clk;
    localparam WIDTH = 8;
    localparam DEPTH = 4;
    logic [WIDTH-1:0] data_i;
    logic enqueue_i;
    logic full_o;
    logic [WIDTH-1:0] data_o;
    logic dequeue_i;
    logic empty_o;

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

   cpu dut_cpu (
        .clk    (clk),
        .rst            (rst),

        .bmem_addr  ( 0  ),
        .bmem_read  (0  ),
        .bmem_write ( 0 ),
        .bmem_wdata ( 0 ),
        .bmem_ready ( 0 ),
        .bmem_raddr ( 0 ),
        .bmem_rdata ( 0 ),
        .bmem_rvalid( 0 )
    );



        initial begin
    $display("Starting queue testt.");
        @(posedge clk);
        rst <= 1;
        data_i <= 0;
        enqueue_i <= 0;
        dequeue_i <= 0;
        @(posedge clk);
        
        rst <= 0;
        @(posedge clk);
        
        // Test Case 1: nmpty queue check
        if (!empty_o) $error("Queue should be empty after reset");
        if (full_o) $error("Queue should not be full after reset");
        
        // try dequeuing from empty queue
        dequeue_i <= 1;
        @(posedge clk);
        if (!empty_o) $error("Queue should still be empty after attempted dequeue");
        dequeue_i <= 0;
        
        // Test Case 2: normal queue operation
        // Enqueue first value
        data_i <= 8'hA1;
        enqueue_i <= 1;
        @(posedge clk);
        enqueue_i <= 0;
        if (empty_o) $error("Queue should not be empty after enqueue");
        if (data_o != 8'hA1) $error("Expected first value A1, got %h", data_o);
        
        // enqueue more values
        data_i <= 8'hB2;
        enqueue_i <= 1;
        @(posedge clk);
        data_i = 8'hC3;
        @(posedge clk);
        enqueue_i <= 0;
        
        // dequeue and check FIFO order
        dequeue_i <= 1;
        @(posedge clk);
        if (data_o != 8'hB2) $error("Expected second value B2, got %h", data_o);
        @(posedge clk);
        if (data_o != 8'hC3) $error("Expected third value C3, got %h", data_o);
        dequeue_i = 0;
        @(posedge clk);
        
        // Test Case 3: full queue check
        @(posedge clk);

        rst <= 1;
        @(posedge clk);
        rst <= 0;
        @(posedge clk);
        
        // fill the queue
        enqueue_i <= 1;
        for (int i = 1; i <= DEPTH; i++) begin
            data_i = i;
            @(posedge clk);
        end
        
        if (!full_o) $error("Queue should be full");
        
        // try enqueuing when full
        data_i <= 8'hFF;
        @(posedge clk);
        
        // verify last value wasn't enqueued
        //dequeue_i = 1;
        @(posedge clk);
        if (data_o != 1) $error("Expected first value 1, got %h", data_o);
        
        // Test Case 4: simultaneous enqueue/dequeue when full
        dequeue_i <= 1;
        enqueue_i <= 1;
        data_i <= 8'hFF;
        @(posedge clk);
        
        // check values
        for (int i = 2; i <= DEPTH; i++) begin
            if (data_o != i) $error("Expected value %d, got %h", i, data_o);
            @(posedge clk);
        end
        if (data_o != 8'hFF) $error("Expected new value FF, got %h", data_o);
        
        // End test
        dequeue_i <= 0;
        enqueue_i <= 0;
        @(posedge clk);
        $display("Queue tests completed");
        $finish;
            $fsdbDumpfile("dump.fsdb");
        if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
        //    $fsdbDumpvars(0, dut, "+all");
            $fsdbDumpoff();
        end else begin
            $fsdbDumpvars(0, "+all");
        end
    end
    initial begin
        rst <= 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;
    end


endmodule

