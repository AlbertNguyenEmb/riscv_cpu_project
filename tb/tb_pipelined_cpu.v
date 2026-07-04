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

        #10000;

        $display("==================================");
        $display("Level 8 RV32IM Results:");

        $display("x1  = %0d", dut.u_regfile.regs[1]);
        $display("x2  = %0d", dut.u_regfile.regs[2]);
        $display("x3  = %0d", dut.u_regfile.regs[3]);
        $display("x4  = %h",  dut.u_regfile.regs[4]);
        $display("x5  = %h",  dut.u_regfile.regs[5]);
        $display("x6  = %h",  dut.u_regfile.regs[6]);
        $display("x7  = %h",  dut.u_regfile.regs[7]);
        $display("x8  = %h",  dut.u_regfile.regs[8]);
        $display("x9  = %0d", dut.u_regfile.regs[9]);
        $display("x10 = %0d", dut.u_regfile.regs[10]);

        $display("x12 = %h",  dut.u_regfile.regs[12]);
        $display("x13 = %h",  dut.u_regfile.regs[13]);
        $display("x14 = %0d", dut.u_regfile.regs[14]);
        $display("x15 = %0d", dut.u_regfile.regs[15]);
        $display("x16 = %0d", dut.u_regfile.regs[16]);
        $display("x17 = %h",  dut.u_regfile.regs[17]);
        $display("x18 = %0d", dut.u_regfile.regs[18]);

        $display("DMEM[0..3]  = %h %h %h %h",
                 dut.u_dmem.mem[3], dut.u_dmem.mem[2],
                 dut.u_dmem.mem[1], dut.u_dmem.mem[0]);

        $display("DMEM[4..7]  = %h %h %h %h",
                 dut.u_dmem.mem[7], dut.u_dmem.mem[6],
                 dut.u_dmem.mem[5], dut.u_dmem.mem[4]);

        $display("DMEM[8..11] = %h %h %h %h",
                 dut.u_dmem.mem[11], dut.u_dmem.mem[10],
                 dut.u_dmem.mem[9],  dut.u_dmem.mem[8]);

        $display("==================================");

        if (dut.u_regfile.regs[1]  == 32'd6 &&
            dut.u_regfile.regs[2]  == 32'd7 &&
            dut.u_regfile.regs[3]  == 32'd42 &&
            dut.u_regfile.regs[4]  == 32'hffff_fffa &&
            dut.u_regfile.regs[5]  == 32'hffff_ffd6 &&
            dut.u_regfile.regs[6]  == 32'hffff_ffff &&
            dut.u_regfile.regs[7]  == 32'h0000_0006 &&
            dut.u_regfile.regs[8]  == 32'hffff_ffff &&
            dut.u_regfile.regs[9]  == 32'd7 &&
            dut.u_regfile.regs[10] == 32'd0 &&
            dut.u_regfile.regs[12] == 32'hffff_ffd6 &&
            dut.u_regfile.regs[13] == 32'hffff_fffa &&
            dut.u_regfile.regs[14] == 32'd0 &&
            dut.u_regfile.regs[15] == 32'd6 &&
            dut.u_regfile.regs[16] == 32'd0 &&
            dut.u_regfile.regs[17] == 32'hffff_ffff &&
            dut.u_regfile.regs[18] == 32'd6 &&
            {dut.u_dmem.mem[3], dut.u_dmem.mem[2],
             dut.u_dmem.mem[1], dut.u_dmem.mem[0]} == 32'd42 &&
            {dut.u_dmem.mem[7], dut.u_dmem.mem[6],
             dut.u_dmem.mem[5], dut.u_dmem.mem[4]} == 32'hffff_fffa &&
            {dut.u_dmem.mem[11], dut.u_dmem.mem[10],
             dut.u_dmem.mem[9],  dut.u_dmem.mem[8]} == 32'hffff_ffff) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d stall=%b M_busy=%b M_done=%b IF_ID=%h ID_EX_rd=%0d EX_MEM_rd=%0d MEM_WB_rd=%0d WB_data=%h",
                 $time,
                 dut.pc,
                 dut.stall,
                 dut.M_busy,
                 dut.M_done,
                 dut.IF_ID_instr,
                 dut.ID_EX_rd,
                 dut.EX_MEM_rd,
                 dut.MEM_WB_rd,
                 dut.WB_write_data);
    end

endmodule