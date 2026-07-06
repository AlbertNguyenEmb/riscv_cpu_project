`timescale 1ns/1ps

module imem_pipeline (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'h00000013; // NOP
        end

        // DSP_BASE = 0x3000_0000
        //
        // FIR_CTRL      = 0x3000_0020
        // FIR_X0        = 0x3000_0028
        // FIR_X1        = 0x3000_002C
        // FIR_X2        = 0x3000_0030
        // FIR_X3        = 0x3000_0034
        // FIR_H0        = 0x3000_0038
        // FIR_H1        = 0x3000_003C
        // FIR_H2        = 0x3000_0040
        // FIR_H3        = 0x3000_0044
        // FIR_RESULT_LO = 0x3000_0048
        // FIR_COUNT     = 0x3000_0050
        //
        // Compute:
        // y = 1*10 + 2*20 + 3*30 + 4*40 = 300

        mem[0]  = 32'h300000b7; // lui  x1, 0x30000       ; x1 = 0x3000_0000

        mem[1]  = 32'h00200213; // addi x4, x0, 2
        mem[2]  = 32'h0240a023; // sw   x4, 32(x1)        ; FIR_CTRL = clear

        mem[3]  = 32'h00100113; // addi x2, x0, 1
        mem[4]  = 32'h0220a423; // sw   x2, 40(x1)        ; FIR_X0 = 1

        mem[5]  = 32'h00200113; // addi x2, x0, 2
        mem[6]  = 32'h0220a623; // sw   x2, 44(x1)        ; FIR_X1 = 2

        mem[7]  = 32'h00300113; // addi x2, x0, 3
        mem[8]  = 32'h0220a823; // sw   x2, 48(x1)        ; FIR_X2 = 3

        mem[9]  = 32'h00400113; // addi x2, x0, 4
        mem[10] = 32'h0220aa23; // sw   x2, 52(x1)        ; FIR_X3 = 4

        mem[11] = 32'h00a00193; // addi x3, x0, 10
        mem[12] = 32'h0230ac23; // sw   x3, 56(x1)        ; FIR_H0 = 10

        mem[13] = 32'h01400193; // addi x3, x0, 20
        mem[14] = 32'h0230ae23; // sw   x3, 60(x1)        ; FIR_H1 = 20

        mem[15] = 32'h01e00193; // addi x3, x0, 30
        mem[16] = 32'h0430a023; // sw   x3, 64(x1)        ; FIR_H2 = 30

        mem[17] = 32'h02800193; // addi x3, x0, 40
        mem[18] = 32'h0430a223; // sw   x3, 68(x1)        ; FIR_H3 = 40

        mem[19] = 32'h00100213; // addi x4, x0, 1
        mem[20] = 32'h0240a023; // sw   x4, 32(x1)        ; FIR_CTRL = start

        // Wait several cycles for FIR FSM to finish
        mem[21] = 32'h00000013; // nop
        mem[22] = 32'h00000013; // nop
        mem[23] = 32'h00000013; // nop
        mem[24] = 32'h00000013; // nop
        mem[25] = 32'h00000013; // nop
        mem[26] = 32'h00000013; // nop
        mem[27] = 32'h00000013; // nop
        mem[28] = 32'h00000013; // nop

        mem[29] = 32'h0480a283; // lw   x5, 72(x1)        ; x5 = FIR_RESULT_LO
        mem[30] = 32'h0500a303; // lw   x6, 80(x1)        ; x6 = FIR_COUNT

        mem[31] = 32'h00502023; // sw   x5, 0(x0)         ; DMEM[0] = 300
        mem[32] = 32'h00602223; // sw   x6, 4(x0)         ; DMEM[4] = 1
    end

    assign instr = mem[addr[9:2]];

endmodule