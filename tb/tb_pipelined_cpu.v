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
        gpio_in = 32'h0000_0000;

        rst = 1;
        #12;
        rst = 0;

        #1200;

        $display("==================================");
        $display("Level 11 FIR Accelerator Results:");

        $display("DSP_BASE x1        = %h", dut.u_regfile.regs[1]);
        $display("FIR_RESULT x5      = %0d", dut.u_regfile.regs[5]);
        $display("FIR_COUNT x6       = %0d", dut.u_regfile.regs[6]);

        $display("FIR_X0             = %0d", dut.u_dsp_accel.fir_x0);
        $display("FIR_X1             = %0d", dut.u_dsp_accel.fir_x1);
        $display("FIR_X2             = %0d", dut.u_dsp_accel.fir_x2);
        $display("FIR_X3             = %0d", dut.u_dsp_accel.fir_x3);

        $display("FIR_H0             = %0d", dut.u_dsp_accel.fir_h0);
        $display("FIR_H1             = %0d", dut.u_dsp_accel.fir_h1);
        $display("FIR_H2             = %0d", dut.u_dsp_accel.fir_h2);
        $display("FIR_H3             = %0d", dut.u_dsp_accel.fir_h3);

        $display("FIR internal ACC   = %0d", dut.u_dsp_accel.fir_acc_reg);
        $display("FIR internal count = %0d", dut.u_dsp_accel.fir_count);
        $display("FIR busy           = %b",  dut.u_dsp_accel.fir_busy);
        $display("FIR done           = %b",  dut.u_dsp_accel.fir_done);

        $display("DMEM[0..3] = %h %h %h %h",
                 dut.u_dmem.mem[3],
                 dut.u_dmem.mem[2],
                 dut.u_dmem.mem[1],
                 dut.u_dmem.mem[0]);

        $display("DMEM[4..7] = %h %h %h %h",
                 dut.u_dmem.mem[7],
                 dut.u_dmem.mem[6],
                 dut.u_dmem.mem[5],
                 dut.u_dmem.mem[4]);

        $display("==================================");

        if (dut.u_regfile.regs[1] == 32'h3000_0000 &&
            dut.u_regfile.regs[5] == 32'd300 &&
            dut.u_regfile.regs[6] == 32'd1 &&
            dut.u_dsp_accel.fir_acc_reg == 64'd300 &&
            dut.u_dsp_accel.fir_count == 32'd1 &&
            {dut.u_dmem.mem[3], dut.u_dmem.mem[2],
             dut.u_dmem.mem[1], dut.u_dmem.mem[0]} == 32'd300 &&
            {dut.u_dmem.mem[7], dut.u_dmem.mem[6],
             dut.u_dmem.mem[5], dut.u_dmem.mem[4]} == 32'd1) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d IF_ID=%h FIR_busy=%b FIR_done=%b FIR_ACC=%0d FIR_COUNT=%0d WB_data=%h",
                 $time,
                 dut.pc,
                 dut.IF_ID_instr,
                 dut.u_dsp_accel.fir_busy,
                 dut.u_dsp_accel.fir_done,
                 dut.u_dsp_accel.fir_acc_reg,
                 dut.u_dsp_accel.fir_count,
                 dut.WB_write_data);
    end

endmodule