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

        mem[0]  = 32'h123450b7; // lui   x1, 0x12345
        mem[1]  = 32'h00001117; // auipc x2, 0x1
        mem[2]  = 32'hfff00193; // addi  x3, x0, -1

        mem[3]  = 32'h0001a213; // slti  x4, x3, 0
        mem[4]  = 32'h0011b293; // sltiu x5, x3, 1

        mem[5]  = 32'h00421313; // slli  x6, x4, 4
        mem[6]  = 32'h00135393; // srli  x7, x6, 1
        mem[7]  = 32'h4041d413; // srai  x8, x3, 4

        mem[8]  = 32'h07f00513; // addi x10, x0, 127
        mem[9]  = 32'h00a00023; // sb   x10, 0(x0)
        mem[10] = 32'h00000583; // lb   x11, 0(x0)
        mem[11] = 32'h00004603; // lbu  x12, 0(x0)

        mem[12] = 32'hfff00693; // addi x13, x0, -1
        mem[13] = 32'h00d000a3; // sb   x13, 1(x0)
        mem[14] = 32'h00100703; // lb   x14, 1(x0)
        mem[15] = 32'h00104783; // lbu  x15, 1(x0)

        mem[16] = 32'h12300813; // addi x16, x0, 291
        mem[17] = 32'h01001223; // sh   x16, 4(x0)
        mem[18] = 32'h00401883; // lh   x17, 4(x0)
        mem[19] = 32'h00405903; // lhu  x18, 4(x0)

        mem[20] = 32'hfff00993; // addi x19, x0, -1
        mem[21] = 32'h01301323; // sh   x19, 6(x0)
        mem[22] = 32'h00601a03; // lh   x20, 6(x0)
        mem[23] = 32'h00605a83; // lhu  x21, 6(x0)

        mem[24] = 32'h00102423; // sw   x1, 8(x0)
        mem[25] = 32'h00802b03; // lw   x22, 8(x0)
        mem[26] = 32'h000b0c33; // add  x24, x22, x0  // load-use test

        mem[27] = 32'h00c58bb3; // add  x23, x11, x12
        mem[28] = 32'h01702623; // sw   x23, 12(x0)
    end

    assign instr = mem[addr[9:2]];

endmodule