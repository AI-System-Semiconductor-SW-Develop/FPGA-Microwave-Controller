`timescale 1ns / 1ps

module tb_top_micro_wave;

    reg clk = 0;
    reg reset = 1;
    reg [4:0] btn = 0;
    reg increase = 0;
    reg decrease = 0;
    reg door_open = 0;

    wire [13:0] remaining;
    wire running;
    wire done;

    // 100MHz 클럭
    always #5 clk = ~clk;

    // 빠른 확인을 위해 10클럭을 1초로 취급
    microwave_timer #(
        .SECOND_TICKS(10)
    ) u_microwave_timer (
        .clk(clk),
        .reset(reset),
        .tick(1'b1),
        .btn(btn),
        .increase(increase),
        .decrease(decrease),
        .door_open(door_open),
        .remaining(remaining),
        .running(running),
        .done(done)
    );

    initial begin
        // 초기화
        repeat (3) @(negedge clk);
        reset = 0;

        // 3초 설정
        repeat (3) begin
            @(negedge clk);
            increase = 1;
            @(negedge clk);
            increase = 0;
        end

        // 시작
        @(negedge clk);
        btn[1] = 1;
        @(negedge clk);
        btn[1] = 0;

        // 일부 시간이 흐른 뒤 일시정지
        repeat (12) @(negedge clk);
        btn[0] = 1;
        @(negedge clk);
        btn[0] = 0;

        // 정지 중 remaining이 유지되는지 확인
        repeat (15) @(negedge clk);

        // 재개
        btn[1] = 1;
        @(negedge clk);
        btn[1] = 0;

        // 자연 종료 확인
        wait (done == 1);
        repeat (3) @(negedge clk);
        $finish;
        
        $monitor("time=%0t remaining=%0d running=%b done=%b",$time, remaining, running, done);        
    end

endmodule
