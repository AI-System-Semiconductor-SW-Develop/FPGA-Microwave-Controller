`timescale 1ns / 1ps

module fnd_controller #(
    parameter integer BLINK_TICKS = 500
)(
    input clk,
    input reset,
    input tick,
    input timer_done,
    input [13:0] in_data,
    output [7:0] seg,
    output completion_active,
    output completion_beep,
    output [3:0] an
);
    wire [1:0] w_sel;
    wire [3:0] w_d1, w_d10, w_d100, w_d1000;
    wire [7:0] normal_seg;
    wire [3:0] normal_an;
    reg blink_active;
    reg [2:0] phase;
    localparam integer BLINK_WIDTH = (BLINK_TICKS > 1) ? $clog2(BLINK_TICKS) : 1;
    reg [BLINK_WIDTH-1:0] blink_count;
    reg done_prev;

    // 1밀리초 틱 500번마다 꺼짐과 켜짐을 전환한다.
    // 완료 신호의 상승 에지에서만 시작하며 총 세 번 반복한다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            blink_active <= 0;
            phase <= 0;
            blink_count <= 0;
            done_prev <= 0;
        end else begin
            done_prev <= timer_done;
            if (in_data != 0) begin
                blink_active <= 0;
                phase <= 0;
                blink_count <= 0;
            end else if (timer_done && !done_prev && !blink_active) begin
                blink_active <= 1;
                phase <= 0;
                blink_count <= 0;
            end else if (blink_active && tick) begin
                if (blink_count == BLINK_TICKS - 1) begin
                    blink_count <= 0;
                    if (phase == 5) begin
                        blink_active <= 0;
                        phase <= 0;
                    end else phase <= phase + 1'b1;
                end else blink_count <= blink_count + 1;
            end
        end
    end

    // 표시와 완료음이 같은 단계 신호를 사용하여 세 번 함께 반복한다.
    assign completion_active = !reset && blink_active;
    assign completion_beep = completion_active && !phase[0];

    // 짝수 단계에서 전체 소등, 홀수 단계에서 숫자를 표시한다.
    assign seg = (blink_active && !phase[0]) ? 8'hff : normal_seg;
    assign an = (blink_active && !phase[0]) ? 4'hf : normal_an;

    fnd_digit_select u_fnd_digit_select(
        .clk(clk), .reset(reset), .tick(tick), .sel(w_sel)
    );
    bin2bcd_4digit u_bin2bcd_4digit(
        .in_data(in_data), .d1(w_d1), .d10(w_d10),
        .d100(w_d100), .d1000(w_d1000)
    );
    fnd_digit_display u_fnd_digit_display(
        .sel(w_sel), .d1(w_d1), .d10(w_d10),
        .d100(w_d100), .d1000(w_d1000),
        .seg(normal_seg), .an(normal_an)
    );
endmodule

module fnd_digit_select(
    input clk,
    input reset,
    input tick,
    output reg[1:0] sel // 00 01 10 11 : 1ms 마다 바뀜
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            sel <= 0;
        else if (tick)
            sel <= sel + 1;
    end
endmodule

// 9999까지 표현하기 위해 14비트를 사용한다.
// 0~9999 천/백/십/일 자리 숫자 0~9 bcd로 4bit 표현한다.
module bin2bcd_4digit (
    input [13:0] in_data,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100,
    output [3:0] d1000            
    );

    assign d1 = in_data % 10;
    assign d10 = (in_data / 10) % 10;
    assign d100 = (in_data / 100) % 10;
    assign d1000 = (in_data / 1000) % 10;   

endmodule

module fnd_digit_display(
    input [1:0] sel,
    input [3:0] d1,
    input [3:0] d10,
    input [3:0] d100,
    input [3:0] d1000,
    output reg [7:0] seg,
    output reg [3:0] an
);

    reg [3:0] bcd_data;

    // 표시할 자리와 해당 숫자 선택
    always @(*) begin
        case (sel)
            2'b00: begin
                bcd_data = d1;
                an = 4'b1110;
            end
            2'b01: begin
                bcd_data = d10;
                an = 4'b1101;
            end
            2'b10: begin
                bcd_data = d100;
                an = 4'b1011;
            end
            2'b11: begin
                bcd_data = d1000;
                an = 4'b0111;
            end
            default: begin
                bcd_data = 0;
                an = 4'b1111;
            end
        endcase
    end

    // seg 비트 순서: {dp, g, f, e, d, c, b, a}
    // 출력이 0이면 해당 세그먼트가 켜진다.
    always @(*) begin
        case (bcd_data)
            4'd0: seg = 8'b11000000;
            4'd1: seg = 8'b11111001;
            4'd2: seg = 8'b10100100;
            4'd3: seg = 8'b10110000;
            4'd4: seg = 8'b10011001;
            4'd5: seg = 8'b10010010;
            4'd6: seg = 8'b10000010;
            4'd7: seg = 8'b11111000;
            4'd8: seg = 8'b10000000;
            4'd9: seg = 8'b10010000;
            default: seg = 8'b11111111;
        endcase
    end

endmodule
