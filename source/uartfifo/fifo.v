`timescale 1ns / 1ps

module fifo(
    input        clk,
    input        rst,
    input  [7:0] w_data,
    input        push,
    input        pop,
    output       full,
    output       empty,
    output [7:0] r_data
);

    wire [1:0] w_addr, r_addr;

    register_file U_Register_File(
        .clk(clk),
        .w_data(w_data),
        .w_addr(w_addr),
        .r_addr(r_addr),
        .wr_en(~full & push),
        .rd_en(~empty & pop),
        .r_data(r_data)
    );

    fifo_control_unit U_FIFO_CU(
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .r_addr(r_addr),
        .w_addr(w_addr),
        .full(full),
        .empty(empty)
    );

endmodule

module register_file (
    input        clk,
    input [7:0]  w_data,
    input [1:0]  w_addr,
    input [1:0]  r_addr,
    input        wr_en,
    input        rd_en,
    output [7:0] r_data
);

    reg [7:0] mem[0:3];

    //reg [7:0] rdata_reg;
    //assign rdata = rdata_reg;

    //assign r_data = mem[r_addr];

    always @(posedge clk) begin
        if (wr_en) begin
            // write to mem
            mem[w_addr] <= w_data;
        end /*else begin
            rdata_reg <= mem[r_addr];
        end*/ 
    end

    assign r_data = (rd_en) ? mem[r_addr]: 8'hz;
    
endmodule

module fifo_control_unit (
    input        clk,
    input        rst,
    input        push,
    input        pop,
    output [1:0] r_addr,
    output [1:0] w_addr,
    output       full,
    output       empty
);
    
    reg [1:0] wptr_reg, wptr_next;
    reg [1:0] rptr_reg, rptr_next;
    reg       full_reg, full_next;
    reg       empty_reg, empty_next;

    assign w_addr = wptr_reg;
    assign r_addr = rptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    // fsm 이긴한데 따로 state 만들지 않음
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({push,pop})
            2'b01: begin
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (wptr_reg == rptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin
                if (empty_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 1'b0;
                end else if (full_reg) begin
                    rptr_next = rptr_reg  + 1;
                    full_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

endmodule