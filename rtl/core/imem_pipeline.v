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

        mem[0]  = 32'h500000b7; // lui x1,0x50000
        mem[1]  = 32'h00200193; // addi x3,x0,2
        mem[2]  = 32'h0030a023; // sw x3,0(x1) clear

        mem[3]  = 32'h00112137; // lui x2,0x00112
        mem[4]  = 32'h23310113; // addi x2,x2,0x233
        mem[5]  = 32'h0020a823; // sw x2,16(x1) ; PT0 = 00112233

        mem[6]  = 32'h44556137; // lui x2,0x44556
        mem[7]  = 32'h67710113; // addi x2,x2,0x677
        mem[8]  = 32'h0020aa23; // sw x2,20(x1) ; PT1 = 44556677

        mem[9]  = 32'h8899b137; // lui x2,0x8899b
        mem[10] = 32'habb10113; // addi x2,x2,-1349
        mem[11] = 32'h0020ac23; // sw x2,24(x1) ; PT2 = 8899aabb

        mem[12] = 32'hccddf137; // lui x2,0xccddf
        mem[13] = 32'heff10113; // addi x2,x2,-257
        mem[14] = 32'h0020ae23; // sw x2,28(x1) ; PT3 = ccddeeff

        mem[15] = 32'h00010137; // lui x2,0x00010
        mem[16] = 32'h20310113; // addi x2,x2,0x203
        mem[17] = 32'h0220a023; // sw x2,32(x1) ; KEY0 = 00010203

        mem[18] = 32'h04050137; // lui x2,0x04050
        mem[19] = 32'h60710113; // addi x2,x2,0x607
        mem[20] = 32'h0220a223; // sw x2,36(x1) ; KEY1 = 04050607

        mem[21] = 32'h08091137; // lui x2,0x08091
        mem[22] = 32'ha0b10113; // addi x2,x2,-1525
        mem[23] = 32'h0220a423; // sw x2,40(x1) ; KEY2 = 08090a0b

        mem[24] = 32'h0c0d1137; // lui x2,0x0c0d1
        mem[25] = 32'he0f10113; // addi x2,x2,-497
        mem[26] = 32'h0220a623; // sw x2,44(x1) ; KEY3 = 0c0d0e0f

        mem[27] = 32'h00100193; // addi x3,x0,1
        mem[28] = 32'h0030a023; // sw x3,0(x1) start

        mem[29] = 32'h00000013; // nop
        mem[30] = 32'h00000013; // nop
        mem[31] = 32'h00000013; // nop
        mem[32] = 32'h00000013; // nop
        mem[33] = 32'h00000013; // nop
        mem[34] = 32'h00000013; // nop
        mem[35] = 32'h00000013; // nop
        mem[36] = 32'h00000013; // nop
        mem[37] = 32'h00000013; // nop
        mem[38] = 32'h00000013; // nop
        mem[39] = 32'h00000013; // nop
        mem[40] = 32'h00000013; // nop
        mem[41] = 32'h00000013; // nop
        mem[42] = 32'h00000013; // nop
        mem[43] = 32'h00000013; // nop
        mem[44] = 32'h00000013; // nop
        mem[45] = 32'h00000013; // nop
        mem[46] = 32'h00000013; // nop
        mem[47] = 32'h00000013; // nop
        mem[48] = 32'h00000013; // nop

        mem[49] = 32'h0300a283; // lw x5,48(x1) ; CT0
        mem[50] = 32'h0340a303; // lw x6,52(x1) ; CT1
        mem[51] = 32'h0380a383; // lw x7,56(x1) ; CT2
        mem[52] = 32'h03c0a403; // lw x8,60(x1) ; CT3

        mem[53] = 32'h00502023; // sw x5,0(x0)
        mem[54] = 32'h00602223; // sw x6,4(x0)
        mem[55] = 32'h00702423; // sw x7,8(x0)
        mem[56] = 32'h00802623; // sw x8,12(x0)
    end

    assign instr = mem[addr[9:2]];

endmodule