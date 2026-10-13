`timescale 1ns/1ps

module tb_axi_lite_regs;

    // Clock: 10 ns period
    logic clk = 0;
    always #5 clk = ~clk;

    // Reset
    logic aresetn = 0;

    // AW channel
    logic [31:0] awaddr = 0;
    logic        awvalid = 0;
    wire         awready;

    // W channel
    logic [31:0] wdata = 0;
    logic [3:0]  wstrb = 0;
    logic        wvalid = 0;
    wire         wready;

    // B channel
    wire [1:0] bresp;
    wire       bvalid;
    logic      bready = 0;

    // Device Under Test
    axi_lite_regs dut (
        .clk(clk),
        .aresetn(aresetn),

        .s_axi_awaddr(awaddr),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),

        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),

        // Read interface not implemented yet
        .s_axi_araddr(32'b0),
        .s_axi_arvalid(1'b0),
        .s_axi_arready(),
        .s_axi_rdata(),
        .s_axi_rresp(),
        .s_axi_rvalid(),
        .s_axi_rready(1'b0)
    );

    initial begin

        // Hold reset through several rising edges
        repeat (3) @(negedge clk);
        aresetn = 1;

        // Start first transaction
        @(negedge clk);

        if (awready !== 1'b1 || wready !== 1'b1)
            $fatal(1, "FAIL: AW/W not ready after reset");

        awaddr  = 32'h00000008; // SRC_ADDR
        awvalid = 1;
        repeat (3) begin
            @(negedge clk);
            awvalid = 0;
            if (dut.awaddr_received !== 1'b1)
                $fatal(1, "FAIL: AW was not captured/held");
            if (dut.awaddr_reg !== awaddr)
                $fatal(1, "FAIL: Address was not correctly stored");
            if (dut.wdata_received !== 1'b0)
                $fatal(1, "FAIL: W should not be captured");
            if (awready !== 0)
                $fatal(1, "FAIL: AWREADY was not reset");
        end

        wdata   = 32'h12345678;
        wstrb   = 4'b1111;
        wvalid  = 1;

        // The intervening rising edge accepts AW and W
        @(negedge clk);

        if (dut.awaddr_received !== 1'b1 ||
            dut.wdata_received !== 1'b1)
            $fatal(1, "FAIL: AW/W were not captured");
        if (dut.write !== 1'b1)
            $fatal(1, "FAIL: write signal was not set");
        wvalid  = 0;

        // The next rising edge executes the write
        @(negedge clk);

        if (dut.src_addr_reg !== 32'h12345678)
            $fatal(1, "FAIL: Incorrect SRC_ADDR value");

        if (bvalid !== 1'b1 || bresp !== 2'b00)
            $fatal(1, "FAIL: Incorrect write response");

        // Test B-channel backpressure
        repeat (3) begin
            @(negedge clk);

            if (bvalid !== 1'b1 || bresp !== 2'b00)
                $fatal(1, "FAIL: B response not held");
            if (awready !== 1'b0 || wready !== 1'b0)
                $fatal(1, "FAIL: New write accepted while B pending");
        end

        // Allow response handshake
        bready = 1;

        // B channel handshake happens at rising edge

        @(negedge clk);

        if (bvalid !== 1'b0)
            $fatal(1, "FAIL: BVALID did not clear");
        if (awready !== 1'b1 || wready !== 1'b1)
            $fatal(1, "FAIL: AW/W not ready");  

        $display("PASS: AW-before-W transaction");

        wdata   = 32'h01234567; // Different wdata
        wstrb   = 4'b1000;
        wvalid  = 1;

        repeat (3) begin
            @(negedge clk)
            wvalid = 0;
            if (dut.wdata_received !== 1'b1)
                $fatal(1, "FAIL: W was not captured/held");
            if (dut.wdata_reg !== wdata) 
                $fatal(1, "FAIL: Data was not correctly stored");
            if (dut.wstrb_reg !== wstrb)
                $fatal(1, "FAIL: WSTRB was not correctly stored");
            if (dut.awaddr_received !== 1'b0)
                $fatal(1, "FAIL: AW should not be captured");
        end
        awaddr  = 32'h00000008; // SRC_ADDR
        awvalid = 1;

        // The next rising edge puts awaddr in awaddr_reg. Doesn't write yet due to nonblocking assignment

        @(negedge clk);

        if (dut.awaddr_received !== 1'b1 ||
            dut.wdata_received !== 1'b1)
            $fatal(1, "FAIL: AW/W were not captured");
        if (dut.write !== 1'b1)
            $fatal(1, "FAIL: write signal was not set");
        awvalid  = 0;

        // write executed at rising edge

        @(negedge clk);

        if (dut.src_addr_reg !== 32'h01345678) // need to account for wstrb
            $fatal(1, "FAIL: Incorrect SRC_ADDR value/Was not WSTRB-controlled");

        if (bvalid !== 1'b1 || bresp !== 2'b00)
            $fatal(1, "FAIL: Incorrect write response");

        // BREADY is still 1 from the first transaction

        // Next rising edge completes the second B handshake
        @(negedge clk);

        if (bvalid !== 1'b0)
        $fatal(1, "FAIL: Second BVALID did not clear");

        if (awready !== 1'b1 || wready !== 1'b1)
            $fatal(1, "FAIL: AW/W not ready after second write");
        
        $display("PASS: W-before-AW transaction");
        
        // Test write to control_reg

        awaddr = 32'h00000000; 
        awvalid = 1;
        wdata   = 32'h01234567; 
        wstrb   = 4'b1111;
        wvalid  = 1;
        bready = 1;

        @(negedge clk);
        awvalid = 0;
        wvalid = 0;

        @(negedge clk);
        if (dut.control_reg !== wdata) begin
            $fatal(1, "FAIL: Data was not correctly stored in control_reg");
        end

        if (bresp !== 2'b00) begin
            $fatal(1, "FAIL: BRESP was not correctly set");
        end

        if (bvalid !== 1) begin
            $fatal(1, "FAIL, BVALID was not set");
        end

        // Test write to length_reg
        @(negedge clk);
        awaddr = 32'h00000010; 
        awvalid = 1;
        wdata   = 32'hAABB1234; 
        wstrb   = 4'b0011;
        wvalid  = 1;
        bready = 1;

        @(negedge clk);
        awvalid = 0;
        wvalid = 0;

        @(negedge clk);
        if (dut.length_reg !== 32'h00001234) begin
            $fatal(1, "FAIL: Data was not correctly stored in length_reg");
        end

        if (bresp !== 2'b00) begin
            $fatal(1, "FAIL: BRESP was not correctly set");
        end

        if (bvalid !== 1) begin
            $fatal(1, "FAIL, BVALID was not set");
        end

        // Test write to status_reg
        @(negedge clk);
        awaddr = 32'h00000004; 
        awvalid = 1;
        wdata   = 32'h01234567; 
        wstrb   = 4'b1111;
        wvalid  = 1;
        bready = 1;

        @(negedge clk);
        awvalid = 0;
        wvalid = 0;

        @(negedge clk);
        if (dut.status_reg !== '0) begin
            $fatal(1, "FAIL: status_reg should not be written to");
        end

        if (bresp !== 2'b10) begin
            $fatal(1, "FAIL: BRESP was not correctly set");
        end

        if (bvalid !== 1) begin
            $fatal(1, "FAIL, BVALID was not set");
        end

        // Test write to invalid address 
        @(negedge clk);
        awaddr = 32'h0000001C; 
        awvalid = 1;
        wdata   = 32'h00000000; 
        wstrb   = 4'b0000;
        wvalid  = 1;
        bready = 1;

        @(negedge clk);
        awvalid = 0;
        wvalid = 0;

        @(negedge clk);
        if (bresp !== 2'b10) begin
            $fatal(1, "FAIL: BRESP was not correctly set");
        end

        if (bvalid !== 1) begin
            $fatal(1, "FAIL, BVALID was not set");
        end
        $display("PASS: All write tests to DMA registers");

        $finish;
    end

    // Prevent a broken test from running forever
    initial begin
        #500;
        $fatal(1, "FAIL: Testbench timeout");
    end

endmodule
