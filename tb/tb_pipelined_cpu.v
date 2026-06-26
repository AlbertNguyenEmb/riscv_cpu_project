`timescale 1ns/1ps

module tb_pipelined_cpu;

    reg clk;
    reg rst;

    pipelined_cpu dut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #12;
        rst = 0;

        // Need enough cycles for pipeline to fill and drain
        #700;

        $display("==================================");
        $display("Pipelined CPU Results:");
        $display("x1 = %0d", dut.u_regfile.regs[1]);
        $display("x2 = %0d", dut.u_regfile.regs[2]);
        $display("x3 = %0d", dut.u_regfile.regs[3]);
        $display("x4 = %0d", dut.u_regfile.regs[4]);
        $display("x5 = %0d", dut.u_regfile.regs[5]);
        $display("x6 = %0d", dut.u_regfile.regs[6]);
        $display("x7 = %0d", dut.u_regfile.regs[7]);
        $display("x8 = %0d", dut.u_regfile.regs[8]);
        $display("x9 = %0d", dut.u_regfile.regs[9]);

        $display("DMEM[0] = %0d", dut.u_dmem.mem[0]);
        $display("DMEM[1] = %0d", dut.u_dmem.mem[1]);
        $display("==================================");

        if (dut.u_regfile.regs[1] == 32'd10 &&
            dut.u_regfile.regs[2] == 32'd20 &&
            dut.u_regfile.regs[3] == 32'd30 &&
            dut.u_regfile.regs[4] == 32'd30 &&
            dut.u_regfile.regs[5] == 32'd20 &&
            dut.u_dmem.mem[0] == 32'd30 &&
            dut.u_dmem.mem[1] == 32'd20) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d IF_ID_instr=%h ID_EX_rd=%0d EX_MEM_rd=%0d MEM_WB_rd=%0d WB_data=%0d",
                 $time,
                 dut.pc,
                 dut.IF_ID_instr,
                 dut.ID_EX_rd,
                 dut.EX_MEM_rd,
                 dut.MEM_WB_rd,
                 dut.WB_write_data);
    end

endmodule