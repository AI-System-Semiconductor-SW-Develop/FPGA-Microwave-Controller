`timescale 1ns / 1ps

module pwm_duty_control #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer PWM_HZ = 1_000,
    parameter integer DUTY_PERCENT = 100
)(
    input clk,
    input reset,
    input enable,
    output pwm_out,
    output [1:0] in1_in2
);
    // 주파수와 듀티는 사용하는 모터 드라이버에 맞춰 지정한다.
    localparam integer PERIOD_CYCLES = CLK_HZ / PWM_HZ;
    localparam integer HIGH_CYCLES = (PERIOD_CYCLES / 100) * DUTY_PERCENT
                                  + ((PERIOD_CYCLES % 100) * DUTY_PERCENT) / 100;
    localparam integer COUNT_WIDTH = (PERIOD_CYCLES > 1) ? $clog2(PERIOD_CYCLES) : 1;
    reg [COUNT_WIDTH-1:0] pwm_count;

    // 중지 중에는 카운터를 초기화하여 재시작 시 새 주기부터 출력한다.
    always @(posedge clk or posedge reset) begin
        if (reset) pwm_count <= 0;
        else if (!enable) pwm_count <= 0;
        else if (pwm_count == PERIOD_CYCLES - 1) pwm_count <= 0;
        else pwm_count <= pwm_count + 1'b1;
    end

    // 리셋이나 중지 요청이 들어오면 출력은 즉시 0이 된다.
    assign pwm_out = !reset && enable && (pwm_count < HIGH_CYCLES);
    // 비트 0은 IN1, 비트 1은 IN2이며 조리 중 한 방향으로 구동한다.
    // 중지 시에는 인에이블과 방향 입력을 모두 0으로 만든다.
    assign in1_in2 = (!reset && enable && HIGH_CYCLES > 0) ? 2'b01 : 2'b00;
endmodule
