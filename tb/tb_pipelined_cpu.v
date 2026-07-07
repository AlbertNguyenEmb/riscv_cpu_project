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
        $display("Level 12 AI INT8 Dot-Product Accelerator Results:");

        $display("AI_BASE x1       = %h", dut.u_regfile.regs[1]);
        $display("ACC_LO x5        = %0d", dut.u_regfile.regs[5]);
        $display("LAST_DOT x6      = %0d", $signed(dut.u_regfile.regs[6]));
        $display("AI_COUNT x7      = %0d", dut.u_regfile.regs[7]);

        $display("AI vec A         = %h", dut.u_ai_accel.vec_a_reg);
        $display("AI vec B         = %h", dut.u_ai_accel.vec_b_reg);
        $display("AI ACC           = %0d", dut.u_ai_accel.acc_reg);
        $display("AI LAST DOT      = %0d", dut.u_ai_accel.last_dot_reg);
        $display("AI COUNT         = %0d", dut.u_ai_accel.dot_count);

        $display("DMEM[0..3] ACC       = %h %h %h %h",
                 dut.u_dmem.mem[3],
                 dut.u_dmem.mem[2],
                 dut.u_dmem.mem[1],
                 dut.u_dmem.mem[0]);

        $display("DMEM[4..7] LAST_DOT  = %h %h %h %h",
                 dut.u_dmem.mem[7],
                 dut.u_dmem.mem[6],
                 dut.u_dmem.mem[5],
                 dut.u_dmem.mem[4]);

        $display("DMEM[8..11] COUNT    = %h %h %h %h",
                 dut.u_dmem.mem[11],
                 dut.u_dmem.mem[10],
                 dut.u_dmem.mem[9],
                 dut.u_dmem.mem[8]);

        $display("==================================");

        if (dut.u_regfile.regs[1] == 32'h4000_0000 &&
            dut.u_regfile.regs[5] == 32'd294 &&
            dut.u_regfile.regs[6] == 32'hffff_fffa &&
            dut.u_regfile.regs[7] == 32'd2 &&
            dut.u_ai_accel.acc_reg == 64'd294 &&
            dut.u_ai_accel.last_dot_reg == 32'hffff_fffa &&
            dut.u_ai_accel.dot_count == 32'd2 &&
            {dut.u_dmem.mem[3], dut.u_dmem.mem[2],
             dut.u_dmem.mem[1], dut.u_dmem.mem[0]} == 32'd294 &&
            {dut.u_dmem.mem[7], dut.u_dmem.mem[6],
             dut.u_dmem.mem[5], dut.u_dmem.mem[4]} == 32'hffff_fffa &&
            {dut.u_dmem.mem[11], dut.u_dmem.mem[10],
             dut.u_dmem.mem[9], dut.u_dmem.mem[8]} == 32'd2) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d IF_ID=%h AI_ACC=%0d AI_LAST=%0d AI_COUNT=%0d WB_data=%h",
                 $time,
                 dut.pc,
                 dut.IF_ID_instr,
                 dut.u_ai_accel.acc_reg,
                 dut.u_ai_accel.last_dot_reg,
                 dut.u_ai_accel.dot_count,
                 dut.WB_write_data);
    end

endmodule