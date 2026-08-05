`timescale 1ns/1ps

module tb_apb_subsystem();
    
    reg clk;
    reg rst;

    reg req;
    reg we;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0]  be;

    wire [31:0] rdata;
    wire        ready;
    wire        err;

    wire [31:0] PADDR;
    wire        PSEL;
    wire        PENABLE;
    wire [31:0] PWDATA;
    wire [3:0]  PSTRB;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    reg  [31:0] gpio_in;
    wire [31:0] gpio_out;
    wire [31:0] gpio_dir;
    wire        timer_irq;

    simple_to_apb_bridge u_bridge (
        .clk(clk),
        .rst(rst),

        .req(req),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .be(be),

        .rdata(rdata),
        .ready(ready),
        .err(err),

        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    apb_decoder u_apb_decoder (
        .PCLK(clk),
        .PRESETn(~rst),

        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),

        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir),
        .timer_irq(timer_irq)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task bus_write;
        input [31:0] wr_addr;
        input [31:0] wr_data;
        input [3:0]  wr_be;
        begin
            @(posedge clk);
            req   <= 1'b1;
            we    <= 1'b1;
            addr  <= wr_addr;
            wdata <= wr_data;
            be    <= wr_be;

            @(posedge clk);
            req <= 1'b0;

            wait (ready == 1'b1);
            @(posedge clk);

            $display("[WRITE] addr=%h data=%h err=%b", wr_addr, wr_data, err);
        end
    endtask

    task bus_read;
        input [31:0] rd_addr;
        output [31:0] rd_data; 

        begin
            @(posedge clk);
            req   <= 1'b1;
            we    <= 1'b0;
            addr  <= rd_addr;
            wdata <= 32'b0;
            be    <= 4'b1111;

            @(posedge clk);
            req <= 1'b0;

            wait (ready == 1'b1);
            rd_data = rdata;
            @(posedge clk);

            $display("[READ ] addr=%h data=%h err=%b", rd_addr, rd_data, err);
        end
    endtask

    reg [31:0] temp;

    initial begin
        req     = 0;
        we      = 0;
        addr    = 0;
        wdata   = 0;
        be      = 4'b1111;
        gpio_in = 32'ha5a5_1234;

        rst = 1;
        #30;
        rst = 0;

        // --------------------------------------------------------
        // GPIO test
        // --------------------------------------------------------
        bus_write(32'h1000_0000, 32'h0000_0055, 4'b1111);
        bus_read (32'h1000_0000, temp);

        if (temp != 32'h0000_0055) begin
            $display("GPIO_OUT READBACK FAILED");
            $finish;
        end

        bus_read(32'h1000_0004, temp);

        if (temp != 32'ha5a5_1234) begin
            $display("GPIO_IN READ FAILED");
            $finish;
        end

        bus_write(32'h1000_0008, 32'hffff_0000, 4'b1111);
        bus_read (32'h1000_0008, temp);

        if (temp != 32'hffff_0000) begin
            $display("GPIO_DIR FAILED");
            $finish;
        end

        // --------------------------------------------------------
        // Timer test
        // --------------------------------------------------------
        bus_write(32'h1000_1008, 32'd5, 4'b1111); // compare = 5
        bus_write(32'h1000_1000, 32'd1, 4'b1111); // enable

        repeat (10) @(posedge clk);

        bus_read(32'h1000_1004, temp);

        if (temp == 32'd0) begin
            $display("TIMER COUNT FAILED");
            $finish;
        end

        bus_read(32'h1000_100C, temp);

        if (temp[0] != 1'b1) begin
            $display("TIMER IRQ FLAG FAILED");
            $finish;
        end

        if (timer_irq != 1'b1) begin
            $display("TIMER IRQ OUTPUT FAILED");
            $finish;
        end

        // Clear IRQ
        bus_write(32'h1000_100C, 32'd1, 4'b1111);
        bus_read (32'h1000_100C, temp);

        if (temp[0] != 1'b0) begin
            $display("TIMER IRQ CLEAR FAILED");
            $finish;
        end

        // --------------------------------------------------------
        // Invalid address test
        // --------------------------------------------------------
        bus_read(32'h1000_3000, temp);

        if (err != 1'b1) begin
            $display("INVALID ADDRESS ERROR FAILED");
            $finish;
        end

        $display("==================================");
        $display("LEVEL 15 APB SUBSYSTEM TEST PASSED");
        $display("==================================");

        $finish;
    end

    initial begin
        $monitor("time=%0t req=%b we=%b addr=%h ready=%b PSEL=%b PENABLE=%b PWRITE=%b PREADY=%b PRDATA=%h",
                 $time, req, we, addr, ready, PSEL, PENABLE, PWRITE, PREADY, PRDATA);
    end
endmodule