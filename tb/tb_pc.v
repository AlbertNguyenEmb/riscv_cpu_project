`timescale 1ns/1ps

module tb_pc;

    reg         clk;
    reg         rst;
    reg         stall;
    reg         pc_src;
    reg  [31:0] pc_target;
    wire [31:0] pc_out;

    pc uut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_src(pc_src),
        .pc_target(pc_target),
        .pc_out(pc_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst       = 1;
        stall     = 0;
        pc_src    = 0;
        pc_target = 32'b0;

        #12;
        rst = 0;

        // Normal PC increment
        #10;
        #10;
        #10;

        // Stall PC
        stall = 1;
        #20;
        stall = 0;

        // Jump PC to address 100
        pc_src    = 1;
        pc_target = 32'd100;
        #10;
        pc_src    = 0;

        // Continue normal increment
        #10;
        #10;

        $finish;
    end

    initial begin
        $monitor("time=%0t rst=%b stall=%b pc_src=%b pc_target=%d pc_out=%d",
                 $time, rst, stall, pc_src, pc_target, pc_out);
    end

endmodule