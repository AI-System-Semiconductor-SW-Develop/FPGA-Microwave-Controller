`timescale 1ns / 1ps

// 로터리 한 단계는 1초이며, 남은 초를 0부터 9999까지 표시한다.
module microwave_timer #(
    parameter integer SECOND_TICKS = 1000
)(
    input clk, input reset, input tick,
    input [4:0] btn,
    input increase, input decrease,
    input door_open,
    output reg [13:0] remaining,
    output reg running,
    output reg done
);
    reg previous_start;
    localparam integer TICK_WIDTH = (SECOND_TICKS > 1) ? $clog2(SECOND_TICKS) : 1;
    reg [TICK_WIDTH-1:0] elapsed_ticks;
    wire start_pressed = btn[1] && !previous_start;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            previous_start <= 0;
            remaining <= 0;
            running <= 0;
            done <= 0;
            elapsed_ticks <= 0;
        end else begin
            previous_start <= btn[1];
            done <= 0;
            // 취소와 문 열기, 일시정지를 시작보다 우선한다.
            if (btn[2]) begin
                remaining <= 0;
                running <= 0;
                elapsed_ticks <= 0;
            end else if (btn[3] || btn[0]) begin
                running <= 0;
            end else if (!running && (increase || decrease)) begin
                elapsed_ticks <= 0;
                if (increase && !decrease && remaining < 9999)
                    remaining <= remaining + 1'b1;
                else if (decrease && !increase && remaining > 0)
                    remaining <= remaining - 1'b1;
            end else if (start_pressed && !door_open && remaining != 0) begin
                running <= 1;
            end else if (running && tick) begin
                if (elapsed_ticks == SECOND_TICKS - 1) begin
                    elapsed_ticks <= 0;
                    if (remaining == 1) begin
                        remaining <= 0;
                        running <= 0;
                        done <= 1;
                    end else if (remaining > 1)
                        remaining <= remaining - 1'b1;
                end else elapsed_ticks <= elapsed_ticks + 1;
            end
        end
    end
endmodule
