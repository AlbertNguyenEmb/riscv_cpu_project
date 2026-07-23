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

        #2000;

        $display("==================================");
        $display("Level 13 AES-128 Crypto Accelerator Results:");

        $display("CRYPTO_BASE x1 = %h", dut.u_regfile.regs[1]);
        $display("CT0 x5 = %h", dut.u_regfile.regs[5]);
        $display("CT1 x6 = %h", dut.u_regfile.regs[6]);
        $display("CT2 x7 = %h", dut.u_regfile.regs[7]);
        $display("CT3 x8 = %h", dut.u_regfile.regs[8]);

        $display("AES ciphertext internal = %h", dut.u_crypto_accel.ciphertext_reg);
        $display("AES op_count = %0d", dut.u_crypto_accel.op_count);

        $display("DMEM CT = %h%h%h%h",
                 {dut.u_dmem.mem[3],  dut.u_dmem.mem[2],  dut.u_dmem.mem[1],  dut.u_dmem.mem[0]},
                 {dut.u_dmem.mem[7],  dut.u_dmem.mem[6],  dut.u_dmem.mem[5],  dut.u_dmem.mem[4]},
                 {dut.u_dmem.mem[11], dut.u_dmem.mem[10], dut.u_dmem.mem[9],  dut.u_dmem.mem[8]},
                 {dut.u_dmem.mem[15], dut.u_dmem.mem[14], dut.u_dmem.mem[13], dut.u_dmem.mem[12]});

        $display("==================================");

        if (dut.u_regfile.regs[1] == 32'h5000_0000 &&
            dut.u_regfile.regs[5] == 32'h69c4e0d8 &&
            dut.u_regfile.regs[6] == 32'h6a7b0430 &&
            dut.u_regfile.regs[7] == 32'hd8cdb780 &&
            dut.u_regfile.regs[8] == 32'h70b4c55a &&
            dut.u_crypto_accel.ciphertext_reg == 128'h69c4e0d86a7b0430d8cdb78070b4c55a &&
            dut.u_crypto_accel.op_count == 32'd1) begin

            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

    initial begin
        $monitor("time=%0t pc=%0d IF_ID=%h AES_busy=%b AES_done=%b CT=%h WB=%h",
                 $time,
                 dut.pc,
                 dut.IF_ID_instr,
                 dut.u_crypto_accel.aes_busy,
                 dut.u_crypto_accel.aes_done,
                 dut.u_crypto_accel.ciphertext_reg,
                 dut.WB_write_data);
    end

endmodule