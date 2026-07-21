`timescale 1ns/1ps

module crypto_accel(
    input wire        clk,
    input wire        rst,

    input wire        write_en,
    input wire [7:0]  addr,
    input wire [31:0] write_data,

    output reg [31:0] read_data
);
    
    localparam ADDR_CTRL     = 8'h00;
    localparam ADDR_STATUS   = 8'h04;

    localparam ADDR_PT0      = 8'h10;
    localparam ADDR_PT1      = 8'h14;
    localparam ADDR_PT2      = 8'h18;
    localparam ADDR_PT3      = 8'h1C;

    localparam ADDR_KEY0     = 8'h20;
    localparam ADDR_KEY1     = 8'h24;
    localparam ADDR_KEY2     = 8'h28;
    localparam ADDR_KEY3     = 8'h2C;

    localparam ADDR_CT0      = 8'h30;
    localparam ADDR_CT1      = 8'h34;
    localparam ADDR_CT2      = 8'h38;
    localparam ADDR_CT3      = 8'h3C;

    localparam ADDR_COUNT    = 8'h40;

    reg [127:0] plaintext_reg;
    reg [127:0] key_reg;
    reg [127:0] ciphertext_reg;

    reg [31:0] op_count;
    reg        start_pulse;

    wire [127:0] aes_ciphertext;
    wire         aes_busy;
    wire         aes_done;

    aes128_encrypt_core u_aes128_encrypt_core (
        .clk(clk),
        .rst(rst),
        .start(start_pulse),
        .plaintext(plaintext_reg),
        .key(key_reg),
        .ciphertext(aes_ciphertext),
        .busy(aes_busy),
        .done(aes_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            plaintext_reg  <= 128'b0;
            key_reg        <= 128'b0;
            ciphertext_reg <= 128'b0;
            op_count       <= 32'b0;
            start_pulse    <= 1'b0;
        end else begin
            start_pulse <= 1'b0;

            if (aes_done) begin
                ciphertext_reg <= aes_ciphertext;
                op_count       <= op_count + 32'd1;
            end

            if (write_en) begin
                case (addr)
                    
                    ADDR_CTRL: begin
                        if (write_data[1]) begin
                            ciphertext_reg <= 128'b0;
                            op_count       <= 32'b0;
                        end

                        if (write_data[0]) begin
                            start_pulse <= 1'b1;
                        end
                    end

                    ADDR_PT0:  plaintext_reg[127:96] <= write_data;
                    ADDR_PT1:  plaintext_reg[95:64]  <= write_data;
                    ADDR_PT2:  plaintext_reg[63:32]  <= write_data;
                    ADDR_PT3:  plaintext_reg[31:0]   <= write_data;

                    ADDR_KEY0: key_reg[127:96] <= write_data;
                    ADDR_KEY1: key_reg[95:64]  <= write_data;
                    ADDR_KEY2: key_reg[63:32]  <= write_data;
                    ADDR_KEY3: key_reg[31:0]   <= write_data;

                    default: begin
                        //Nothing
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
                read_data = {30'b0, aes_busy, aes_done};
            end

            ADDR_PT0: begin
                read_data = plaintext_reg[127:96];
            end

            ADDR_PT1: begin
                read_data = plaintext_reg[95:64];
            end

            ADDR_PT2: begin
                read_data = plaintext_reg[63:32];
            end

            ADDR_PT3: begin
                read_data = plaintext_reg[31:0];
            end

            ADDR_KEY0: begin
                read_data = key_reg[127:96];
            end

            ADDR_KEY1: begin
                read_data = key_reg[95:64];
            end

            ADDR_KEY2: begin
                read_data = key_reg[63:32];
            end

            ADDR_KEY3: begin
                read_data = key_reg[31:0];
            end

            ADDR_CT0: begin
                read_data = ciphertext_reg[127:96];
            end

            ADDR_CT1: begin
                read_data = ciphertext_reg[95:64];
            end

            ADDR_CT2: begin
                read_data = ciphertext_reg[63:32];
            end

            ADDR_CT3: begin
                read_data = ciphertext_reg[31:0];
            end

            ADDR_COUNT: begin
                read_data = op_count;
            end

            default: begin
                read_data = 32'b0;
            end

        endcase
    end
endmodule