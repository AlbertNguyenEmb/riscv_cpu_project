`timescale 1ns/1ps
module m_unit (
    input wire        clk,
    input wire        rst,
    input wire        start,
    input wire [2:0]  funct3,
    input wire [31:0] rs1_value,
    input wire [31:0] rs2_value,

    output reg [31:0] result,
    output reg        busy,
    output reg        done
);
    
    localparam M_MUL    = 3'b000;
    localparam M_MULH   = 3'b001;
    localparam M_MULHSU = 3'b010;
    localparam M_MULHU  = 3'b011;
    localparam M_DIV    = 3'b100;
    localparam M_DIVU   = 3'b101;
    localparam M_REM    = 3'b110;
    localparam M_REMU   = 3'b111;

    reg [2:0]  op_reg;
    reg [31:0] a_reg;
    reg [31:0] b_reg;
    reg [5:0]  count;

    wire is_div_op;
    assign is_div_op = funct3[2];

    function [31:0] calc_m_result;
        input [2:0] op;
        input [31:0] a;
        input [31:0] b;

        reg signed [31:0] sa;
        reg signed [31:0] sb;

        reg signed [63:0] prod_ss;
        reg signed [63:0] prod_su;
        reg        [63:0] prod_uu;

        begin
            sa = a;
            sb = b;

            prod_ss = $signed({{32{a[31]}}, a}) * $signed({{32{b[31]}}, b});
            prod_su = $signed({{32{a[31]}}, a}) * $signed({32'b0, b});
            prod_uu = {32'b0, a} * {32'b0, b};

            case (op)

                M_MUL: begin
                    calc_m_result = prod_uu[31:0];
                end

                M_MULH: begin
                    calc_m_result = prod_ss[63:32];
                end

                M_MULHSU: begin
                    calc_m_result = prod_su[63:32];
                end

                M_MULHU: begin
                    calc_m_result = prod_uu[63:32];
                end

                M_DIV: begin
                    if (b == 32'b0) begin
                        calc_m_result = 32'hffff_ffff;
                    end else if (a == 32'h8000_0000 && b == 32'hffff_ffff) begin
                        calc_m_result = 32'h8000_0000;
                    end else begin
                        calc_m_result = sa/sb;
                    end
                end

                M_DIVU: begin
                    if (b == 32'b0) begin
                        calc_m_result = 32'hffff_ffff;
                    end else begin
                        calc_m_result = a / b;
                    end
                end

                M_REM: begin
                    if (b == 32'b0) begin
                        calc_m_result = a;
                    end else if (a == 32'h8000_0000 && b == 32'hffff_ffff) begin
                        calc_m_result = 32'b0;
                    end else begin
                        calc_m_result = sa % sb;
                    end
                end

                M_REMU: begin
                    if (b == 32'b0) begin
                        calc_m_result = a;
                    end else begin
                        calc_m_result = a % b;
                    end
                end

                default: begin
                    calc_m_result = 32'b0;
                end
            endcase
        end 
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 32'b0;
            busy   <= 1'b0;
            done   <= 1'b0;
            op_reg <= 3'b0;
            a_reg  <= 32'b0;
            b_reg  <= 32'b0;
            count  <= 6'b0;
        end else begin
            
            if (start && !busy) begin
                op_reg <= funct3;
                a_reg  <= rs1_value;
                b_reg  <= rs2_value;

                if (is_div_op) begin
                    busy  <= 1'b1;
                    done  <= 1'b0;
                    count <= 6'd32;
                end else begin
                    result <= calc_m_result(funct3, rs1_value, rs2_value);
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    count  <= 6'b0;
                end
    
            end else if (busy) begin
                if (count == 6'd1) begin
                    result <= calc_m_result(op_reg, a_reg, b_reg);
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    count  <= 6'b0;
                end else begin
                    count <= count - 6'd1;
                    done  <= 1'b0;
                end

            end else begin
                done <= 1'b0;
            end
        end
    end
endmodule