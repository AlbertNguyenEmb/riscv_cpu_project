`timescale 1ns/1ps

module forwarding_unit (
    input wire [4:0] ID_EX_rs1,
    input wire [4:0] ID_EX_rs2,

    input wire [4:0] EX_MEM_rd,
    input wire EX_MEM_reg_write,
    input wire EX_MEM_mem_to_reg,

    input wire [4:0] MEM_WB_rd,
    input wire MEM_WB_reg_write,

    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;

        // EX hazard
        // Forward from EX/MEM to EX stage.
        if (EX_MEM_reg_write &&
            !EX_MEM_mem_to_reg &&
            EX_MEM_rd != 5'd0 &&
            EX_MEM_rd == ID_EX_rs1) begin
                forwardA = 2'b10;
            end

        if (EX_MEM_reg_write &&
            !EX_MEM_mem_to_reg && 
            EX_MEM_rd != 5'd0 &&
            EX_MEM_rd == ID_EX_rs2) begin
                forwardB = 2'b10;
            end

        // MEM hazard
        // Forward from MEM/WB to EX stage.
        if (MEM_WB_reg_write && 
            MEM_WB_rd != 5'd0 &&
            !(EX_MEM_reg_write &&
            !EX_MEM_mem_to_reg &&
            EX_MEM_rd != 5'd0 &&
            EX_MEM_rd == ID_EX_rs1) &&
            MEM_WB_rd == ID_EX_rs1) begin
                forwardA = 2'b01;
            end

        if (MEM_WB_reg_write && 
            MEM_WB_rd != 5'd0 &&
            !(EX_MEM_reg_write &&
            !EX_MEM_mem_to_reg &&
            EX_MEM_rd != 5'd0 &&
            EX_MEM_rd == ID_EX_rs2) &&
            MEM_WB_rd == ID_EX_rs2) begin
                forwardB = 2'b01;
            end
    end
    
endmodule