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

        #700;

        $display("==================================");
        $display("Level 6 Pipeline CPU Results:");
        $display("x1  = %0d", dut.u_regfile.regs[1]);
        $display("x2  = %0d", dut.u_regfile.regs[2]);
        $display("x3  = %0d", dut.u_regfile.regs[3]);
        $display("x4  = %0d", dut.u_regfile.regs[4]);
        $display("x5  = %0d", dut.u_regfile.regs[5]);
        $display("x6  = %0d", dut.u_regfile.regs[6]);
        $display("x7  = %0d", dut.u_regfile.regs[7]);
        $display("x8  = %0d", dut.u_regfile.regs[8]);
        $display("x9  = %0d", dut.u_regfile.regs[9]);
        $display("x10 = %0d", dut.u_regfile.regs[10]);
        $display("DMEM[0] = %0d", dut.u_dmem.mem[0]);
        $display("==================================");

        if (dut.u_regfile.regs[1]  == 32'd10  &&
            dut.u_regfile.regs[2]  == 32'd10  &&
            dut.u_regfile.regs[3]  == 32'd30  &&
            dut.u_regfile.regs[4]  == 32'd5   &&
            dut.u_regfile.regs[5]  == 32'd40  &&
            dut.u_regfile.regs[6]  == 32'd60  &&
            dut.u_regfile.regs[7]  == 32'd64  &&
            dut.u_regfile.regs[8]  == 32'd60  &&
            dut.u_regfile.regs[9]  == 32'd90  &&
            dut.u_regfile.regs[10] == 32'd120 &&
            dut.u_dmem.mem[0]      == 32'd120) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d redirect=%b target=%0d stall=%b IF_ID=%h ID_EX_rd=%0d EX_MEM_rd=%0d MEM_WB_rd=%0d WB_data=%0d",
                 $time,
                 dut.pc,
                 dut.pc_redirect,
                 dut.EX_pc_target,
                 dut.stall,
                 dut.IF_ID_instr,
                 dut.ID_EX_rd,
                 dut.EX_MEM_rd,
                 dut.MEM_WB_rd,
                 dut.WB_write_data);
    end

endmodule