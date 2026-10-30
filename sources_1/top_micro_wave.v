`timescale 1ns / 1ps

module top_micro_wave#(
    parameter ROTARY_DEBOUNCE_TIME = 200_000
)(
    input clk,
    input reset,
    input [4:0] btn,
    input s1,
    input s2,
    output [7:0] seg,
    output [3:0] an,
    output pwm_out,
    output pwm_out_led,
    output [1:0] in1_in2,
    output buzzer,
    output servo
    );

    wire w_clean_s1, w_clean_s2;
    wire [4:0] w_btn;
    // 내부 버튼은 누르면 1, 외부 문 버튼은 누르면 0이므로 극성을 통일한다.
    wire [4:0] w_pressed_btn = {~btn[4:3], btn[2:0]};
    wire w_tick;
    wire [13:0] w_remaining;
    wire w_increase, w_decrease, w_running, w_done;
    wire w_motor_enable;
    wire w_completion_active, w_completion_beep;
    reg r_door_open;
    wire w_door_target = w_btn[3] ? 1'b1 :
                         w_btn[4] ? 1'b0 : r_door_open;

    // 문 상태는 한 곳에서 저장하고 타이머와 서보가 함께 사용한다.
    always @(posedge clk or posedge reset) begin
        if (reset) r_door_open <= 1'b0;
        else r_door_open <= w_door_target;
    end

    debouncer #(.DEBOUNCE_LIMIT(ROTARY_DEBOUNCE_TIME))u_s1_debouncer(
        // 100MHz 기준 200,000클럭 동안 로터리 입력을 안정화한다.
        .clk(clk),
        .reset(reset),
        .noisy_btn(s1),
        .clean_btn(w_clean_s1)
    );

    debouncer #(.DEBOUNCE_LIMIT(ROTARY_DEBOUNCE_TIME))u_s2_debouncer(
        // 100MHz 기준 200,000클럭 동안 로터리 입력을 안정화한다.
        .clk(clk),
        .reset(reset),
        .noisy_btn(s2),
        .clean_btn(w_clean_s2)
    );

    btn_debouncer u_btn_debouncer(
        .clk(clk),
        .reset(reset),
        .noisy_btn(w_pressed_btn),
        .clean_btn(w_btn)
    );

    rotary u_rotary(
        .clk(clk),
        .reset(reset),
        .s1(w_clean_s1),
        .s2(w_clean_s2),
        .increase(w_increase),
        .decrease(w_decrease) 
    );

    play_poweron_opendoor u_play_poweron_opendoor(
        .clk(clk),
        .reset(reset),
        .btn(w_btn),
        .completion_active(w_completion_active),
        .completion_beep(w_completion_beep),
        .buzzer(buzzer)       
    );

    // 주파수와 듀티는 PWM 모듈의 설정값을 그대로 사용한다.
    pwm_duty_control u_pwm_duty_control(
        .clk(clk),
        .reset(reset),
        .enable(w_motor_enable),
        .pwm_out(pwm_out),
        .in1_in2(in1_in2)
    ); 

    tick_generator u_tick_generator(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset | w_btn[2]),
        .tick(w_tick),
        .timer_done(w_done),
        .completion_active(w_completion_active),
        .completion_beep(w_completion_beep),
        .in_data(w_remaining),
        .an(an),
        .seg(seg)
    );

    servo_controller u_servo_controller(
        .clk(clk),
        .reset(reset),
        .servo(servo),
        .door_open(w_door_target)
    );
    microwave_timer u_microwave_timer(
        .clk(clk), 
        .reset(reset), 
        .tick(w_tick), 
        .btn(w_btn),
        .increase(w_increase),
        .decrease(w_decrease),
        .door_open(r_door_open),
        .remaining(w_remaining),
        .running(w_running), 
        .done(w_done)
    );

    // 실행 중에만 조리 신호를 내보내고 중지 요청은 즉시 반영한다.
    assign w_motor_enable = w_running && (w_remaining != 0) && !reset
                   && !w_btn[0] && !w_btn[2] && !w_btn[3];

    assign pwm_out_led = pwm_out;
endmodule
