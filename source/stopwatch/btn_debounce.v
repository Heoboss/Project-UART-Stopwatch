`timescale 1ns / 1ps
module btn_debounce(
    input clk,
    input rst,
    input i_btn,
    output o_btn
);
    wire debounce;
    reg [3:0] q_reg, q_next;
    // clkj divider 1Mhz
    reg [$clog2(100)-1:0] counter;
    reg r_db_clk;

    always @(posedge clk, posedge rst) begin
        if(rst)begin
            counter <= 0;
            r_db_clk <= 1'b0;
        end else begin
            if(counter == (100-1))begin 
                counter <= 0;
                r_db_clk <= 1'b1;
            end else begin
                counter <= counter + 1;
                r_db_clk <= 1'b0;
            end
        end
    end
    // shift register SL
    always @(posedge r_db_clk, posedge rst) begin
        if(rst)begin
            q_reg <= 4'b0000;
        end else begin
            q_reg <= q_next;
        end
    end

    // Combinational Logic
    // shift 연산 구현
    always @(*) begin
        q_next = {i_btn, q_reg[3:1]};
    end

    // 4 input AND Logic
    assign debounce = &q_reg;

    reg edge_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign o_btn = ~edge_reg & debounce;
endmodule
