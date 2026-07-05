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

        #1000;

        $display("==================================");
        $display("Level 10 DSP Accelerator Results:");

        $display("DSP_BASE x1      = %h", dut.u_regfile.regs[1]);
        $display("DSP_RESULT x5    = %0d", dut.u_regfile.regs[5]);
        $display("DSP_COUNT x6     = %0d", dut.u_regfile.regs[6]);

        $display("DSP internal A   = %0d", dut.u_dsp_accel.a_reg);
        $display("DSP internal B   = %0d", dut.u_dsp_accel.b_reg);
        $display("DSP internal ACC = %0d", dut.u_dsp_accel.acc_reg);
        $display("DSP MAC count    = %0d", dut.u_dsp_accel.mac_count);

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
            dut.u_regfile.regs[5] == 32'd140 &&
            dut.u_regfile.regs[6] == 32'd3 &&
            dut.u_dsp_accel.acc_reg == 64'd140 &&
            dut.u_dsp_accel.mac_count == 32'd3 &&
            {dut.u_dmem.mem[3], dut.u_dmem.mem[2],
             dut.u_dmem.mem[1], dut.u_dmem.mem[0]} == 32'd140 &&
            {dut.u_dmem.mem[7], dut.u_dmem.mem[6],
             dut.u_dmem.mem[5], dut.u_dmem.mem[4]} == 32'd3) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d IF_ID=%h DSP_ACC=%0d DSP_COUNT=%0d WB_data=%h",
                 $time,
                 dut.pc,
                 dut.IF_ID_instr,
                 dut.u_dsp_accel.acc_reg,
                 dut.u_dsp_accel.mac_count,
                 dut.WB_write_data);
    end

endmodule