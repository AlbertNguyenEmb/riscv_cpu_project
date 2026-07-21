`timescale 1ns/1ps

module aes128_encrypt_core(
    input wire         clk,
    input wire         rst,
    input wire         start,
    input wire [127:0] plaintext,
    input wire [127:0] key,

    output reg [127:0] ciphertext,
    output reg         busy,
    output reg         done
);
    
    reg [3:0] round;
    reg [127:0] state_reg;
    reg [127:0] round_key_reg;

    wire [127:0] next_round_key;
    wire [127:0] sub_state;
    wire [127:0] shift_state;
    wire [127:0] mix_state;

    // Solve data s-box 
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: gen_sbox_data
            aes_sbox u_sbox_data (
                .data_in (state_reg[(i*8) + 7 : (i*8)]),
                .data_out(sub_state[(i*8) + 7 : (i*8)])
            );
        end
    endgenerate

    // Solve s-box for key expansion
    wire [31:0] key_w3 = round_key_reg[31:0];
    wire [31:0] key_w3_rot = {key_w3[23:0], key_w3[31:24]};
    wire [31:0] key_w3_sub;

    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin: gen_sbox_key
            aes_sbox u_sbox_key (
                .data_in (key_w3_rot[(j*8)+7 : (j*8)]),
                .data_out(key_w3_sub[(j*8)+7 : (j*8)])
            );
        end
    endgenerate

    assign next_round_key = key_expand_round(round_key_reg, round, key_w3_sub);    assign shift_state    = shift_rows(sub_state);
    assign mix_state      = mix_columns(shift_state);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round         <= 4'b0;
            state_reg     <= 128'b0;
            round_key_reg <= 128'b0;
            ciphertext    <= 128'b0;
            busy          <= 1'b0;
            done          <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                round_key_reg <= key;
                state_reg     <= plaintext ^ key;
                round         <= 4'd1;
                busy          <= 1'b1;
            end else if (busy) begin

                if (round < 4'd10) begin
                    round_key_reg <= next_round_key;
                    state_reg     <= mix_state ^ next_round_key;
                    round         <= round + 4'd1;
                end else begin
                    round_key_reg <= next_round_key;
                    ciphertext    <= shift_state ^ next_round_key;
                    busy          <= 1'b0;
                    done          <= 1'b1;
                    round         <= 4'b0;
                end
            end
        end
    end

    function [127:0] shift_rows;
        input [127:0] s;
        begin
            shift_rows = {
                s[127:120], s[87:80],   s[47:40],   s[7:0],
                s[95:88],   s[55:48],   s[15:8],    s[103:96],
                s[63:56],   s[23:16],   s[111:104], s[71:64],
                s[31:24],   s[119:112], s[79:72],   s[39:32]
            };
        end
    endfunction

    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = b[7] ? ((b << 1) ^ 8'h1b) : (b << 1);
        end
    endfunction

    function [7:0] mul2;
        input [7:0] b;
        begin
            mul2 = xtime(b);
        end
    endfunction

    function [7:0] mul3;
        input [7:0] b;
        begin
            mul3 = xtime(b) ^ b;
        end
    endfunction

    function [31:0] mix_col;
        input [31:0] c;
        reg [7:0] a0, a1, a2, a3, r0, r1, r2, r3;
        begin
            a0 = c[31:24]; a1 = c[23:16]; a2 = c[15:8]; a3 = c[7:0];

            r0 = mul2(a0) ^ mul3(a1) ^ a2       ^ a3;
            r1 = a0       ^ mul2(a1) ^ mul3(a2) ^ a3;
            r2 = a0       ^ a1       ^ mul2(a2) ^ mul3(a3);
            r3 = mul3(a0) ^ a1       ^ a2       ^ mul2(a3);

            mix_col = {r0, r1, r2, r3};
        end
    endfunction

    function [127:0] mix_columns;
        input [127:0] s;
        begin
            mix_columns = {mix_col(s[127:96]), mix_col(s[95:64]), mix_col(s[63:32]), mix_col(s[31:0]) };
        end
    endfunction

    function [7:0] rcon;
        input [3:0] r;
        begin
            case (r)
                4'd1: rcon = 8'h01; 4'd2: rcon = 8'h02; 4'd3: rcon = 8'h04; 4'd4: rcon = 8'h08;
                4'd5: rcon = 8'h10; 4'd6: rcon = 8'h20; 4'd7: rcon = 8'h40; 4'd8: rcon = 8'h80;
                4'd9: rcon = 8'h1b; 4'd10: rcon = 8'h36; default: rcon = 8'h00;
            endcase
        end
    endfunction

    function [127:0] key_expand_round;
        input [127:0] key_in;
        input [3:0]   r;
        input [31:0]  sub_w3_in; 

        reg [31:0] w0, w1, w2, w3;
        reg [31:0] nw0, nw1, nw2, nw3;
        reg [31:0] temp;
        begin
            w0 = key_in[127:96];
            w1 = key_in[95:64];
            w2 = key_in[63:32];
            w3 = key_in[31:0];

            temp = sub_w3_in ^ {rcon(r), 24'h000000}; 

            nw0 = w0 ^ temp;
            nw1 = w1 ^ nw0;
            nw2 = w2 ^ nw1;
            nw3 = w3 ^ nw2;

            key_expand_round = {nw0, nw1, nw2, nw3};
        end
    endfunction
endmodule