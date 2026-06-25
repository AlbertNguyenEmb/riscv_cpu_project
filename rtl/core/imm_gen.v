`timescale 1ns/1ps

module imm_gen (
    input  wire [31:0] instr,
    input  wire [1:0]  imm_sel,
    output reg  [31:0] imm_out
);

    localparam IMM_I = 2'b00;
    localparam IMM_S = 2'b01;

    always @(*) begin
        case (imm_sel)
            IMM_I: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end

            IMM_S: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            default: begin
                imm_out = 32'b0;
            end
        endcase
    end

endmodule