`timescale 1ns/1ps

module tb_multi_cycle_cpu ();
    reg clk;
    reg rst;

    multi_cycle_cpu dut (
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

        #400;

        $display("==================================");
        $display("Multi-cycle CPU Results:");
        $display("x1 = %0d", dut.u_regfile.regs[1]);
        $display("x2 = %0d", dut.u_regfile.regs[2]);
        $display("x3 = %0d", dut.u_regfile.regs[3]);
        $display("x4 = %0d", dut.u_regfile.regs[4]);
        $display("x5 = %0d", dut.u_regfile.regs[5]);

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
        $monitor("time=%0t state=%0d pc=%0d ir=%h A=%0d B=%0d alu_out=%0d mdr=%0d",
                 $time,
                 dut.state,
                 dut.pc,
                 dut.ir,
                 dut.A,
                 dut.B,
                 dut.alu_out,
                 dut.mdr);
    end

endmodule