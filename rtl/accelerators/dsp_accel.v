`timescale 1ns/1ps

module dsp_accel (
    input  wire        clk,
    input  wire        rst,

    input  wire        write_en,
    input  wire [7:0]  addr,
    input  wire [31:0] write_data,

    output reg  [31:0] read_data
);
    // ============================================================
    // MAC register map
    // ============================================================
    localparam ADDR_MAC_CTRL      = 8'h00;
    localparam ADDR_MAC_STATUS    = 8'h04;
    localparam ADDR_MAC_A         = 8'h08;
    localparam ADDR_MAC_B         = 8'h0C;
    localparam ADDR_MAC_RESULT_LO = 8'h10;
    localparam ADDR_MAC_RESULT_HI = 8'h14;
    localparam ADDR_MAC_COUNT     = 8'h18;

    // ============================================================
    // FIR register map
    // ============================================================
    localparam ADDR_FIR_CTRL      = 8'h20;
    localparam ADDR_FIR_STATUS    = 8'h24;

    localparam ADDR_FIR_X0        = 8'h28;
    localparam ADDR_FIR_X1        = 8'h2C;
    localparam ADDR_FIR_X2        = 8'h30;
    localparam ADDR_FIR_X3        = 8'h34;

    localparam ADDR_FIR_H0        = 8'h38;
    localparam ADDR_FIR_H1        = 8'h3C;
    localparam ADDR_FIR_H2        = 8'h40;
    localparam ADDR_FIR_H3        = 8'h44;

    localparam ADDR_FIR_RESULT_LO = 8'h48;
    localparam ADDR_FIR_RESULT_HI = 8'h4C;
    localparam ADDR_FIR_COUNT     = 8'h50;

    // ============================================================
    // MAC internal registers
    // ============================================================
    reg signed [31:0] mac_a_reg;
    reg signed [31:0] mac_b_reg;
    reg signed [63:0] mac_acc_reg;

    reg [31:0] mac_count;
    reg        mac_done;
    reg        mac_busy;

    wire signed [63:0] mac_product;
    wire signed [63:0] mac_acc_next;

    assign product  = mac_a_reg * mac_b_reg;
    assign acc_next = mac_acc_reg + mac_product;

    // ============================================================
    // FIR internal registers
    // ============================================================
    reg signed [31:0] fir_x0;
    reg signed [31:0] fir_x1;
    reg signed [31:0] fir_x2;
    reg signed [31:0] fir_x3;

    reg signed [31:0] fir_h0;
    reg signed [31:0] fir_h1;
    reg signed [31:0] fir_h2;
    reg signed [31:0] fir_h3;

    reg signed [63:0] fir_acc_reg;
    reg        [31:0] fir_count;
    reg        [1:0]  fir_tap_index;
    reg               fir_busy;
    reg               fir_done;

    wire signed [63:0] fir_product_0;
    wire signed [63:0] fir_product_1;
    wire signed [63:0] fir_product_2;
    wire signed [63:0] fir_product_3;

    assign fir_product_0 = fir_x0 * fir_h0;
    assign fir_product_1 = fir_x1 * fir_h1;
    assign fir_product_2 = fir_x2 * fir_h2;
    assign fir_product_3 = fir_x3 * fir_h3;

    // ============================================================
    // Sequential logic
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mac_a_reg   <= 32'b0;
            mac_b_reg   <= 32'b0;
            mac_acc_reg <= 32'b0;
            mac_count   <= 32'b0;
            mac_done    <= 1'b0;
            mac_busy    <= 1'b0;

            fir_x0 <= 32'b0;
            fir_x1 <= 32'b0;
            fir_x2 <= 32'b0;
            fir_x3 <= 32'b0;

            fir_h0 <= 32'b0;
            fir_h1 <= 32'b0;
            fir_h2 <= 32'b0;
            fir_h3 <= 32'b0;

            fir_acc_reg   <= 64'b0;
            fir_count     <= 32'b0;
            fir_tap_index <= 2'b0;
            fir_busy      <= 1'b0;
            fir_done      <= 1'b0;
        end else begin
            // ====================================================
            // FIR calculation FSM
            // ====================================================
            if (fir_busy) begin
                case (fir_tap_index)
                    
                    2'd0: begin
                        fir_acc_reg   <= fir_acc_reg + fir_product_0;
                        fir_tap_index <= 2'd1;
                    end

                    2'd1: begin
                        fir_acc_reg   <= fir_acc_reg + fir_product_1;
                        fir_tap_index <= 2'd2;
                    end

                    2'd2: begin
                        fir_acc_reg   <= fir_acc_reg + fir_product_2;
                        fir_tap_index <= 2'd3;
                    end

                    2'd3: begin
                        fir_acc_reg   <= fir_acc_reg + fir_product_3;
                        fir_tap_index <= 2'd0;
                        fir_busy      <= 1'b0;
                        fir_done      <= 1'b1;
                        fir_count     <= fir_count + 32'd1;
                    end

                    default: begin
                        fir_tap_index <= 2'd0;
                    end
                endcase
            end
            // ====================================================
            // MMIO writes
            // ====================================================
            if (write_en) begin
                case (addr)
                    // -------------------------------
                    // MAC control
                    // -------------------------------
                    ADDR_MAC_CTRL: begin
                        if (write_data[1]) begin
                            mac_acc_reg <= 64'b0;
                            mac_count   <= 32'b0;
                            mac_done    <= 1'b1;
                            mac_busy    <= 1'b0;
                        end

                        if (write_data[0]) begin
                            mac_acc_reg <= mac_acc_next;
                            mac_count   <= mac_count + 32'd1;
                            mac_done    <= 1'b1;
                            mac_busy    <= 1'b0;
                        end
                    end

                    ADDR_MAC_A: begin
                        mac_a_reg <= write_data;
                    end

                    ADDR_MAC_B: begin
                        mac_b_reg <= write_data;
                    end
                    // -------------------------------
                    // FIR control
                    // -------------------------------
                    ADDR_FIR_CTRL: begin
                        if (write_data[1]) begin
                            fir_acc_reg   <= 64'b0;
                            fir_count     <= 32'b0;
                            fir_tap_index <= 2'b0;
                            fir_busy      <= 1'b0;
                            fir_done      <= 1'b1;
                        end

                        if (write_data[0] && !fir_busy) begin
                            fir_acc_reg   <= 64'b0;
                            fir_tap_index <= 2'b0;
                            fir_busy      <= 1'b1;
                            fir_done      <= 1'b0;
                        end
                    end

                    ADDR_FIR_X0: begin
                        fir_x0 <= write_data;
                    end

                    ADDR_FIR_X1: begin
                        fir_x1 <= write_data;
                    end

                    ADDR_FIR_X2: begin
                        fir_x2 <= write_data;
                    end

                    ADDR_FIR_X3: begin
                        fir_x3 <= write_data;
                    end

                    ADDR_FIR_H0: begin
                        fir_h0 <= write_data;
                    end

                    ADDR_FIR_H1: begin
                        fir_h1 <= write_data;
                    end

                    ADDR_FIR_H2: begin
                        fir_h2 <= write_data;
                    end

                    ADDR_FIR_H3: begin
                        fir_h3 <= write_data;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    // ============================================================
    // MMIO read mux
    // ============================================================
    always @(*) begin
        case (addr)

            // -------------------------------
            // MAC read
            // -------------------------------
            ADDR_MAC_CTRL: begin
                read_data = 32'b0;
            end

            ADDR_MAC_STATUS: begin
                read_data = {30'b0, mac_busy, mac_done};
            end

            ADDR_MAC_A: begin
                read_data = mac_a_reg;
            end

            ADDR_MAC_B: begin
                read_data = mac_b_reg;
            end

            ADDR_MAC_RESULT_LO: begin
                read_data = mac_acc_reg[31:0];
            end

            ADDR_MAC_RESULT_HI: begin
                read_data = mac_acc_reg[63:32];
            end

            ADDR_MAC_COUNT: begin
                read_data = mac_count;
            end

            // -------------------------------
            // FIR read
            // -------------------------------
            ADDR_FIR_CTRL: begin
                read_data = 32'b0;
            end

            ADDR_FIR_STATUS: begin
                read_data = {30'b0, fir_busy, fir_done};
            end

            ADDR_FIR_X0: begin
                read_data = fir_x0;
            end

            ADDR_FIR_X1: begin
                read_data = fir_x1;
            end

            ADDR_FIR_X2: begin
                read_data = fir_x2;
            end

            ADDR_FIR_X3: begin
                read_data = fir_x3;
            end

            ADDR_FIR_H0: begin
                read_data = fir_h0;
            end

            ADDR_FIR_H1: begin
                read_data = fir_h1;
            end

            ADDR_FIR_H2: begin
                read_data = fir_h2;
            end

            ADDR_FIR_H3: begin
                read_data = fir_h3;
            end

            ADDR_FIR_RESULT_LO: begin
                read_data = fir_acc_reg[31:0];
            end

            ADDR_FIR_RESULT_HI: begin
                read_data = fir_acc_reg[63:32];
            end

            ADDR_FIR_COUNT: begin
                read_data = fir_count;
            end

            default: begin
                read_data = 32'b0;
            end

        endcase
    end

endmodule