module display_mux (
    input  logic clk,
    input  logic rst_n,
    input  logic [3:0] d3, d2, d1, d0,   // Dígitos BCD
    output logic [6:0] seven,            // Segmentos a–g
    output logic [3:0] anodo             // Control de displays
);

    parameter integer REFRESH_RATE = 27000; 

    logic [15:0] refresh_cnt;
    logic [1:0]  digit_sel;
    logic [3:0]  current_digit;
    logic [6:0]  seg_pattern;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt <= 0;
            digit_sel <= 0;
        end else if (refresh_cnt >= REFRESH_RATE) begin
            refresh_cnt <= 0;
            digit_sel <= digit_sel + 1;
        end else
            refresh_cnt <= refresh_cnt + 1;
    end

    always_comb begin
        case (digit_sel)
            2'd0: begin anodo = 4'b1110; current_digit = d0; end
            2'd1: begin anodo = 4'b1101; current_digit = d1; end
            2'd2: begin anodo = 4'b1011; current_digit = d2; end
            2'd3: begin anodo = 4'b0111; current_digit = d3; end
        endcase
    end

    always_comb begin
        case (current_digit)
            4'h0: seg_pattern = 7'b0000001;
            4'h1: seg_pattern = 7'b1001111;
            4'h2: seg_pattern = 7'b0010010;
            4'h3: seg_pattern = 7'b0000110;
            4'h4: seg_pattern = 7'b1001100;
            4'h5: seg_pattern = 7'b0100100;
            4'h6: seg_pattern = 7'b0100000;
            4'h7: seg_pattern = 7'b0001111;
            4'h8: seg_pattern = 7'b0000000;
            4'h9: seg_pattern = 7'b0000100;
            4'hA: seg_pattern = 7'b0001000;
            4'hB: seg_pattern = 7'b1100000;
            4'hC: seg_pattern = 7'b0110001;
            4'hD: seg_pattern = 7'b1000010;
            4'hE: seg_pattern = 7'b0110000;
            4'hF: seg_pattern = 7'b0111000;
            default: seg_pattern = 7'b1111111;
        endcase
    end

    assign seven = seg_pattern;

endmodule
