`timescale 1ns / 1ps

module servo_controller (
    input clk,
    input reset,
    input door_open, 
    output servo
);
    localparam FRAME_CYCLES  = 2_000_000;
    localparam CLOSED_CYCLES = 100_000;
    localparam OPEN_CYCLES   = 200_000;

    reg [20:0] frame_count;
    reg [20:0] pulse_cycles;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            frame_count <= 0;
            pulse_cycles <= CLOSED_CYCLES;
        end else begin
            if (frame_count == FRAME_CYCLES - 1) begin
                frame_count <= 0;
                pulse_cycles <= door_open ? OPEN_CYCLES : CLOSED_CYCLES;
            end else begin
                frame_count <= frame_count + 1'b1;
            end
        end
    end


    assign servo = !reset && (frame_count < pulse_cycles);
endmodule
