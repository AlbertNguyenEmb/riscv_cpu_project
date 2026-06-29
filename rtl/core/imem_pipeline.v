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

        // 0x00: addi x1, x0, 10
        // 0x04: addi x2, x0, 10
        // 0x08: beq  x1, x2, equal
        // 0x0C: addi x3, x0, 111     // must be flushed
        // 0x10: addi x3, x0, 112     // must be flushed
        // equal:
        // 0x14: addi x3, x0, 30
        // 0x18: addi x4, x0, 1
        // 0x1C: bne  x1, x2, not_equal // not taken
        // 0x20: addi x4, x4, 4
        // 0x24: jal  x5, jump_target
        // 0x28: addi x6, x0, 111     // must be flushed
        // 0x2C: addi x6, x0, 112     // must be flushed
        // jump_target:
        // 0x30: addi x6, x0, 60
        // 0x34: addi x7, x0, 64
        // 0x38: jalr x8, 0(x7)
        // 0x3C: addi x9, x0, 111     // must be flushed
        // 0x40: addi x9, x0, 90
        // 0x44: add  x10, x3, x9
        // 0x48: sw   x10, 0(x0)

        mem[0]  = 32'h00a00093; // addi x1, x0, 10
        mem[1]  = 32'h00a00113; // addi x2, x0, 10
        mem[2]  = 32'h00208663; // beq  x1, x2, +12
        mem[3]  = 32'h06f00193; // addi x3, x0, 111
        mem[4]  = 32'h07000193; // addi x3, x0, 112
        mem[5]  = 32'h01e00193; // addi x3, x0, 30

        mem[6]  = 32'h00100213; // addi x4, x0, 1
        mem[7]  = 32'h00209663; // bne  x1, x2, +12
        mem[8]  = 32'h00420213; // addi x4, x4, 4 

        mem[9]  = 32'h00c002ef; // jal x5, +12
        mem[10] = 32'h06f00313; // addi x6, x0, 111
        mem[11] = 32'h07000313; // addi x6, x0, 112
        mem[12] = 32'h03c00313; // addi x6, x0, 60

        mem[13] = 32'h04000393; // addi x7, x0, 64
        mem[14] = 32'h00038467; // jalr x8, 0(x7)
        mem[15] = 32'h06f00493; // addi x9, x0, 111
        mem[16] = 32'h05a00493; // addi x9, x0, 90

        mem[17] = 32'h00918533; // add x10, x3, x9
        mem[18] = 32'h00a02023; // sw x10, 0(x0)
    end

    assign instr = mem[addr[9:2]];

endmodule