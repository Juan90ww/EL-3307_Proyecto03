module modulo_3 #(
    parameter IN_WIDTH = 11,
    parameter DIGITS = 4
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   start,
    input  logic [IN_WIDTH-1:0]    bin_in,
    output logic [3:0]             bcd3, bcd2, bcd1, bcd0,
    output logic                   done
);

    logic [IN_WIDTH-1:0] bin_val;
    logic [3:0] thousands, hundreds, tens, ones;
    logic processing;
    int i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_val <= '0;
            {thousands, hundreds, tens, ones} <= '0;
            processing <= 1'b0;
            done <= 1'b0;
        end else begin
            if (start && !processing) begin
                bin_val <= bin_in;
                thousands <= 4'd0;
                hundreds <= 4'd0;
                tens <= 4'd0;
                ones <= 4'd0;
                processing <= 1'b1;
                done <= 1'b0;
            end else if (processing) begin
                // Algoritmo de división sucesiva (más robusto)
                if (bin_val >= 1000) begin
                    thousands <= thousands + 1;
                    bin_val <= bin_val - 1000;
                end else if (bin_val >= 100) begin
                    hundreds <= hundreds + 1;
                    bin_val <= bin_val - 100;
                end else if (bin_val >= 10) begin
                    tens <= tens + 1;
                    bin_val <= bin_val - 10;
                end else begin
                    ones <= bin_val[3:0];
                    processing <= 1'b0;
                    done <= 1'b1;
                end
            end else begin
                done <= 1'b0;
            end
        end
    end

    assign bcd3 = thousands;
    assign bcd2 = hundreds;
    assign bcd1 = tens;
    assign bcd0 = ones;

endmodule

