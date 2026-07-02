`timescale 1ns/1ps

module imm_gen (
    input  wire [31:0] instr,
    input  wire [2:0]  imm_sel,
    output reg  [31:0] imm_out
);

    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_J = 3'b011;
    localparam IMM_U = 3'b100;

    always @(*) begin
        case (imm_sel)
            IMM_I: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end

            IMM_S: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            IMM_B: begin
                imm_out = {{19{instr[31]}},
                           instr[31],
                           instr[7],
                           instr[30:25],
                           instr[11:8],
                           1'b0};
            end

            IMM_J: begin
                imm_out = {{11{instr[31]}},
                           instr[31],
                           instr[19:12],
                           instr[20],
                           instr[30:21],
                           1'b0};
            end
            
            IMM_U: begin
                imm_out = {instr[31:12], 12'b0};
            end
            default: begin
                imm_out = 32'b0;
            end
        endcase
    end

endmodule