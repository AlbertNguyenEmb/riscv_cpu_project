`timescale 1ns/1ps

module tb_pipelined_cpu;

    reg clk;
    reg rst;

    reg  [31:0] gpio_in;
    wire [31:0] gpio_out;

    pipelined_cpu dut (
        .clk(clk),
        .rst(rst),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        gpio_in = 32'ha5a5_1234;

        rst = 1;
        #12;
        rst = 0;

        #1200;

        $display("==================================");
        $display("Level 9 Mini SoC Results:");

        $display("GPIO_IN      = %h", gpio_in);
        $display("GPIO_OUT     = %h", gpio_out);

        $display("x1 GPIO_BASE = %h", dut.u_regfile.regs[1]);
        $display("x2           = %h", dut.u_regfile.regs[2]);
        $display("x3 GPIO_IN   = %h", dut.u_regfile.regs[3]);

        $display("x4 PERF_BASE = %h", dut.u_regfile.regs[4]);
        $display("x5 cycles    = %0d", dut.u_regfile.regs[5]);
        $display("x6 instrs    = %0d", dut.u_regfile.regs[6]);

        $display("x9           = %0d", dut.u_regfile.regs[9]);
        $display("x10          = %0d", dut.u_regfile.regs[10]);
        $display("x11          = %0d", dut.u_regfile.regs[11]);
        $display("x12          = %0d", dut.u_regfile.regs[12]);

        $display("x13 stalls   = %0d", dut.u_regfile.regs[13]);
        $display("x14 flushes  = %0d", dut.u_regfile.regs[14]);

        $display("counter cycle_count   = %0d", dut.cycle_count);
        $display("counter instr_count   = %0d", dut.instr_count);
        $display("counter stall_count   = %0d", dut.stall_count);
        $display("counter flush_count   = %0d", dut.flush_count);
        $display("counter m_stall_count = %0d", dut.m_stall_count);

        $display("DMEM[20..23] stall_count = %h%h%h%h",
                 dut.u_dmem.mem[23],
                 dut.u_dmem.mem[22],
                 dut.u_dmem.mem[21],
                 dut.u_dmem.mem[20]);

        $display("DMEM[24..27] flush_count = %h%h%h%h",
                 dut.u_dmem.mem[27],
                 dut.u_dmem.mem[26],
                 dut.u_dmem.mem[25],
                 dut.u_dmem.mem[24]);

        $display("==================================");

        if (dut.u_regfile.regs[1]  == 32'h1000_0000 &&
            dut.u_regfile.regs[3]  == 32'ha5a5_1234 &&
            dut.u_regfile.regs[4]  == 32'h2000_0000 &&
            dut.u_regfile.regs[9]  == 32'd42 &&
            dut.u_regfile.regs[10] == 32'd42 &&
            dut.u_regfile.regs[11] == 32'd42 &&
            dut.u_regfile.regs[12] == 32'd77 &&
            gpio_out               == 32'd42 &&
            dut.u_regfile.regs[5]  > 32'd0 &&
            dut.u_regfile.regs[6]  > 32'd0 &&
            dut.u_regfile.regs[13] > 32'd0 &&
            dut.u_regfile.regs[14] > 32'd0) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d gpio_out=%h cycle=%0d instr=%0d stall=%0d flush=%0d IF_ID=%h WB_data=%h",
                 $time,
                 dut.pc,
                 gpio_out,
                 dut.cycle_count,
                 dut.instr_count,
                 dut.stall_count,
                 dut.flush_count,
                 dut.IF_ID_instr,
                 dut.WB_write_data);
    end

endmodule