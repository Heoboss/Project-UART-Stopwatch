`timescale 1ns / 1ps
module stopwatch(
    input clk,
    input rst,
    input btn_R,
    input btn_L,
    input key_r,
    input key_s,
    input key_c,
   // input change_hour_to_sec,
    input change_watch_to_stopwatch,
    output [23:0] o_stopwatch
);
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    wire w_cu_clear, w_cu_run_stop;

    assign o_stopwatch = {w_hour,w_min,w_sec,w_msec};

    controller_unit_stopwatch U_Stopwatch_CU(
        .clk(clk),
        .rst(rst),
        .btnR(btn_R),
        .btnL(btn_L | key_c),
        .key_r(key_r),
        .key_s(key_s),
        .clear(w_cu_clear),
       // .change_hour_to_sec(change_hour_to_sec),
        .change_watch_to_stopwatch(change_watch_to_stopwatch),
        .run_stop(w_cu_run_stop)
    );

    stopwatch_dp U_SW_DP(
        .clk(clk),
        .rst(rst),
        .clear(w_cu_clear),
        .run_stop(w_cu_run_stop),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

endmodule

module watch(
    input clk,
    input rst,
    input modify_watch,
    input change_hour_to_sec,
    input change_watch_to_stopwatch,
    input btn_R,
    input btn_L,
    input btn_U,
    input btn_D,
    input btn_L_uart,
    input btn_R_uart,
    input btn_U_uart,
    input btn_D_uart,
    output [23:0] o_watch
);
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;
    wire o_run_stop;
    wire w_inc_hour_1, w_inc_hour_10, w_dec_hour_1, w_dec_hour_10;
    wire w_inc_min_1, w_inc_min_10, w_dec_min_1, w_dec_min_10;
    wire w_inc_sec_1, w_inc_sec_10, w_dec_sec_1, w_dec_sec_10;

    assign o_watch = {w_hour,w_min,w_sec,w_msec};

    controller_unit_watch U_Watch_CU(
        .clk(clk),
        .rst(rst),
        .btn_R(btn_R | btn_R_uart),
        .btn_L(btn_L | btn_L_uart),
        .btn_U(btn_U | btn_U_uart),
        .btn_D(btn_D | btn_D_uart),
        .inc_hour_1(w_inc_hour_1),
        .dec_hour_1(w_dec_hour_1),
        .inc_hour_10(w_inc_hour_10),
        .dec_hour_10(w_dec_hour_10),
        .inc_min_1(w_inc_min_1),
        .dec_min_1(w_dec_min_1),
        .inc_min_10(w_inc_min_10),
        .dec_min_10(w_dec_min_10),
        .inc_sec_1(w_inc_sec_1),
        .dec_sec_1(w_dec_sec_1),
        .inc_sec_10(w_inc_sec_10),
        .dec_sec_10(w_dec_sec_10),
        .modify_watch(modify_watch),
        .change_hour_to_sec(change_hour_to_sec),
        .change_watch_to_stopwatch(change_watch_to_stopwatch),
        .run_stop(o_run_stop)
    );

    watch_dp U_W_DP(
        .clk(clk),
        .rst(rst),
        .run_stop(o_run_stop),
        .inc_hour_1(w_inc_hour_1),
        .dec_hour_1(w_dec_hour_1),
        .inc_hour_10(w_inc_hour_10),
        .dec_hour_10(w_dec_hour_10),
        .inc_min_1(w_inc_min_1),
        .dec_min_1(w_dec_min_1),
        .inc_min_10(w_inc_min_10),
        .dec_min_10(w_dec_min_10),
        .inc_sec_1(w_inc_sec_1),
        .dec_sec_1(w_dec_sec_1),
        .inc_sec_10(w_inc_sec_10),
        .dec_sec_10(w_dec_sec_10),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

endmodule

module watch_dp (
    input clk,
    input rst,
    input run_stop,
    input inc_hour_1,
    input inc_hour_10,
    input dec_hour_1,
    input dec_hour_10,
    input inc_min_1,
    input inc_min_10,
    input dec_min_1,
    input dec_min_10,
    input inc_sec_1,
    input inc_sec_10,
    input dec_sec_1,
    input dec_sec_10,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_tick_msec,w_tick_sec,w_tick_min;

    // To count hour tick
    tick_counter_hour #(
        .TICK_COUNT(24),
        .WIDTH(5)
        ) U_HOUR_WATCH(
            .clk(clk),
            .rst(rst),
            .clear(1'b0),
            .inc_1(inc_hour_1),
            .dec_1(dec_hour_1),
            .inc_10(inc_hour_10),
            .dec_10(dec_hour_10),
            .i_tick(w_tick_min),
            .o_time(hour),
            .o_tick()
    );

    // To count min tick
    tick_counter #(
        .TICK_COUNT(60),
        .WIDTH(6)
        ) U_MIN_WATCH(
            .clk(clk),
            .rst(rst),
            .clear(1'b0),
            .inc_1(inc_min_1),
            .dec_1(dec_min_1),
            .inc_10(inc_min_10),
            .dec_10(dec_min_10),
            .i_tick(w_tick_sec),
            .o_time(min),
            .o_tick(w_tick_min)
    );

    // To count sec tick
    tick_counter #(
        .TICK_COUNT(60),
        .WIDTH(6)
        ) U_SEC_WATCH(
            .clk(clk),
            .rst(rst),
            .clear(1'b0),
            .inc_1(inc_sec_1),
            .dec_1(dec_sec_1),
            .inc_10(inc_sec_10),
            .dec_10(dec_sec_10),
            .i_tick(w_tick_msec),
            .o_time(sec),
            .o_tick(w_tick_sec)
    );
    // To count msec tick
    tick_counter #(
        .TICK_COUNT(100),
        .WIDTH(7)
        ) U_MSEC_WATCH(
            .clk(clk),
            .rst(rst),
            .clear(1'b0),
            .inc_1(1'b0),
            .dec_1(1'b0),
            .inc_10(1'b0),
            .dec_10(1'b0),
            .i_tick(w_tick_100hz),
            .o_time(msec),
            .o_tick(w_tick_msec)
    );
    
    // To generate 100hz tick
    tick_gen_100hz U_TICK_GEN_WATCH(
        .clk(clk),
        .rst(rst),
        .clear(1'b0),
        .run_stop(run_stop),
        .o_tick(w_tick_100hz)
    );

endmodule

module stopwatch_dp (
    input clk,
    input rst,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_tick_msec,w_tick_sec,w_tick_min;

    // To count hour tick
    tick_counter #(
        .TICK_COUNT(24),
        .WIDTH(5)
        ) U_HOUR_STOPWATCH(
            .clk(clk),
            .rst(rst),
            .clear(clear),
            .inc_1(1'b0),
            .dec_1(1'b0),
            .inc_10(1'b0),
            .dec_10(1'b0),
            .i_tick(w_tick_min),
            .o_time(hour),
            .o_tick()
    );

    // To count min tick
    tick_counter #(
        .TICK_COUNT(60),
        .WIDTH(6)
        ) U_MIN_STOPWATCH(
            .clk(clk),
            .rst(rst),
            .clear(clear),
            .inc_1(1'b0),
            .dec_1(1'b0),
            .inc_10(1'b0),
            .dec_10(1'b0),
            .i_tick(w_tick_sec),
            .o_time(min),
            .o_tick(w_tick_min)
    );

    // To count sec tick
    tick_counter #(
        .TICK_COUNT(60),
        .WIDTH(6)
        ) U_SEC_STOPWATCH(
            .clk(clk),
            .rst(rst),
            .clear(clear),
            .inc_1(1'b0),
            .dec_1(1'b0),
            .inc_10(1'b0),
            .dec_10(1'b0),
            .i_tick(w_tick_msec),
            .o_time(sec),
            .o_tick(w_tick_sec)
    );
    // To count msec tick
    tick_counter #(
        .TICK_COUNT(100),
        .WIDTH(7)
        ) U_MSEC_STOPWATCH(
            .clk(clk),
            .rst(rst),
            .clear(clear),
            .inc_1(1'b0),
            .dec_1(1'b0),
            .inc_10(1'b0),
            .dec_10(1'b0),
            .i_tick(w_tick_100hz),
            .o_time(msec),
            .o_tick(w_tick_msec)
    );
    
    // To generate 100hz tick
    tick_gen_100hz U_TICK_GEN_STOPWATCH(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .run_stop(run_stop),
        .o_tick(w_tick_100hz)
    );

endmodule

module tick_counter #(parameter TICK_COUNT = 100, WIDTH = 7) (
    input clk,
    input rst,
    input i_tick,
    input clear,
    input inc_1,
    input dec_1,
    input inc_10,
    input dec_10,
    output [WIDTH-1:0] o_time,
    output o_tick
);
    reg [$clog2(TICK_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    assign o_time = counter_reg;
    assign o_tick = tick_reg;

    // 동기 블록: 실제 레지스터 업데이트
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_reg    <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg    <= tick_next;
        end
    end

    // 조합 블록: 다음 상태 계산
    always @(*) begin
        counter_next = counter_reg;
        tick_next    = 1'b0;  // 기본값은 0으로 설정

        if (i_tick) begin
            if (counter_reg == TICK_COUNT - 1) begin
                counter_next = 0;
                tick_next    = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
                tick_next    = 1'b0;
            end
        end

        if (clear) begin
            counter_next = 0;
        end else if (inc_1) begin
            if (counter_reg + 1 >= TICK_COUNT)
                counter_next = 0;
            else
                counter_next = counter_reg + 1;
        end else if (inc_10) begin
            if (counter_reg + 10 >= TICK_COUNT)
                counter_next = (counter_reg + 10) - TICK_COUNT;
            else
                counter_next = counter_reg + 10;
        end else if (dec_1) begin
            if (counter_reg == 0)
                counter_next = TICK_COUNT - 1;
            else
                counter_next = counter_reg - 1;
        end else if (dec_10) begin
            if (counter_reg < 10)
                counter_next = TICK_COUNT + (counter_reg - 10);
            else
                counter_next = counter_reg - 10;
        end
    end
endmodule

module tick_counter_hour #(parameter TICK_COUNT = 100, WIDTH = 7) (
    input clk,
    input rst,
    input i_tick,
    input clear,
    input inc_1,
    input dec_1,
    input inc_10,
    input dec_10,
    output [WIDTH-1:0] o_time,
    output o_tick
);
    reg [$clog2(TICK_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    assign o_time = counter_reg;
    assign o_tick = tick_reg;

    // 동기 블록: 레지스터 업데이트
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 12;        // 시계 전용 초기값 12시
            tick_reg    <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg    <= tick_next;
        end
    end

    // 조합 블록: 다음 상태 계산
    always @(*) begin
        counter_next = counter_reg;
        tick_next    = 1'b0;  // 기본값

        if (i_tick) begin
            if (counter_reg == TICK_COUNT - 1) begin
                counter_next = 0;
                tick_next    = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
                tick_next    = 1'b0;
            end
        end

        if (clear) begin
            counter_next = 0;
        end else if (inc_1) begin
            if (counter_reg + 1 >= TICK_COUNT)
                counter_next = 0;
            else
                counter_next = counter_reg + 1;
        end else if (inc_10) begin
            if (counter_reg + 10 >= TICK_COUNT)
                counter_next = (counter_reg + 10) - TICK_COUNT;
            else
                counter_next = counter_reg + 10;
        end else if (dec_1) begin
            if (counter_reg == 0)
                counter_next = TICK_COUNT - 1;
            else
                counter_next = counter_reg - 1;
        end else if (dec_10) begin
            if (counter_reg < 10)
                counter_next = TICK_COUNT + (counter_reg - 10);
            else
                counter_next = counter_reg - 10;
        end
    end
endmodule


/*module tick_counter #(parameter TICK_COUNT = 100, WIDTH = 7) (
    input clk,
    input rst,
    input i_tick,
    input clear,
    input inc_1,
    input dec_1,
    input inc_10,
    input dec_10,
    output [WIDTH-1:0] o_time,
    output o_tick
);
    reg [$clog2(TICK_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg,tick_next;

    assign o_time = counter_reg;
    assign o_tick = tick_reg;

    always @(posedge clk, posedge rst) begin
        if(rst)begin
            counter_reg <= 0;
            tick_reg <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end

    // next logic
    always @(*) begin
        counter_next = counter_reg;
        tick_next = tick_reg; // 아니면 이걸 tick_next = 1'b0; 으로 수정
        if(i_tick)begin
            if (counter_reg == TICK_COUNT-1) begin
                counter_next = 0;
                tick_next = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
                tick_next = 1'b0;
            end
        end else tick_next = 1'b0;
        if (clear == 1)begin
            counter_next = 0;
        end else if(inc_1)begin
            if(counter_reg + 1 >= TICK_COUNT)begin
                counter_reg = 0;
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg + 1;
            end
        end else if(inc_10)begin
            if(counter_reg + 10 >= TICK_COUNT)begin
                counter_reg = ( (counter_reg+10) - TICK_COUNT);
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg + 1;
            end 
        end else if(dec_1) begin
            if(counter_reg - 1 < 0)begin
                counter_reg = TICK_COUNT-1;
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg - 1;
            end
        end else if(dec_10) begin
            if(counter_reg - 10 < 0)begin
                counter_reg = TICK_COUNT + (counter_reg - 10);
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg - 10;
            end
        end
    end
endmodule

module tick_counter_hour #(parameter TICK_COUNT = 100, WIDTH = 7) (
    input clk,
    input rst,
    input i_tick,
    input clear,
    input inc_1,
    input dec_1,
    input inc_10,
    input dec_10,
    output [WIDTH-1:0] o_time,
    output o_tick
);
    reg [$clog2(TICK_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg,tick_next;

    assign o_time = counter_reg;
    assign o_tick = tick_reg;

    always @(posedge clk, posedge rst) begin
        if(rst)begin
            counter_reg <= 12;
            tick_reg <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end

    // next logic
    always @(*) begin
        counter_next = counter_reg;
        tick_next = tick_reg; // 아니면 이걸 tick_next = 1'b0; 으로 수정
        if(i_tick)begin
            if (counter_reg == TICK_COUNT-1) begin
                counter_next = 0;
                tick_next = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
                tick_next = 1'b0;
            end
        end else tick_next = 1'b0;

        if (clear == 1)begin
            counter_next = 0;
        end else if(inc_1)begin
            if(counter_reg + 1 >= TICK_COUNT)begin
                counter_reg = 0;
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg + 1;
            end
        end else if(inc_10)begin
            if(counter_reg + 10 >= TICK_COUNT)begin
                counter_reg = ( (counter_reg+10) - TICK_COUNT);
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg + 1;
            end 
        end else if(dec_1) begin
            if(counter_reg - 1 < 0)begin
                counter_reg = TICK_COUNT-1;
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg - 1;
            end
        end else if(dec_10) begin
            if(counter_reg - 10 < 0)begin
                counter_reg = TICK_COUNT + (counter_reg - 10);
                counter_next = counter_reg;
            end else begin
                counter_next = counter_reg - 10;
            end
        end
    end
endmodule
*/

module tick_gen_100hz (
    input clk,
    input rst,
    input clear,
    input run_stop,
    output o_tick
);
    reg [$clog2(1_000_000)-1:0] counter;
    reg r_tick;
    assign o_tick = r_tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter <= 1'b0;
            r_tick  <= 1'b0;
        end else begin
            if(run_stop == 1)begin
                if (counter == (1000000 - 1)) begin
                    counter <= 1'b0;
                    r_tick  <= 1'b1;
                end else begin
                    counter <= counter + 1;
                    r_tick  <= 1'b0;
                end
            end else if (clear) begin
                counter <=0;
            end
        end
    end

endmodule

