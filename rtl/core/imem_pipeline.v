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

        // AI_BASE = 0x4000_0000
        //
        // AI_CTRL     = 0x4000_0000
        // AI_VEC_A    = 0x4000_0008
        // AI_VEC_B    = 0x4000_000C
        // AI_ACC_LO   = 0x4000_0010
        // AI_LAST_DOT = 0x4000_0018
        // AI_COUNT    = 0x4000_001C

        mem[0]  = 32'h400000b7; // lui  x1, 0x40000       ; x1 = 0x4000_0000

        mem[1]  = 32'h00200213; // addi x4, x0, 2
        mem[2]  = 32'h0040a023; // sw   x4, 0(x1)         ; AI_CTRL = clear

        // A1 = [1,2,3,4] packed = 0x04030201
        mem[3]  = 32'h04030137; // lui  x2, 0x04030
        mem[4]  = 32'h20110113; // addi x2, x2, 0x201

        // B1 = [10,20,30,40] packed = 0x281E140A
        mem[5]  = 32'h281e11b7; // lui  x3, 0x281e1
        mem[6]  = 32'h40a18193; // addi x3, x3, 0x40a

        mem[7]  = 32'h0020a423; // sw   x2, 8(x1)         ; AI_VEC_A
        mem[8]  = 32'h0030a623; // sw   x3, 12(x1)        ; AI_VEC_B

        mem[9]  = 32'h00100213; // addi x4, x0, 1
        mem[10] = 32'h0040a023; // sw   x4, 0(x1)         ; start dot4

        // A2 = [-1,-2,3,4] packed = 0x0403FEFF
        mem[11] = 32'h04040137; // lui  x2, 0x04040
        mem[12] = 32'heff10113; // addi x2, x2, -257

        // B2 = [5,6,-7,8] packed = 0x08F90605
        mem[13] = 32'h08f901b7; // lui  x3, 0x08f90
        mem[14] = 32'h60518193; // addi x3, x3, 0x605

        mem[15] = 32'h0020a423; // sw   x2, 8(x1)         ; AI_VEC_A
        mem[16] = 32'h0030a623; // sw   x3, 12(x1)        ; AI_VEC_B
        mem[17] = 32'h0040a023; // sw   x4, 0(x1)         ; start dot4

        mem[18] = 32'h0100a283; // lw   x5, 16(x1)        ; x5 = ACC_LO = 294
        mem[19] = 32'h0180a303; // lw   x6, 24(x1)        ; x6 = LAST_DOT = -6
        mem[20] = 32'h01c0a383; // lw   x7, 28(x1)        ; x7 = COUNT = 2

        mem[21] = 32'h00502023; // sw   x5, 0(x0)         ; DMEM[0] = 294
        mem[22] = 32'h00602223; // sw   x6, 4(x0)         ; DMEM[4] = -6
        mem[23] = 32'h00702423; // sw   x7, 8(x0)         ; DMEM[8] = 2
    end

    assign instr = mem[addr[9:2]];

endmodule