`timescale 1ns/1ps

module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg  [3:0] alu_ctrl
);

    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_SLT = 4'b0101;
    localparam ALU_SLL = 4'b0110;
    localparam ALU_SRL = 4'b0111;
    localparam ALU_SRA = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    always @(*) begin
        case (alu_op)
            2'b00: begin
                alu_ctrl = ALU_ADD; 
            end

            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SUB;
                        else
                            alu_ctrl = ALU_ADD;
                    end

                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SRA;
                        else
                            alu_ctrl = ALU_SRL;
                    end
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            2'b11: begin
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD; // addi
                    3'b001: alu_ctrl = ALU_SLL; // slli
                    3'b010: alu_ctrl = ALU_SLT; // slti
                    3'b011: alu_ctrl = ALU_SLTU; // sltiu
                    3'b100: alu_ctrl = ALU_XOR; // xori
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SRA; // srai
                        else
                            alu_ctrl = ALU_SRL; // srli
                    end
                    3'b110: alu_ctrl = ALU_OR;  // ori
                    3'b111: alu_ctrl = ALU_AND; // andi
                    
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            default: begin
                alu_ctrl = ALU_ADD;
            end
        endcase
    end

endmodule