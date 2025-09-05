`timescale 1ns / 1ps

module uart_fifo_loopback (
    input  clk,
    input  rst,
    input  rx,
    output tx,
    output [7:0] rx_data,
    output empty,
    output rx_done
);

    wire w_b_tick, w_rx_done;
    wire w_lp_pop,w_lp_push, w_tx_start, w_tx_busy;
    wire [7:0] w_rx_data, w_tx_data, w_loop_back_data;
    assign rx_data = w_rx_data;

    assign empty = w_lp_push;

    assign rx_done = w_rx_done;

    uart U_UART(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx_start(~w_tx_start),
        .tx_data(w_tx_data),
        .tx(tx),
        .tx_busy(w_tx_busy),
        .rx_data(w_rx_data),
        .rx_busy(),
        .rx_done(w_rx_done)
    );

    fifo U_UART_TX_FIFO(
        .clk(clk),
        .rst(rst),
        .w_data(w_loop_back_data),
        .push(~w_lp_push),
        .pop(~w_tx_busy),
        .full(w_lp_pop),
        .empty(w_tx_start),
        .r_data(w_tx_data)
    );

    fifo U_UART_RX_FIFO(
        .clk(clk),
        .rst(rst),
        .w_data(w_rx_data),
        .push(w_rx_done),
        .pop(~w_lp_pop),
        .full(),
        .empty(w_lp_push),
        .r_data(w_loop_back_data)
    );

    
endmodule

module uart(
    input        clk,
    input        rst,
    input        rx,
    input        tx_start,
    input [7:0]  tx_data,
    output       tx,
    output       tx_busy,
    output [7:0] rx_data,
    output       rx_busy,
    output       rx_done
);
    wire w_b_tick;  

    baud_tick_gen U_Baud_Tick_Gen(
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );

    uart_rx U_UART_RX(
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done(rx_done)
    );

    uart_tx U_UART_TX(
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .b_tick(w_b_tick),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .tx(tx)
    );

endmodule

module ascii_sender(
    input clk,
    input rst,
    input btn_start,
    input tx_busy,
    output send_start,
    output [7:0] ascii_data
);
    
    // state
    parameter IDLE = 0, SEND = 1;

    // manage state register
    reg state;
    reg [2:0]send_count;
    reg [7:0] r_ascii_data[0:4];
    reg r_send;

    assign ascii_data = r_ascii_data[send_count];
    assign send_start = r_send;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            r_send <= 0;
            send_count <= 0;
            r_ascii_data[0] <= "h"; // ASCII 
            r_ascii_data[1] <= "e"; // ASCII 
            r_ascii_data[2] <= "l"; // ASCII 
            r_ascii_data[3] <= "l"; // ASCII 
            r_ascii_data[4] <= "o"; // ASCII 
        end else begin
            case(state)
                IDLE: begin
                    send_count <= 0;
                    r_send <= 1'b0;
                    if(btn_start)begin
                        state <= SEND;
                        r_send <= 1'b1;
                    end
                end
                SEND: begin
                    r_send <= 1'b0; // 1 tick
                    if(!tx_busy && !r_send)begin
                            send_count <= send_count + 1;
                            r_send <= 1'b1;
                        if(send_count == 3'h4) begin
                            r_send <= 1'b0;
                            state <= IDLE;
                            send_count <= 0;
                        end
                        else state <= SEND;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

module uart_rx (
    input clk,
    input rst,
    input b_tick,
    input rx,
    output [7:0] rx_data,
    output rx_busy,
    output rx_done
);
    // state
    localparam[1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    // manage : state register
    reg [1:0] state_reg, state_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next; // 16 tick counter
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg rx_done_reg, rx_done_next;
    reg rx_busy_reg, rx_busy_next;

    // output
    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;
    assign rx_busy = rx_busy_reg;

    // state registeer
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state_reg      <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            rx_data_reg    <= 0;
            rx_busy_reg    <= 0;
            rx_done_reg    <= 0;
        end else begin
            state_reg      <= state_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            rx_data_reg <= rx_data_next;
            rx_busy_reg <= rx_busy_next;
            rx_done_reg <= rx_done_next;

        end
    end

    // next combinational logic
    always @(*) begin
        state_next      = state_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        rx_busy_next    = rx_busy_reg;
        rx_done_next    = rx_done_reg;
        rx_data_next    = rx_data_reg;
        case (state_reg)
            IDLE: begin
                rx_done_next = 1'b0;
                if (rx == 1'b0) begin // rx == 0 , receive start
                    bit_cnt_next  = 0;
                    b_tick_cnt_next = 0;
                    rx_busy_next    = 1'b1;
                    state_next       = START;
                end
            end
            START: begin
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 0;
                        state_next      = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        rx_data_next = {rx, rx_data_reg[7:1]};
                        // rx_data_next = rx_data_reg >> 1; 이러면 MSB 0으로 채워지고 순환 x
                        if (bit_cnt_reg == 7) begin
                            state_next   = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 15) begin
                        rx_done_next    = 1'b1;
                        rx_busy_next    = 1'b0;
                        state_next      = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end


endmodule

module uart_tx (
    input clk,
    input rst,
    input start,
    input b_tick,
    input [7:0] tx_data,
    output tx_busy,
    output tx
);

    // state define
    parameter [2:0] IDLE = 0, WAIT = 1, START = 2, DATA = 3, STOP = 4;

    // manage : state register
    reg [2:0] c_state, n_state;
    reg c_tx_busy, n_tx_busy, c_tx, n_tx;
    reg [3:0] c_bit_cnt,n_bit_cnt;
    reg [3:0] tick_cnt_reg, tick_cnt_next;
    reg [7:0] data_reg, data_next;

    // output combinational logic
    assign tx = c_tx;
    assign tx_busy = c_tx_busy;
    
    // FSM
    // state register SL
    always @(posedge clk, posedge rst) begin 
        if(rst) begin
            c_state <= IDLE;
            c_tx <= 1'b1;
            c_tx_busy <= 1'b0;
            c_bit_cnt <= 3'b000;
            tick_cnt_reg <= 4'h0;
            data_reg <= 8'h00;
        end else begin
            c_state <= n_state;
            c_tx <= n_tx;
            c_tx_busy <= n_tx_busy;
            c_bit_cnt <= n_bit_cnt;
            tick_cnt_reg <= tick_cnt_next;
            data_reg <= data_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        n_tx = c_tx;
        n_tx_busy = c_tx_busy;
        n_bit_cnt = c_bit_cnt;
        tick_cnt_next = tick_cnt_reg; // 전 상태를 유지하겠다.
        data_next = data_reg;
        case(c_state)
            IDLE:begin
                n_tx = 1'b1;
                //n_tx_busy = 1'b0;
                tick_cnt_next = 4'h0;
                if(start == 1) begin
                    n_state = WAIT;
                    n_tx_busy = 1'b1; // mealy machine 왜냐하면 현재상태와 출력 조건을 보고 나간거니까
                    data_next = tx_data;
                end
            end
            WAIT:begin
                if(b_tick == 1)begin
                    n_state = START;
                end 
            end
            START:begin
                n_tx = 1'b0;
                n_bit_cnt = 0;
                if(b_tick == 1)begin
                    if (tick_cnt_reg == 15) begin
                        n_state = DATA;
                        tick_cnt_next = 4'h0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA:begin
                n_tx = data_reg[0]; // lsb out
                if(b_tick==1)begin
                    if (tick_cnt_reg == 15) begin
                        data_next = data_reg >> 1; // shift register : 오른쪽으로 1bit 밀어서 다음거 가져가게 함
                        tick_cnt_next = 4'h0;
                        if(n_bit_cnt == 7)begin
                            n_state = STOP;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1;
                            n_state = DATA;
                        end
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            STOP:begin
                n_tx = 1'b1;
                if(b_tick == 1)begin
                    if (tick_cnt_reg == 15) begin
                        n_state = IDLE;
                        n_tx_busy = 1'b0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end 
            end
        endcase
    end

    
endmodule

module baud_tick_gen (
    input clk,
    input rst,
    output b_tick
);
    // tick bps : 9600 -> 600
    parameter BAUD_COUNT = 100_000_000/(9600 * 16);
    reg [$clog2(BAUD_COUNT)-1:0] r_counter;
    reg r_tick;
    always @(posedge clk, posedge rst) begin
        if(rst)begin
            r_counter <= 0;
            r_tick <= 0;
        end else begin
            if(r_counter == BAUD_COUNT - 1)begin
                r_tick <= 1'b1;
                r_counter <= 0;
            end else begin 
                r_counter <= r_counter +1;
                r_tick <= 1'b0;
            end
        end
    end
    assign b_tick = r_tick;

endmodule

/*module uart_loopback(
    input clk,
    input rst,
    input rx,
    output tx
);

    wire w_b_tick, w_rx_done;
    wire [7:0] w_rx_data;
    uart U_Uart_loopback(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx_start(w_rx_done),
        .tx_data(w_rx_data),
        .tx(tx),
        .tx_busy(),
        .rx_data(w_rx_data),
        .rx_busy(),
        .rx_done(w_rx_done)
    );
    
endmodule*/