module ai_accel(
    input wire        clk,
    input wire        rst,

    input wire        write_en,
    input wire [7:0]  addr,
    input wire [31:0] write_data,

    output reg [31:0] read_data
);
    
    localparam ADDR_AI_CTRL      = 8'h00;
    localparam ADDR_AI_STATUS    = 8'h04;
    localparam ADDR_AI_VEC_A     = 8'h08;
    localparam ADDR_AI_VEC_B     = 8'h0C;
    localparam ADDR_AI_ACC_LO    = 8'h10;
    localparam ADDR_AI_ACC_HI    = 8'h14;
    localparam ADDR_AI_LAST_DOT  = 8'h18;
    localparam ADDR_AI_COUNT     = 8'h1C;

    reg [31:0] vec_a_reg;
    reg [31:0] vec_b_reg;

    reg signed [63:0] acc_reg;
    reg signed [31:0] last_dot_reg;

    reg [31:0] dot_count;
    reg        done;
    reg        busy;

    wire signed [31:0] a0;
    wire signed [31:0] a1;
    wire signed [31:0] a2;
    wire signed [31:0] a3;

    wire signed [31:0] b0;
    wire signed [31:0] b1;
    wire signed [31:0] b2;
    wire signed [31:0] b3;

    wire signed [63:0] p0;
    wire signed [63:0] p1;
    wire signed [63:0] p2;
    wire signed [63:0] p3;

    wire signed [63:0] dot_result;
    
    assign a0 = {{24{vec_a_reg[7]}},  vec_a_reg[7:0]};
    assign a1 = {{24{vec_a_reg[15]}}, vec_a_reg[15:8]};
    assign a2 = {{24{vec_a_reg[23]}}, vec_a_reg[23:16]};
    assign a3 = {{24{vec_a_reg[31]}}, vec_a_reg[31:24]};

    assign b0 = {{24{vec_b_reg[7]}},  vec_b_reg[7:0]};
    assign b1 = {{24{vec_b_reg[15]}}, vec_b_reg[15:8]};
    assign b2 = {{24{vec_b_reg[23]}}, vec_b_reg[23:16]};
    assign b3 = {{24{vec_b_reg[31]}}, vec_b_reg[31:24]};

    assign p0 = a0 * b0;
    assign p1 = a1 * b1;
    assign p2 = a2 * b2;
    assign p3 = a3 * b3;

    assign dot_result = p0 + p1 + p2 + p3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            vec_a_reg    <= 32'b0;
            vec_b_reg    <= 32'b0;
            acc_reg      <= 64'b0;
            last_dot_reg <= 32'b0;
            dot_count    <= 32'b0;
            done         <= 1'b0;
            busy         <= 1'b0;
        end else begin
            done <= 1'b0;
            busy <= 1'b0;

            if (write_en) begin
                case (addr)
                    
                    ADDR_AI_CTRL: begin
                        if (write_data[1]) begin
                            acc_reg      <= 64'b0;
                            last_dot_reg <= 32'b0;
                            dot_count    <= 32'b0;
                            done         <= 1'b1;
                            busy         <= 1'b0;
                        end

                        if (write_data[0]) begin
                            acc_reg      <= acc_reg + dot_result;
                            last_dot_reg <= dot_result[31:0];
                            dot_count    <= dot_count + 32'd1;
                            done         <= 1'b1;
                            busy         <= 1'b0;
                        end
                    end

                    ADDR_AI_VEC_A: begin
                        vec_a_reg <= write_data;
                    end

                    ADDR_AI_VEC_B: begin
                        vec_b_reg <= write_data;
                    end
                    
                    default: begin
                    end
                endcase
            end
        end
    end

        always @(*) begin
        case (addr)

            ADDR_AI_CTRL: begin
                read_data = 32'b0;
            end

            ADDR_AI_STATUS: begin
                read_data = {30'b0, busy, done};
            end

            ADDR_AI_VEC_A: begin
                read_data = vec_a_reg;
            end

            ADDR_AI_VEC_B: begin
                read_data = vec_b_reg;
            end

            ADDR_AI_ACC_LO: begin
                read_data = acc_reg[31:0];
            end

            ADDR_AI_ACC_HI: begin
                read_data = acc_reg[63:32];
            end

            ADDR_AI_LAST_DOT: begin
                read_data = last_dot_reg;
            end

            ADDR_AI_COUNT: begin
                read_data = dot_count;
            end

            default: begin
                read_data = 32'b0;
            end

        endcase
    end
endmodule