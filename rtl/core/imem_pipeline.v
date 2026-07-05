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
        // DSP_CTRL      = 0x3000_0000
        // DSP_A         = 0x3000_0008
        // DSP_B         = 0x3000_000C
        // DSP_RESULT_LO = 0x3000_0010
        // DSP_COUNT     = 0x3000_0018
        //
        // Compute:
        // ACC = 1*10 + 2*20 + 3*30 = 140

        mem[0]  = 32'h300000b7; // lui  x1, 0x30000       ; x1 = 0x3000_0000

        mem[1]  = 32'h00200113; // addi x2, x0, 2         ; clear bit
        mem[2]  = 32'h0020a023; // sw   x2, 0(x1)         ; DSP_CTRL = clear

        mem[3]  = 32'h00100193; // addi x3, x0, 1
        mem[4]  = 32'h00a00213; // addi x4, x0, 10
        mem[5]  = 32'h0030a423; // sw   x3, 8(x1)         ; DSP_A = 1
        mem[6]  = 32'h0040a623; // sw   x4, 12(x1)        ; DSP_B = 10
        mem[7]  = 32'h00100113; // addi x2, x0, 1         ; start bit
        mem[8]  = 32'h0020a023; // sw   x2, 0(x1)         ; start MAC

        mem[9]  = 32'h00200193; // addi x3, x0, 2
        mem[10] = 32'h01400213; // addi x4, x0, 20
        mem[11] = 32'h0030a423; // sw   x3, 8(x1)         ; DSP_A = 2
        mem[12] = 32'h0040a623; // sw   x4, 12(x1)        ; DSP_B = 20
        mem[13] = 32'h0020a023; // sw   x2, 0(x1)         ; start MAC

        mem[14] = 32'h00300193; // addi x3, x0, 3
        mem[15] = 32'h01e00213; // addi x4, x0, 30
        mem[16] = 32'h0030a423; // sw   x3, 8(x1)         ; DSP_A = 3
        mem[17] = 32'h0040a623; // sw   x4, 12(x1)        ; DSP_B = 30
        mem[18] = 32'h0020a023; // sw   x2, 0(x1)         ; start MAC

        mem[19] = 32'h0100a283; // lw   x5, 16(x1)        ; x5 = RESULT_LO
        mem[20] = 32'h0180a303; // lw   x6, 24(x1)        ; x6 = COUNT

        mem[21] = 32'h00502023; // sw   x5, 0(x0)         ; DMEM[0] = 140
        mem[22] = 32'h00602223; // sw   x6, 4(x0)         ; DMEM[4] = 3
    end

    assign instr = mem[addr[9:2]];

endmodule