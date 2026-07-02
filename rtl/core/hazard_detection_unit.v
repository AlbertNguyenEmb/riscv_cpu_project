`timescale 1ns/1ps

module hazard_detection_unit (
    input wire       ID_EX_mem_read,
    input wire [4:0] ID_EX_rd,

    input wire [4:0] IF_ID_rs1,
    input wire [4:0] IF_ID_rs2,
    input wire [6:0] IF_ID_opcode,

    output reg       stall
);

    localparam OPCODE_RTYPE  = 7'b0110011;
    localparam OPCODE_ITYPE  = 7'b0010011;
    localparam OPCODE_LOAD   = 7'b0000011;
    localparam OPCODE_STORE  = 7'b0100011;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_LUI    = 7'b0010111;
    localparam OPCODE_AUIPC  = 7'b0010111;

    reg uses_rs1;
    reg uses_rs2;

    always @(*) begin
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;

        case (IF_ID_opcode)

            OPCODE_RTYPE: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            OPCODE_ITYPE: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
            end

            OPCODE_LOAD: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
            end

            OPCODE_STORE: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            OPCODE_BRANCH: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            OPCODE_JALR: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
            end

            OPCODE_JAL,
            OPCODE_LUI,
            OPCODE_AUIPC: begin
                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;
            end

            default: begin
                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;
            end

        endcase

        stall = 1'b0;

        if (ID_EX_mem_read && ID_EX_rd != 5'd0) begin
            if ((uses_rs1 && ID_EX_rd == IF_ID_rs1) ||
                (uses_rs2 && ID_EX_rd == IF_ID_rs2)) begin
                stall = 1'b1;
            end
        end
    end

endmodule