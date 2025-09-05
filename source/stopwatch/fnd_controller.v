`timescale 1ns / 1ps
module fnd_controller(
    input clk,
    input reset,
    input change_hour_to_sec,
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    input [4:0] hour,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);
    wire [3:0] w_digit_msec_1;
    wire [3:0] w_digit_msec_10;
    wire [3:0] w_digit_sec_1;
    wire [3:0] w_digit_sec_10;

    wire [3:0] w_digit_min_1;
    wire [3:0] w_digit_min_10;
    wire [3:0] w_digit_hour_1;
    wire [3:0] w_digit_hour_10;
    
    wire [3:0] w_bcd_data,w_bcd_data_msec_sec,w_bcd_data_min_hour;

    wire [2:0] w_digit_sel;
    
    wire w_clk_1khz;

    wire w_dot_onoff;

    digit_spliter #(.DS_WIDTH(5)) U_HOUR_DS(
        .i_data(hour),
        .digit_1(w_digit_hour_1),
        .digit_10(w_digit_hour_10)
    );
    
    digit_spliter #(.DS_WIDTH(6)) U_MIN_DS(
        .i_data(min),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10)
    );
    
    digit_spliter #(.DS_WIDTH(6)) U_SEC_DS(
        .i_data(sec),
        .digit_1(w_digit_sec_1),
        .digit_10(w_digit_sec_10)
    );

    digit_spliter #(.DS_WIDTH(7)) U_MSEC_DS(
        .i_data(msec),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10)
    );
    
    clk_div U_Clk_div(
        .clk(clk),
        .reset(reset),
        .o_1khz(w_clk_1khz)
    );

    counter_8 U_Counter_8(
        .clk(w_clk_1khz),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_Decoder_2x4(
        .sel(w_digit_sel[1:0]),
        .fnd_com(fnd_com)
    );
    mux_2x1_4bit U_MUX_2x1(
        .sel(change_hour_to_sec),
        .x0(w_bcd_data_msec_sec),
        .x1(w_bcd_data_min_hour),
        .bcd_data(w_bcd_data)
    );
    dot_comp U_DOT_COMP(
        .msec(msec),
        .dot_onoff(w_dot_onoff)    
    );
    mux_8x1 U_MUX_8x1_MSEC_SEC(
        .sel(w_digit_sel),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10),
        .digit_100(w_digit_sec_1),
        .digit_1000(w_digit_sec_10),
        .digit_off_1(4'he),
        .digit_off_10(4'he),
        .digit_dot({3'b111,w_dot_onoff}),
        .digit_off_1000(4'he),
        .bcd_data(w_bcd_data_msec_sec)
    );
    mux_8x1 U_MUX_8x1_MIN_HOUR(
        .sel(w_digit_sel),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10),
        .digit_100(w_digit_hour_1),
        .digit_1000(w_digit_hour_10),
        .digit_off_1(4'he),
        .digit_off_10(4'he),
        .digit_dot({3'b111,w_dot_onoff}),
        .digit_off_1000(4'he),
        .bcd_data(w_bcd_data_min_hour)
    );
    /*mux_4x1 U_Mux_4x1_sec_msec(
        .sel(w_digit_sel),
        .digit_1(w_digit_msec_1),
        .digit_10(w_digit_msec_10),
        .digit_100(w_digit_sec_1),
        .digit_1000(w_digit_sec_10),
        .bcd_data(w_bcd_data_msec_sec)
    );

    mux_4x1 U_Mux_4x1_min_hour(
        .sel(w_digit_sel),
        .digit_1(w_digit_min_1),
        .digit_10(w_digit_min_10),
        .digit_100(w_digit_hour_1),
        .digit_1000(w_digit_hour_10),
        .bcd_data(w_bcd_data_min_hour)
    );*/

    bcd_decoder U_BCD(
        .bcd(w_bcd_data),
        .fnd_data(fnd_data)
    );

endmodule

module dot_comp(
    input [6:0] msec,
    output dot_onoff
);
    assign dot_onoff = (msec >= 50) ? 1'b1: 1'b0;
endmodule

module clk_div(
  input clk,
  input reset,
  output reg o_1khz
);
    reg [16:0] r_counter;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_counter <= 0;
            o_1khz <= 1'b0;
        end else begin
            if(r_counter == 100_000 - 1)begin
                r_counter <= 0;
                o_1khz <= 1'b1;
            end else begin
                r_counter = r_counter + 1;
                o_1khz <= 1'b0;
            end
           
        end
    end
endmodule

module counter_8(
    input clk,
    input reset,
    output [2:0] digit_sel
);
    reg [2:0] r_counter;

    assign digit_sel = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            // operation
            r_counter <= r_counter + 1;
        end
    end
endmodule

module mux_8x1(
    input [2:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [3:0] digit_off_1,
    input [3:0] digit_off_10,
    input [3:0] digit_dot,
    input [3:0] digit_off_1000,
    output reg [3:0] bcd_data
);
    always @(*) begin
        case (sel)
            3'b000: bcd_data = digit_1;
            3'b001: bcd_data = digit_10;
            3'b010: bcd_data = digit_100;
            3'b011: bcd_data = digit_1000;
            3'b100: bcd_data = digit_off_1;
            3'b101: bcd_data = digit_off_10;
            3'b110: bcd_data = digit_dot;
            3'b111: bcd_data = digit_off_1000;
            default: bcd_data = digit_1;
        endcase
    end
endmodule

module mux_2x1_4bit(
    input sel,
    input [3:0] x0,
    input [3:0] x1,
    output reg [3:0] bcd_data
);
    always @(*) begin
        case(sel)
            1'b0 : bcd_data = x0;
            1'b1 : bcd_data = x1;
            default: bcd_data = x0;
        endcase
    end
endmodule

module decoder_2x4(
    input [1:0] sel,
    output reg [3:0] fnd_com
);
    always @(*) begin
        case (sel)
            2'b00 : fnd_com = 4'b1110;
            2'b01 : fnd_com = 4'b1101;
            2'b10 : fnd_com = 4'b1011;
            2'b11 : fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end
endmodule

/*module mux_4x1(
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] bcd_data
);
    always @(*) begin
        case(sel)
            2'b00 : bcd_data = digit_1;
            2'b01 : bcd_data = digit_10;
            2'b10 : bcd_data = digit_100;
            2'b11 : bcd_data = digit_1000;
            default: bcd_data = digit_1;
        endcase
    end
endmodule*/

module bcd_decoder(
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);
    always@(bcd) begin
        case(bcd)
            0: fnd_data = 8'hc0;
            1: fnd_data = 8'hf9;
            2: fnd_data = 8'ha4;
            3: fnd_data = 8'hb0;
            4: fnd_data = 8'h99;
            5: fnd_data = 8'h92;
            6: fnd_data = 8'h82;
            7: fnd_data = 8'hf8;
            8: fnd_data = 8'h80;
            9: fnd_data = 8'h90;
            14: fnd_data = 8'hff;
            15: fnd_data = 8'h7f;
            default: fnd_data = 8'hff;
        endcase
    end
endmodule

module digit_spliter #(parameter DS_WIDTH = 7)(
    input [DS_WIDTH-1:0] i_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);
    assign digit_1 = i_data % 10;
    assign digit_10 = i_data/10 % 10;
endmodule
