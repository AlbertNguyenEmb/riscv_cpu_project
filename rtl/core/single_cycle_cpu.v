`timescale 1ns/1ps

module single_cycle_cpu (
    input wire clk,
    input wire rst
);

    wire [31:0] pc_out;
    wire [31:0] instr;

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        alu_src;
    wire [1:0]  imm_sel;
    wire [1:0]  alu_op;

    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] imm_out;

    wire [31:0] alu_b;
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_result;
    wire        zero;

    wire [31:0] dmem_read_data;
    wire [31:0] write_back_data;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    pc u_pc (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out)
    );

    imem u_imem (
        .addr(pc_out),
        .instr(instr)
    );

    control_unit u_control_unit (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .imm_sel(imm_sel),
        .alu_op(alu_op)
    );

    regfile u_regfile (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_back_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    imm_gen u_imm_gen (
        .instr(instr),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    assign alu_b = (alu_src) ? imm_out : read_data2;

    alu_control u_alu_control (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_ctrl(alu_ctrl)
    );

    alu u_alu (
        .a(read_data1),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    dmem u_dmem (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(alu_result),
        .write_data(read_data2),
        .read_data(dmem_read_data)
    );

    assign write_back_data = (mem_to_reg) ? dmem_read_data : alu_result;

endmodule
