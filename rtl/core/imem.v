`timescale 1ns/1ps

module imem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'h00000013; // NOP = addi x0, x0, 0
        end

        // Program test:
        // addi x1, x0, 10
        // addi x2, x0, 20
        // add  x3, x1, x2
        // sw   x3, 0(x0)
        // lw   x4, 0(x0)
        // sub  x5, x4, x1
        // sw   x5, 4(x0)

        mem[0] = 32'h00a00093; // addi x1, x0, 10
        mem[1] = 32'h01400113; // addi x2, x0, 20
        mem[2] = 32'h002081b3; // add  x3, x1, x2
        mem[3] = 32'h00302023; // sw   x3, 0(x0)
        mem[4] = 32'h00002203; // lw   x4, 0(x0)
        mem[5] = 32'h401202b3; // sub  x5, x4, x1
        mem[6] = 32'h00502223; // sw   x5, 4(x0)
    end

    assign instr = mem[addr[9:2]];

endmodule