`timescale 1ns / 1ps
module btn_selector(
    input sw_mode,           // change_watch_to_stopwatch
    input btn_in,
    output btn_watch,
    output btn_stopwatch
);
    assign btn_watch      = (~sw_mode) & btn_in;
    assign btn_stopwatch  = sw_mode & btn_in;
endmodule
