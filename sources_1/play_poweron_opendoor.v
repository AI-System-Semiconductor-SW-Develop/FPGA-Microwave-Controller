`timescale 1ns / 1ps

module play_poweron_opendoor #(
    parameter integer NOTE_CYCLES = 7_000_000
)(
    input clk,
    input reset,
    input [4:0] btn,
    input completion_active,
    input completion_beep,
    output buzzer
);
    localparam integer NOTE_WIDTH = (NOTE_CYCLES > 1) ? $clog2(NOTE_CYCLES) : 1;
    reg [NOTE_WIDTH-1:0] note_count;
    reg [17:0] tone_count;
    reg [1:0] step;
    reg [4:0] previous_btn;
    reg playing, door_melody, tone;
    reg single_note;
    reg reset_pending;
    reg [17:0] tone_limit;
    wire [4:0] pressed = btn & ~previous_btn;
    wire start_pressed = pressed[1];
    wire open_pressed = pressed[3];
    wire feedback_pressed = pressed[0] || pressed[2] || pressed[4];

    // 시작음과 문 열림음의 기존 네 음을 유지한다.
    always @(*) begin
        if (single_note) begin
            // 일시정지·취소·문 닫기·리셋 확인음은 2kHz로 한 번 재생한다.
            tone_limit = 24_999;
        end else if (door_melody) begin
            case (step)
                0: tone_limit = 191_112;
                1: tone_limit = 151_685;
                2: tone_limit = 127_552;
                default: tone_limit = 90_252;
            endcase
        end else begin
            case (step)
                0: tone_limit = 49_999;
                1: tone_limit = 24_999;
                2: tone_limit = 16_666;
                default: tone_limit = 12_499;
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            note_count <= 0;
            tone_count <= 0;
            step <= 0;
            previous_btn <= 0;
            single_note <= 0;
            // 리셋 중에는 무음이며 해제 후 한 번 확인음을 재생한다.
            reset_pending <= 1;
            playing <= 0;
            door_melody <= 0;
            tone <= 0;
        end else begin
            previous_btn <= btn;
            // 완료 알림 중에는 기존 멜로디보다 완료음을 우선한다.
            if (completion_active) begin
                playing <= 0;
                note_count <= 0;
                step <= 0;
                if (!completion_beep) begin
                    tone_count <= 0;
                    tone <= 0;
                end else if (tone_count >= 18'd24_999) begin
                    // 100MHz 기준 반주기 25,000클럭으로 2kHz 음을 만든다.
                    tone_count <= 0;
                    tone <= ~tone;
                end else tone_count <= tone_count + 1'b1;
            end else if (reset_pending || feedback_pressed || start_pressed || open_pressed) begin
                // 새 버튼 입력은 재생 중인 버튼음을 교체하되 완료음은 우선한다.
                playing <= 1;
                single_note <= reset_pending || feedback_pressed;
                door_melody <= !start_pressed && open_pressed;
                reset_pending <= 0;
                step <= 0;
                note_count <= 0;
                tone_count <= 0;
                tone <= 0;
            end else if (!playing) begin
                tone <= 0;
            end else if (note_count == NOTE_CYCLES - 1) begin
                note_count <= 0;
                tone_count <= 0;
                tone <= 0;
                if (single_note || step == 3) begin
                    playing <= 0;
                    step <= 0;
                end else step <= step + 1'b1;
            end else begin
                note_count <= note_count + 1'b1;
                if (tone_count == tone_limit) begin
                    tone_count <= 0;
                    tone <= ~tone;
                end else tone_count <= tone_count + 1'b1;
            end
        end
    end

    // 버튼을 계속 누르고 있어도 재생이 반복되지 않는다.
    assign buzzer = !reset && tone &&
                    (completion_active ? completion_beep : playing);
endmodule
