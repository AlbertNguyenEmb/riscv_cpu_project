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

        // GPIO base = 0x1000_0000
        // PERF base = 0x2000_0000

        mem[0]  = 32'h100000b7; // lui  x1, 0x10000      ; x1 = 0x1000_0000
        mem[1]  = 32'h05500113; // addi x2, x0, 0x55
        mem[2]  = 32'h0020a023; // sw   x2, 0(x1)        ; GPIO_OUT = 0x55
        mem[3]  = 32'h0040a183; // lw   x3, 4(x1)        ; x3 = GPIO_IN

        mem[4]  = 32'h20000237; // lui  x4, 0x20000      ; x4 = 0x2000_0000
        mem[5]  = 32'h00022283; // lw   x5, 0(x4)        ; cycle_count
        mem[6]  = 32'h00422303; // lw   x6, 4(x4)        ; instr_count

        // Create load-use stall
        mem[7]  = 32'h02a00493; // addi x9, x0, 42
        mem[8]  = 32'h00902823; // sw   x9, 16(x0)
        mem[9]  = 32'h01002503; // lw   x10, 16(x0)
        mem[10] = 32'h000505b3; // add  x11, x10, x0     ; load-use hazard

        // Create branch flush
        mem[11] = 32'h00958663; // beq  x11, x9, +12
        mem[12] = 32'h06f00613; // addi x12, x0, 111     ; flushed
        mem[13] = 32'h07000613; // addi x12, x0, 112     ; flushed
        mem[14] = 32'h04d00613; // addi x12, x0, 77      ; real target

        // GPIO_OUT = 42
        mem[15] = 32'h00b0a023; // sw   x11, 0(x1)

        // Read counters after stall/flush happened
        mem[16] = 32'h00822683; // lw   x13, 8(x4)       ; stall_count
        mem[17] = 32'h00c22703; // lw   x14, 12(x4)      ; flush_count

        // Store counters into DMEM for checking
        mem[18] = 32'h00d02a23; // sw   x13, 20(x0)
        mem[19] = 32'h00e02c23; // sw   x14, 24(x0)
    end

    assign instr = mem[addr[9:2]];

endmodule