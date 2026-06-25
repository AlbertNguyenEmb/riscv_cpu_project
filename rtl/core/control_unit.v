`timescale 1ns/1ps

module control_unit (
    input  wire [6:0] opcode,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg [1:0]  imm_sel,
    output reg [1:0]  alu_op
);

    localparam OPCODE_RTYPE = 7'b0110011;
    localparam OPCODE_ITYPE = 7'b0010011;
    localparam OPCODE_LOAD  = 7'b0000011;
    localparam OPCODE_STORE = 7'b0100011;

    localparam IMM_I = 2'b00;
    localparam IMM_S = 2'b01;

    always @(*) begin
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        alu_src   = 1'b0;
        imm_sel   = IMM_I;
        alu_op    = 2'b00;

        case (opcode)
            OPCODE_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end

            OPCODE_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_I;
                alu_op    = 2'b11;
            end

            OPCODE_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_I;
                alu_op    = 2'b00;
            end

            OPCODE_STORE: begin
                reg_write = 1'b0;
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = IMM_S;
                alu_op    = 2'b00;
            end

            default: begin
                reg_write = 1'b0;
                mem_read  = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 1'b0;
                alu_src   = 1'b0;
                imm_sel   = IMM_I;
                alu_op    = 2'b00;
            end
        endcase
    end

endmodule