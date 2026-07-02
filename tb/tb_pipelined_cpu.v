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

        #900;

        $display("==================================");
        $display("Level 7 RV32I Practical Subset Results:");

        $display("x1  = %h", dut.u_regfile.regs[1]);
        $display("x2  = %h", dut.u_regfile.regs[2]);
        $display("x3  = %h", dut.u_regfile.regs[3]);
        $display("x4  = %0d", dut.u_regfile.regs[4]);
        $display("x5  = %0d", dut.u_regfile.regs[5]);
        $display("x6  = %0d", dut.u_regfile.regs[6]);
        $display("x7  = %0d", dut.u_regfile.regs[7]);
        $display("x8  = %h", dut.u_regfile.regs[8]);

        $display("x11 = %0d", dut.u_regfile.regs[11]);
        $display("x12 = %0d", dut.u_regfile.regs[12]);
        $display("x14 = %h", dut.u_regfile.regs[14]);
        $display("x15 = %0d", dut.u_regfile.regs[15]);

        $display("x17 = %0d", dut.u_regfile.regs[17]);
        $display("x18 = %0d", dut.u_regfile.regs[18]);
        $display("x20 = %h", dut.u_regfile.regs[20]);
        $display("x21 = %0d", dut.u_regfile.regs[21]);

        $display("x22 = %h", dut.u_regfile.regs[22]);
        $display("x23 = %0d", dut.u_regfile.regs[23]);
        $display("x24 = %h", dut.u_regfile.regs[24]);

        $display("DMEM[12] = %h", dut.u_dmem.mem[12]);
        $display("DMEM[13] = %h", dut.u_dmem.mem[13]);
        $display("DMEM[14] = %h", dut.u_dmem.mem[14]);
        $display("DMEM[15] = %h", dut.u_dmem.mem[15]);

        $display("==================================");

        if (dut.u_regfile.regs[1]  == 32'h12345000 &&
            dut.u_regfile.regs[2]  == 32'h00001004 &&
            dut.u_regfile.regs[3]  == 32'hffff_ffff &&
            dut.u_regfile.regs[4]  == 32'd1 &&
            dut.u_regfile.regs[5]  == 32'd0 &&
            dut.u_regfile.regs[6]  == 32'd16 &&
            dut.u_regfile.regs[7]  == 32'd8 &&
            dut.u_regfile.regs[8]  == 32'hffff_ffff &&

            dut.u_regfile.regs[11] == 32'd127 &&
            dut.u_regfile.regs[12] == 32'd127 &&
            dut.u_regfile.regs[14] == 32'hffff_ffff &&
            dut.u_regfile.regs[15] == 32'd255 &&

            dut.u_regfile.regs[17] == 32'd291 &&
            dut.u_regfile.regs[18] == 32'd291 &&
            dut.u_regfile.regs[20] == 32'hffff_ffff &&
            dut.u_regfile.regs[21] == 32'd65535 &&

            dut.u_regfile.regs[22] == 32'h12345000 &&
            dut.u_regfile.regs[23] == 32'd254 &&
            dut.u_regfile.regs[24] == 32'h12345000 &&

            dut.u_dmem.mem[12] == 8'hfe &&
            dut.u_dmem.mem[13] == 8'h00 &&
            dut.u_dmem.mem[14] == 8'h00 &&
            dut.u_dmem.mem[15] == 8'h00) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d stall=%b IF_ID=%h ID_EX_rd=%0d EX_MEM_rd=%0d MEM_WB_rd=%0d WB_data=%h",
                 $time,
                 dut.pc,
                 dut.stall,
                 dut.IF_ID_instr,
                 dut.ID_EX_rd,
                 dut.EX_MEM_rd,
                 dut.MEM_WB_rd,
                 dut.WB_write_data);
    end

endmodule