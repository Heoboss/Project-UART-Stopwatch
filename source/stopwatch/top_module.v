`timescale 1ns / 1ps
module top_module(
    input clk,
    input rst,
    input btn_R,
    input btn_L,
    input btn_U,
    input btn_D,
    input change_hour_to_sec,
    input change_watch_to_stopwatch, // for watch <-> stopwatch
    input modify_watch, // switch for modify watch
    input rx,
    output tx,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [4:0] led
);

    wire [23:0] w_sel_24bit, w_stopwatch_24bit, w_watch_24bit;
    wire w_btn_R_w, w_btn_L_w, w_btn_U_w, w_btn_D_w;
    wire w_btn_R_sw, w_btn_L_sw;
    wire w_btn_U, w_btn_D, w_btn_R, w_btn_L;
    wire w_rst_w, w_rst_sw;

    wire w_key_2, w_key_4, w_key_6, w_key_8;
    wire w_key_r, w_key_s, w_key_c;
    wire w_sw1,w_key_S,w_key_W;
    wire [7:0] w_rx_data;

    assign w_rst_sw = w_sw1 & rst;
    assign w_rst_w = ~(w_sw1) & rst;
    
    wire w_rx_done;

    uart_fifo_loopback U_UART_FIFO(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx),
        .rx_data(w_rx_data),
        .empty(w_empty),
        .rx_done(w_rx_done)
    );

    uart_cmd_decoder U_UART_CMD_DECODER(
        .clk(clk),
        .rst(rst),
        .rx_data(w_rx_data),
        .empty(w_empty),
        .btn_L(w_key_4),
        .btn_R(w_key_6),
        .btn_U(w_key_8),
        .btn_D(w_key_2),
        .btn_run(w_key_r),
        .btn_stop(w_key_s),
        .btn_clear(w_key_c),
        .key_W(w_key_W),
        .key_S(w_key_S)
    );
    switch_cu U_Switch_CU(
        .clk(clk),
        .rst(rst),
        .change_watch_to_stopwatch(change_watch_to_stopwatch),
        .key_W(w_key_W),
        .key_S(w_key_S),
        .sw1(w_sw1)
    );
    btn_selector sel_btnR(
        .sw_mode(w_sw1),
        .btn_in(w_btn_R),
        .btn_watch(w_btn_R_w),
        .btn_stopwatch(w_btn_R_sw)
    );

    btn_selector sel_btnL(
        .sw_mode(w_sw1),
        .btn_in(w_btn_L),
        .btn_watch(w_btn_L_w),
        .btn_stopwatch(w_btn_L_sw)
    );

    btn_selector sel_btnU(
        .sw_mode(w_sw1),
        .btn_in(w_btn_U),
        .btn_watch(w_btn_U_w),
        .btn_stopwatch() // U는 stopwatch엔 필요 없으니 미연결
    );

    btn_selector sel_btnD(
        .sw_mode(w_sw1),
        .btn_in(w_btn_D),
        .btn_watch(w_btn_D_w),
        .btn_stopwatch() // D도 stopwatch엔 필요 없으니 미연결
    );

    btn_debounce U_BD_btn_U(
        .i_btn(btn_U),
        .rst(rst),
        .clk(clk),
        .o_btn(w_btn_U)
    );

    btn_debounce U_BD_btn_D(
        .i_btn(btn_D),
        .rst(rst),
        .clk(clk),
        .o_btn(w_btn_D)
    );    

    btn_debounce U_BD_btn_R(
        .i_btn(btn_R),
        .rst(rst),
        .clk(clk),
        .o_btn(w_btn_R)
    );

    btn_debounce U_BD_btn_L(
        .i_btn(btn_L),
        .rst(rst),
        .clk(clk),
        .o_btn(w_btn_L)
    );

    stopwatch U_StopWatch(
        .clk(clk),
        //.rst(w_rst_sw),
        .rst(rst),
        .btn_R(w_btn_R_sw),
        //.change_hour_to_sec(change_hour_to_sec),
        .change_watch_to_stopwatch(w_sw1),
        .btn_L(w_btn_L_sw),
        .key_r(w_key_r),
        .key_s(w_key_s),
        .key_c(w_key_c),
        .o_stopwatch(w_stopwatch_24bit)
    );
    
    watch U_Watch(
        .clk(clk),
        //.rst(w_rst_w),
        .rst(rst),
        .modify_watch(modify_watch),
        .change_hour_to_sec(change_hour_to_sec),
        .change_watch_to_stopwatch(w_sw1),
        .btn_R(w_btn_R_w),
        .btn_L(w_btn_L_w),
        .btn_U(w_btn_U_w),
        .btn_D(w_btn_D_w),
        .btn_L_uart(w_key_4),
        .btn_R_uart(w_key_6),
        .btn_U_uart(w_key_8),
        .btn_D_uart(w_key_2),
        .o_watch(w_watch_24bit)
    );

    mux_2x1_24bit U_MUX_change_watch_to_stopwatch(
        .sel(w_sw1),
        .stopwatch_24bit(w_stopwatch_24bit),
        .watch_24bit(w_watch_24bit),
        .sel_24bit(w_sel_24bit)
    );

    fnd_controller U_Fnd_CNTL(
        .clk(clk),
        .reset(rst),
        .change_hour_to_sec(change_hour_to_sec),
        .msec(w_sel_24bit[6:0]),
        .sec(w_sel_24bit[12:7]),
        .min(w_sel_24bit[18:13]),
        .hour(w_sel_24bit[23:19]),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    led_indicator U_LED_Indicator(
        .clk(clk),
        .rst(rst),
        .led_mode({modify_watch,w_sw1,change_hour_to_sec}),
        .led(led)

    );
endmodule

module switch_cu (
    input clk,
    input rst,
    input change_watch_to_stopwatch,
    input key_W,
    input key_S,
    output sw1
);

    // state define
    parameter [2:0] IDLE = 0, KEY_W = 1, KEY_S = 2, SW_0 = 3, SW_1 = 4;

    // manage : state register
    reg [2:0] state_reg, state_next;
    reg sw1_reg, sw1_next;
    reg prev_sw_reg, prev_sw_next;

    assign sw1 = sw1_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            sw1_reg   <= change_watch_to_stopwatch;
            prev_sw_reg <= change_watch_to_stopwatch;
        end else begin
            state_reg <= state_next;
            sw1_reg   <= sw1_next;
            prev_sw_reg <= prev_sw_next;
        end
    end

    // next state CL
    always @(*) begin
        state_next = state_reg;
        sw1_next = sw1_reg;
        prev_sw_next = change_watch_to_stopwatch;
        case(state_reg)
            IDLE  : begin 
                sw1_next = 1'b0;
                    if(key_W == 1'b1) begin 
                        state_next = KEY_W;
                        sw1_next = 1'b0;
                    end else if(key_S == 1'b1) begin
                        state_next = KEY_S;
                        sw1_next = 1'b1;
                    end else if(change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end
                end
            KEY_W   : begin
                    sw1_next = 1'b0;
                    if (key_S == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = KEY_S;
                        sw1_next = 1'b1;
                    end else if (key_S == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = KEY_S;
                        sw1_next = 1'b1;
                    end else if(key_S == 1'b0 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else if (key_S == 1'b0 & prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end  else if (key_S == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else if (key_S == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end  else begin
                        state_next = KEY_W;
                    end
                end
            KEY_S :  begin
                    sw1_next = 1'b1;
                    if (key_W == 1'b0 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else if (key_W == 1'b0 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = KEY_W;
                        sw1_next = 1'b0;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b1;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = KEY_W;
                        sw1_next = 1'b0;
                    end else begin
                        state_next = KEY_S;
                    end
            end
            SW_0 :  begin
                    sw1_next = 1'b0;
                    if (key_S == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = KEY_S;
                        sw1_next = 1'b1;
                    end else if (key_S == 1'b0 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end  else if (key_S == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else if (key_S == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end else if (key_S == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = KEY_S;
                        sw1_next = 1'b1;
                    end else if (key_S == 1'b0 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end else begin
                        state_next = SW_0;
                    end
            end
            SW_1 :  begin
                    sw1_next = 1'b1;
                    if(key_W == 1'b0 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else if (key_W == 1'b0 & prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = KEY_W;
                        sw1_next = 1'b0;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b0 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = SW_1;
                        sw1_next = 1'b1;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b0) begin
                        state_next = SW_0;
                        sw1_next = 1'b0;
                    end else if (key_W == 1'b1 && prev_sw_reg == 1'b1 && change_watch_to_stopwatch == 1'b1) begin
                        state_next = KEY_W;
                        sw1_next = 1'b0;
                    end else begin
                        state_next = SW_1;
                    end
            end
        endcase
    end
endmodule

module uart_cmd_decoder (
    input clk,
    input rst,
    input [7:0] rx_data,
    input empty,
    output reg btn_L,
    output reg btn_R,
    output reg btn_U,
    output reg btn_D,
    output reg btn_clear,
    output reg btn_run,
    output reg btn_stop,
    output reg key_W,
    output reg key_S
);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            btn_L <= 0;
            btn_R <= 0;
            btn_U <= 0;
            btn_D <= 0;
            btn_clear <= 0;
            btn_run   <= 0;
            btn_stop   <= 0;
            key_W <= 0;
            key_S <= 0;
        end else begin
            btn_L <= 0;
            btn_R <= 0;
            btn_U <= 0;
            btn_D <= 0;
            btn_clear <= 0;
            btn_run <=0;
            btn_stop <=0;
            key_W <= 0;
            key_S <= 0;

            if (!empty) begin
                case (rx_data)
                    8'h32: btn_D <= 1;
                    8'h34: btn_L <= 1;
                    8'h36: btn_R <= 1;
                    8'h38: btn_U <= 1; 
                    8'h72: btn_run <= 1;
                    8'h73: btn_stop <= 1;
                    8'h63: btn_clear <= 1;
                    8'h53: key_S <= 1;
                    8'h57: key_W <= 1;
                endcase
            end
        end
    end
endmodule

module led_indicator (
    input clk,
    input rst,
    input [2:0] led_mode, // {change_watch_to_stopwatch,change_hour_to_sec}
    output reg [4:0] led
);
    always @(*) begin
        if(rst) begin
            led <= 5'b0000;
        end else begin
            case(led_mode)
                3'b000: led <= 5'b00100;
                3'b001: led <= 5'b01000;
                3'b010: led <= 5'b00001;
                3'b011: led <= 5'b00010;
                3'b100: led <= 5'b10100;
                3'b101: led <= 5'b11000;
                3'b110: led <= 5'b00001;
                3'b111: led <= 5'b00010;
                default: led <= 5'b0000;
            endcase
        end
    end
    
endmodule

module mux_2x1_24bit(
    input sel,
    input [23:0] stopwatch_24bit,
    input [23:0] watch_24bit,
    output reg [23:0] sel_24bit
);
    always @(*) begin
        case(sel)
            1'b0 : sel_24bit = watch_24bit;
            1'b1 : sel_24bit = stopwatch_24bit;
            default: sel_24bit = watch_24bit;
        endcase
    end
endmodule


