`timescale 1ns / 1ps

module rotary(
    input clk,
    input reset,
    input s1,
    input s2,
    output reg increase,
    output reg decrease
);

    reg [1:0] prev_ab;
    reg signed [3:0] quarter_steps;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_ab <= 2'b00;
            quarter_steps <= 0;
            increase <= 0;
            decrease <= 0;
        end else begin
            increase <= 0;
            decrease <= 0;
            prev_ab <= {s1, s2};
            case ({prev_ab, s1, s2})
                // 시계방향: 00 -> 10 -> 11 -> 01 -> 00
                4'b0010, 4'b1011, 4'b1101, 4'b0100: begin
                    if (quarter_steps == 3) begin
                        increase <= 1;
                        quarter_steps <= 0;
                    end else begin
                        quarter_steps <= quarter_steps + 4'sd1;
                    end
                end
                // 반시계방향: 00 -> 01 -> 11 -> 10 -> 00
                4'b0001, 4'b0111, 4'b1110, 4'b1000: begin
                    if (quarter_steps == -4'sd3) begin
                        decrease <= 1;
                        quarter_steps <= 0;
                    end else begin
                        quarter_steps <= quarter_steps - 4'sd1;
                    end
                end
                default: begin

                    if (prev_ab != {s1, s2})
                        quarter_steps <= 0;
                end
            endcase
        end
    end
endmodule
