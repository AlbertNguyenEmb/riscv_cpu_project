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

        $readmemh("D:/Projects/riscv_cpu_project/instructions.hex", mem);
    end

    assign instr = mem[addr[9:2]];

endmodule