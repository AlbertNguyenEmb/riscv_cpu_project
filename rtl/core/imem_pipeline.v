`timescale 1ns/1ps

module imm_pipeline (
    input wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'h00000013;
        end

        // Program test with manual NOPs because Level 4 has no hazard unit yet.
        //
        // addi x1, x0, 10
        // addi x2, x0, 20
        // addi x6, x0, 1
        // addi x7, x0, 2
        // addi x8, x0, 3
        // addi x9, x0, 4
        // add  x3, x1, x2
        // nop
        // nop
        // nop
        // nop
        // sw   x3, 0(x0)
        // nop
        // nop
        // nop
        // nop
        // lw   x4, 0(x0)
        // nop
        // nop
        // nop
        // nop
        // sub  x5, x4, x1
        // nop
        // nop
        // nop
        // nop
        // sw   x5, 4(x0)

        mem[0]  = 32'h00a00093; // addi x1, x0, 10
        mem[1]  = 32'h01400113; // addi x2, x0, 20
        mem[2]  = 32'h00100313; // addi x6, x0, 1
        mem[3]  = 32'h00200393; // addi x7, x0, 2
        mem[4]  = 32'h00300413; // addi x8, x0, 3
        mem[5]  = 32'h00400493; // addi x9, x0, 4

        mem[6]  = 32'h002081b3; // add x3, x1, x2

        mem[7]  = 32'h00000013; // nop
        mem[8]  = 32'h00000013; // nop
        mem[9]  = 32'h00000013; // nop
        mem[10] = 32'h00000013; // nop

        mem[11] = 32'h00302023; // sw x3, 0(x0)

        mem[12] = 32'h00000013; // nop
        mem[13] = 32'h00000013; // nop
        mem[14] = 32'h00000013; // nop
        mem[15] = 32'h00000013; // nop

        mem[16] = 32'h00002203; // lw x4, 0(x0)

        mem[17] = 32'h00000013; // nop
        mem[18] = 32'h00000013; // nop
        mem[19] = 32'h00000013; // nop
        mem[20] = 32'h00000013; // nop

        mem[21] = 32'h401202b3; // sub x5, x4, x1

        mem[22] = 32'h00000013; // nop
        mem[23] = 32'h00000013; // nop
        mem[24] = 32'h00000013; // nop
        mem[25] = 32'h00000013; // nop

        mem[26] = 32'h00502223; // sw x5, 4(x0)
    end

    assign instr = mem[addr[9:2]];
endmodule