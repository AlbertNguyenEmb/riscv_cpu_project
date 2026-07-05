`timescale 1ns/1ps

module dsp_accel (
    input  wire        clk,
    input  wire        rst,

    input  wire        write_en,
    input  wire [7:0]  addr,
    input  wire [31:0] write_data,

    output reg  [31:0] read_data
);

    localparam ADDR_CTRL      = 8'h00;
    localparam ADDR_STATUS    = 8'h04;
    localparam ADDR_A         = 8'h08;
    localparam ADDR_B         = 8'h0C;
    localparam ADDR_RESULT_LO = 8'h10;
    localparam ADDR_RESULT_HI = 8'h14;
    localparam ADDR_COUNT     = 8'h18;

    reg signed [31:0] a_reg;
    reg signed [31:0] b_reg;
    reg signed [63:0] acc_reg;

    reg [31:0] mac_count;
    reg        done;
    reg        busy;

    wire signed [63:0] product;
    wire signed [63:0] acc_next;

    assign product  = a_reg * b_reg;
    assign acc_next = acc_reg + product;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_reg     <= 32'b0;
            b_reg     <= 32'b0;
            acc_reg   <= 64'b0;
            mac_count <= 32'b0;
            done      <= 1'b0;
            busy      <= 1'b0;
        end else begin
            done <= 1'b0;
            busy <= 1'b0;

            if (write_en) begin
                case (addr)

                    ADDR_CTRL: begin
                        if (write_data[1]) begin
                            acc_reg   <= 64'b0;
                            mac_count <= 32'b0;
                            done      <= 1'b1;
                        end

                        if (write_data[0]) begin
                            acc_reg   <= acc_next;
                            mac_count <= mac_count + 32'd1;
                            done      <= 1'b1;
                        end
                    end

                    ADDR_A: begin
                        a_reg <= write_data;
                    end

                    ADDR_B: begin
                        b_reg <= write_data;
                    end

                    default: begin
                    end

                endcase
            end
        end
    end

    always @(*) begin
        case (addr)

            ADDR_CTRL: begin
                read_data = 32'b0;
            end

            ADDR_STATUS: begin
                read_data = {30'b0, busy, done};
            end

            ADDR_A: begin
                read_data = a_reg;
            end

            ADDR_B: begin
                read_data = b_reg;
            end

            ADDR_RESULT_LO: begin
                read_data = acc_reg[31:0];
            end

            ADDR_RESULT_HI: begin
                read_data = acc_reg[63:32];
            end

            ADDR_COUNT: begin
                read_data = mac_count;
            end

            default: begin
                read_data = 32'b0;
            end

        endcase
    end

endmodule