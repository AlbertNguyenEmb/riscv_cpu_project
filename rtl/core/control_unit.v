`timescale 1ns/1ps

module control_unit (
    input  wire [6:0] opcode,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg [2:0]  imm_sel,
    output reg [1:0]  alu_op,
    output reg        branch,
    output reg        jump,
    output reg        jalr,
    output reg [1:0]  alu_a_sel
);

    localparam OPCODE_RTYPE  = 7'b0110011;
    localparam OPCODE_ITYPE  = 7'b0010011;
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_LUI    = 7'b0110111;
    localparam OPCODE_AUIPC  = 7'b0010111;

    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_J = 3'b011;
    localparam IMM_U = 3'b100;

    localparam ALU_A_RS1  = 2'b00;
    localparam ALU_A_PC   = 2'b01;
    localparam ALU_A_ZERO = 2'b10;

    always @(*) begin
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        alu_src   = 1'b0;
        imm_sel   = IMM_I;
        alu_op    = 2'b00;
        branch    = 1'b0;
        jump      = 1'b0;
        jalr      = 1'b0;
        alu_a_sel = ALU_A_RS1;
        case (opcode)

            OPCODE_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
                alu_a_sel = ALU_A_RS1;
            end

            OPCODE_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_I;
                alu_op    = 2'b11;
                alu_a_sel = ALU_A_RS1;
            end

            OPCODE_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_I;
                alu_op    = 2'b00;
                alu_a_sel = ALU_A_RS1;
            end

            OPCODE_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_S;
                alu_op    = 2'b00;
                alu_a_sel = ALU_A_RS1;
            end

            OPCODE_BRANCH: begin
                branch  = 1'b1;
                imm_sel = IMM_B;
                alu_src = 1'b0;
                alu_op  = 2'b01;
                alu_a_sel = ALU_A_RS1;
            end

            OPCODE_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b0;
                imm_sel   = IMM_J;
            end

            OPCODE_JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b1;
                imm_sel   = IMM_I;
                alu_src   = 1'b1;
                alu_a_sel = ALU_A_RS1;
            end
            
            OPCODE_LUI: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                imm_sel = IMM_U;
                alu_op = 2'b00;
                alu_a_sel = ALU_A_ZERO;
            end

            OPCODE_AUIPC: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                imm_sel = IMM_U;
                alu_op = 2'b00;
                alu_a_sel = ALU_A_PC;
            end
            
            default: begin
                reg_write = 1'b0;
            end

        endcase
    end

endmodule