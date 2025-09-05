`timescale 1ns / 1ps
module controller_unit_stopwatch(
    input clk,
    input rst,
    input btnR,
    input btnL,
    input key_r,
    input key_s,
    input change_watch_to_stopwatch,
    output run_stop, 
    output clear
);

    // fsm Controll Unit
    // parameter state define
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, UP = 3'b011, DOWN = 3'b100;

    // manage : state register
    reg [2:0] c_state, n_state;
    reg c_clear, n_clear;

    // state register SL
    always @(posedge clk, posedge rst) begin 
        if(rst) begin
            c_state <= STOP;
            c_clear <= 1'b0;
        end else begin
            c_state <= n_state;
            c_clear <= n_clear;
        end
    end

    // next state combinational logic
    always @(*)begin
        n_state = c_state; // latch 방지
        n_clear = c_clear;
        if(change_watch_to_stopwatch == 1) begin
            case(c_state)
                STOP  : begin 
                    n_clear = 1'b0;
                        if(btnR == 1'b1) begin 
                            n_state = RUN;
                        end else if(btnL == 1'b1) begin
                            n_state = CLEAR;
                        end else if(key_r == 1'b1) begin
                            n_state = RUN;
                        end else n_state = c_state;
                    end
                RUN   : begin
                        if(btnR == 1'b1) begin
                            n_state = STOP;
                        end else if(key_s == 1'b1) begin
                            n_state = STOP;
                        end else n_state = c_state;
                    end
                CLEAR :  begin
                        n_state = STOP;
                        n_clear = 1'b1;
                end
            endcase
        end
    end
    // output combinational logic
    assign run_stop = (c_state == RUN) ? 1'b1 : 1'b0;
    // 10ns clk 1tick generate
    assign clear = c_clear;
endmodule

module controller_unit_watch(
    input clk,
    input rst,
    input btn_R,
    input btn_L,
    input btn_U,
    input btn_D,
    input modify_watch,
    input change_hour_to_sec,
    input change_watch_to_stopwatch,
    output run_stop, 
    output inc_hour_1,
    output inc_hour_10,
    output dec_hour_1,
    output dec_hour_10,
    output inc_min_1,
    output inc_min_10,
    output dec_min_1,
    output dec_min_10,
    output inc_sec_1,
    output inc_sec_10,
    output dec_sec_1,
    output dec_sec_10
);

    // fsm Controll Unit
    // parameter state define
    parameter RUN = 0, SEC_1 = 1,SEC_10 = 2, MIN_1 = 3,  MIN_10 = 4, 
    HOUR_1 = 5, HOUR_10 = 6;

    // manage : state register
    reg [2:0] c_state, n_state;
    reg c_runstop, n_runstop;
    reg c_inc_sec_1,n_inc_sec_1,c_inc_sec_10,n_inc_sec_10,
    c_inc_min_1,n_inc_min_1,c_inc_min_10,n_inc_min_10,
    c_inc_hour_1,n_inc_hour_1,c_inc_hour_10,n_inc_hour_10,
    c_dec_sec_1,n_dec_sec_1,c_dec_sec_10,n_dec_sec_10,
    c_dec_min_1,n_dec_min_1,c_dec_min_10,n_dec_min_10,
    c_dec_hour_1,n_dec_hour_1,c_dec_hour_10,n_dec_hour_10;


    // state register SL
    always @(posedge clk, posedge rst) begin 
        if(rst) begin
            c_state <= RUN;
            c_runstop <= 1'b0;
            c_inc_sec_1 <= 1'b0; 
            c_inc_sec_10 <= 1'b0;
            c_inc_min_1 <= 1'b0;
            c_inc_min_10 <= 1'b0;
            c_inc_hour_1 <= 1'b0;
            c_inc_hour_10 <= 1'b0;
            c_dec_sec_1 <= 1'b0; 
            c_dec_sec_10 <= 1'b0;
            c_dec_min_1 <= 1'b0;
            c_dec_min_10 <= 1'b0;
            c_dec_hour_1 <= 1'b0;
            c_dec_hour_10 <= 1'b0;
        end else begin
            c_state <= n_state;
            c_runstop <= n_runstop;
            c_inc_sec_1 <= n_inc_sec_1;
            c_inc_sec_10 <= n_inc_sec_10;
            c_inc_min_1 <= n_inc_min_1;
            c_inc_min_10 <= n_inc_min_10;
            c_inc_hour_1 <= n_inc_hour_1;
            c_inc_hour_10 <= n_inc_hour_10;
            c_dec_sec_1 <= n_dec_sec_1; 
            c_dec_sec_10 <= n_dec_sec_10;
            c_dec_min_1 <= n_dec_min_1;
            c_dec_min_10 <= n_dec_min_10;
            c_dec_hour_1 <= n_dec_hour_1;
            c_dec_hour_10 <= n_dec_hour_10;
            
        end
    end

    // next state combinational logic
        always @(*)begin
            n_state = c_state; // latch 방지
            n_runstop =     c_runstop;
            n_inc_sec_1 = c_inc_sec_1;
            n_inc_sec_10 = c_inc_sec_10;
            n_inc_min_1 = c_inc_min_1;
            n_inc_min_10 = c_inc_min_10;
            n_inc_hour_1 = c_inc_hour_1;
            n_inc_hour_10 = c_inc_hour_10;
            n_dec_sec_1 =   c_dec_sec_1;
            n_dec_sec_10 =  c_dec_sec_10;
            n_dec_min_1 =   c_dec_min_1;
            n_dec_min_10 =  c_dec_min_10;
            n_dec_hour_1 =  c_dec_hour_1;
            n_dec_hour_10 = c_dec_hour_10;
            case(c_state)
                RUN  : begin 
                    n_runstop = 1'b1; 
                    n_inc_sec_1 = 1'b0; n_inc_sec_10 = 1'b0; 
                    n_inc_min_1 = 1'b0; n_inc_min_10 = 1'b0;
                    n_inc_hour_1 = 1'b0; n_inc_hour_10 = 1'b0; 
                    n_dec_sec_1 = 1'b0; n_dec_sec_10 = 1'b0;
                    n_dec_min_1 = 1'b0; n_dec_min_10 = 1'b0; 
                    n_dec_hour_1 = 1'b0; n_dec_hour_10 = 1'b0;
                    if(change_watch_to_stopwatch == 0) begin 
                        if(modify_watch == 1 && change_hour_to_sec == 0)begin
                            n_state = SEC_1;
                        end else if(modify_watch == 1 && change_hour_to_sec == 1) begin
                            n_state = MIN_1;
                        end else n_state = RUN;
                    end 
                end
                SEC_1   : begin
                    n_runstop = 1'b0;
                    n_inc_sec_1 = 1'b0; n_inc_sec_10 = 1'b0; 
                    n_inc_min_1 = 1'b0; n_inc_min_10 = 1'b0;
                    n_inc_hour_1 = 1'b0; n_inc_hour_10 = 1'b0; 
                    n_dec_sec_1 = 1'b0; n_dec_sec_10 = 1'b0;
                    n_dec_min_1 = 1'b0; n_dec_min_10 = 1'b0; 
                    n_dec_hour_1 = 1'b0; n_dec_hour_10 = 1'b0;
                    if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 0) begin
                            if(btn_R == 1) begin
                                n_state = SEC_10;
                            end else if(btn_L == 1) begin
                                n_state = SEC_10;
                            end else if(btn_U == 1) begin
                                n_state = SEC_1;
                                n_inc_sec_1 = 1'b1;
                            end else if(btn_D == 1) begin
                                n_state = SEC_1;
                                n_dec_sec_1 = 1'b1;
                            end
                    end else if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 1)
                        n_state = MIN_1;
                    else begin
                        n_state = RUN;
                    end
                end
                SEC_10 :  begin
                    n_runstop = 1'b0;
                    n_inc_sec_10 = 1'b0;
                    n_dec_sec_10 = 1'b0;
                    if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 0) begin
                            if(btn_R == 1) begin
                                n_state = SEC_1;
                            end else if(btn_L == 1) begin
                                n_state = SEC_1;
                            end else if(btn_U == 1) begin
                                n_state = SEC_10;
                                n_inc_sec_10 = 1'b1;
                            end else if(btn_D == 1) begin
                                n_state = SEC_10;
                                n_dec_sec_10 = 1'b1;
                            end
                    end else if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 1)
                        n_state = MIN_1;
                    else begin
                        n_state = RUN;
                    end
                end
                MIN_1   : begin
                    n_runstop = 1'b0;
                    n_inc_sec_1 = 1'b0; n_inc_sec_10 = 1'b0; 
                    n_inc_min_1 = 1'b0; n_inc_min_10 = 1'b0;
                    n_inc_hour_10 = 1'b0; 
                    n_dec_sec_1 = 1'b0; n_dec_sec_10 = 1'b0;
                    n_dec_min_1 = 1'b0; n_dec_min_10 = 1'b0; 
                    n_dec_hour_10 = 1'b0;
                    if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 1) begin
                            if(btn_R == 1) begin
                                n_state = HOUR_10;
                            end else if(btn_L == 1) begin
                                n_state = MIN_10;
                            end else if(btn_U == 1) begin
                                n_state = MIN_1;
                                n_inc_min_1 = 1'b1;
                            end else if(btn_D == 1) begin
                                n_state = MIN_1;
                                n_dec_min_1 = 1'b1;
                            end
                    end else if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 0)
                        n_state = SEC_1;
                    else begin
                        n_state = RUN;
                    end
                end
                MIN_10 :  begin
                    n_runstop = 1'b0;
                    n_inc_hour_1 = 1'b0; n_dec_hour_1 = 1'b0;
                    n_inc_min_1 = 1'b0; n_dec_min_1 = 1'b0;
                    n_inc_min_10 = 1'b0; n_dec_min_10 = 1'b0;
                    if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 1) begin
                            if(btn_R == 1) begin
                                n_state = MIN_1;
                            end else if(btn_L == 1) begin
                                n_state = HOUR_1;
                            end else if(btn_U == 1) begin
                                n_state = MIN_10;
                                n_inc_min_10 = 1'b1;
                            end else if(btn_D == 1) begin
                                n_state = MIN_10;
                                n_dec_min_10 = 1'b1;
                            end
                    end else if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 0)
                        n_state = SEC_1;
                    else begin
                        n_state = RUN;
                    end
                end
                HOUR_1   : begin
                    n_runstop = 1'b0;
                    n_inc_hour_10 = 1'b0; n_dec_hour_10 = 1'b0;
                    n_inc_min_10 = 1'b0; n_dec_min_10 = 1'b0;
                    n_inc_hour_1 = 1'b0; n_dec_hour_1 = 1'b0;
                    if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 1) begin
                            if(btn_R == 1) begin
                                n_state = MIN_10;
                            end else if(btn_L == 1) begin
                                n_state = HOUR_10;
                            end else if(btn_U == 1) begin
                                n_state = HOUR_1;
                                n_inc_hour_1 = 1'b1;
                            end else if(btn_D == 1) begin
                                n_state = HOUR_1;
                                n_dec_hour_1 = 1'b1;
                            end
                    end else if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 0)
                        n_state = SEC_1;
                    else begin
                        n_state = RUN;
                    end
                end
                HOUR_10 :  begin
                    n_runstop = 1'b0;
                    n_inc_sec_1 = 1'b0; n_dec_sec_1 = 1'b0;
                    n_inc_hour_1 = 1'b0; n_dec_hour_1 = 1'b0;
                    n_inc_hour_10 = 1'b0; n_dec_hour_10 = 1'b0;
                    if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 1) begin
                            if(btn_R == 1) begin
                                n_state = HOUR_1;
                            end else if(btn_L == 1) begin
                                n_state = MIN_1;
                            end else if(btn_U == 1) begin
                                n_state = HOUR_10;
                                n_inc_hour_10 = 1'b1;
                            end else if(btn_D == 1) begin
                                n_state = HOUR_10;
                                n_dec_hour_10 = 1'b1;
                            end
                    end else if(change_watch_to_stopwatch == 0 && modify_watch == 1 
                        && change_hour_to_sec == 0)
                        n_state = SEC_1;
                    else begin
                        n_state = RUN;
                    end
                end
            endcase
        end
    // output combinational logic
    assign run_stop = c_runstop;
    assign inc_hour_1 = c_inc_hour_1;
    assign dec_hour_1 = c_dec_hour_1;
    assign inc_hour_10 = c_inc_hour_10;
    assign dec_hour_10 = c_dec_hour_10;
    assign inc_min_1 = c_inc_min_1;
    assign inc_min_10 = c_inc_min_10;
    assign dec_min_1 = c_dec_min_1;
    assign dec_min_10 = c_dec_min_10;
    assign inc_sec_1 = c_inc_sec_1;
    assign inc_sec_10 = c_inc_sec_10;
    assign dec_sec_1 = c_dec_sec_1;
    assign dec_sec_10 = c_dec_sec_10;
endmodule