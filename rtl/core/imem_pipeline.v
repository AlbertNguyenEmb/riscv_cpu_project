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

        mem[0]  = 32'h00600093; // addi x1, x0, 6
        mem[1]  = 32'h00700113; // addi x2, x0, 7

        mem[2]  = 32'h022081b3; // mul    x3, x1, x2      => 42

        mem[3]  = 32'hffa00213; // addi   x4, x0, -6
        mem[4]  = 32'h022202b3; // mul    x5, x4, x2      => -42
        mem[5]  = 32'h02221333; // mulh   x6, x4, x2      => high signed(-42)
        mem[6]  = 32'h022233b3; // mulhu  x7, x4, x2      => high unsigned
        mem[7]  = 32'h02222433; // mulhsu x8, x4, x2      => high signed*unsigned

        mem[8]  = 32'h0211c4b3; // div    x9,  x3, x1     => 7
        mem[9]  = 32'h0211e533; // rem    x10, x3, x1     => 0

        mem[10] = 32'hfd600613; // addi   x12, x0, -42
        mem[11] = 32'h022646b3; // div    x13, x12, x2    => -6
        mem[12] = 32'h02266733; // rem    x14, x12, x2    => 0

        mem[13] = 32'h0221d7b3; // divu   x15, x3, x2     => 6
        mem[14] = 32'h0221f833; // remu   x16, x3, x2     => 0

        mem[15] = 32'h0200c8b3; // div    x17, x1, x0     => 0xffffffff
        mem[16] = 32'h0200e933; // rem    x18, x1, x0     => 6

        mem[17] = 32'h00302023; // sw x3,  0(x0)
        mem[18] = 32'h00d02223; // sw x13, 4(x0)
        mem[19] = 32'h01102423; // sw x17, 8(x0)
    end

    assign instr = mem[addr[9:2]];

endmodule