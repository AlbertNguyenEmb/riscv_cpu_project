`timescale 1ns/1ps

module tb_pipelined_cpu_apb;

    reg clk;
    reg rst;

    reg  [31:0] gpio_in;
    wire [31:0] gpio_out;
    wire [31:0] gpio_dir;
    wire        timer_irq;
    wire        uart_tx;

    pipelined_cpu dut (
        .clk(clk),
        .rst(rst),

        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir),

        .timer_irq(timer_irq),
        .uart_tx(uart_tx)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        gpio_in = 32'ha5a5_1234;

        rst = 1;
        #30;
        rst = 0;

        #4000;

        $display("==================================");
        $display("Level 16 CPU + APB Subsystem Results:");

        $display("gpio_in      = %h", gpio_in);
        $display("gpio_out     = %h", gpio_out);
        $display("gpio_dir     = %h", gpio_dir);
        $display("timer_irq    = %b", timer_irq);
        $display("uart_tx      = %b", uart_tx);

        $display("x3 GPIO_OUT readback = %h", dut.u_regfile.regs[3]);
        $display("x4 GPIO_IN read      = %h", dut.u_regfile.regs[4]);
        $display("x7 TIMER_COUNT       = %0d", dut.u_regfile.regs[7]);
        $display("x8 TIMER_STATUS      = %h", dut.u_regfile.regs[8]);
        $display("x11 UART_STATUS      = %h", dut.u_regfile.regs[11]);

        $display("DMEM[0..3]   = %h%h%h%h",
                 dut.u_dmem.mem[3],
                 dut.u_dmem.mem[2],
                 dut.u_dmem.mem[1],
                 dut.u_dmem.mem[0]);

        $display("DMEM[4..7]   = %h%h%h%h",
                 dut.u_dmem.mem[7],
                 dut.u_dmem.mem[6],
                 dut.u_dmem.mem[5],
                 dut.u_dmem.mem[4]);

        $display("DMEM[8..11]  = %h%h%h%h",
                 dut.u_dmem.mem[11],
                 dut.u_dmem.mem[10],
                 dut.u_dmem.mem[9],
                 dut.u_dmem.mem[8]);

        $display("DMEM[12..15] = %h%h%h%h",
                 dut.u_dmem.mem[15],
                 dut.u_dmem.mem[14],
                 dut.u_dmem.mem[13],
                 dut.u_dmem.mem[12]);

        $display("DMEM[16..19] = %h%h%h%h",
                 dut.u_dmem.mem[19],
                 dut.u_dmem.mem[18],
                 dut.u_dmem.mem[17],
                 dut.u_dmem.mem[16]);

        $display("==================================");

        if (gpio_out == 32'h0000_005a &&
            dut.u_regfile.regs[3] == 32'h0000_005a &&
            dut.u_regfile.regs[4] == 32'ha5a5_1234 &&
            dut.u_regfile.regs[7] > 32'd0 &&
            dut.u_regfile.regs[8][0] == 1'b1 &&
            dut.u_regfile.regs[11][1] == 1'b1 &&
            {dut.u_dmem.mem[3], dut.u_dmem.mem[2],
             dut.u_dmem.mem[1], dut.u_dmem.mem[0]} == 32'h0000_005a &&
            {dut.u_dmem.mem[7], dut.u_dmem.mem[6],
             dut.u_dmem.mem[5], dut.u_dmem.mem[4]} == 32'ha5a5_1234) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d mem_stall=%b apb_req=%b apb_ready=%b PADDR=%h PSEL=%b PENABLE=%b PWRITE=%b gpio_out=%h uart_tx=%b",
                 $time,
                 dut.pc,
                 dut.mem_stall,
                 dut.apb_req,
                 dut.APB_ready,
                 dut.u_apb_subsystem.u_simple_to_apb_bridge.PADDR,
                 dut.u_apb_subsystem.u_simple_to_apb_bridge.PSEL,
                 dut.u_apb_subsystem.u_simple_to_apb_bridge.PENABLE,
                 dut.u_apb_subsystem.u_simple_to_apb_bridge.PWRITE,
                 gpio_out,
                 uart_tx);
    end

endmodule