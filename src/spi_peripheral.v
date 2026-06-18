module spi_peripheral (
    input  wire       clk,
    input  wire       nrst,
    input  wire       SCLK,
    input  wire       COPI,
    input  wire       nCS,
    output reg  [7:0] en_reg_out_7_0,
    output reg  [7:0] en_reg_out_15_8,
    output reg  [7:0] en_reg_pwm_7_0,
    output reg  [7:0] en_reg_pwm_15_8,
    output reg  [7:0] pwm_duty_cycle
);

reg COPI_sync1;
reg COPI_sync2;
reg SCLK_sync1;
reg SCLK_sync2;
reg nCS_sync1;
reg nCS_sync2;


always @(posedge clk or negedge nrst) begin

     if (!nrst) begin
        COPI_sync1 <= 1'b0;
        COPI_sync2 <= 1'b0;
        SCLK_sync1 <= 1'b0;
        SCLK_sync2 <= 1'b0;
        nCS_sync1  <= 1'b1; 
        nCS_sync2  <= 1'b1;
    end else begin
        COPI_sync1 <= COPI;
        SCLK_sync1 <= SCLK;
        nCS_sync1 <= nCS;

        COPI_sync2 <= COPI_sync1;
        SCLK_sync2 <= SCLK_sync1;   
        nCS_sync2 <= nCS_sync1;
    end
end

reg SCLK_prev;
reg nCS_prev;

always @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        SCLK_prev <= 1'b0;
        nCS_prev  <= 1'b1; 
    end else begin
        SCLK_prev <= SCLK_sync2;
        nCS_prev  <= nCS_sync2;
    end
end

wire sclk_rising_edge = SCLK_sync2 & ~SCLK_prev;
wire sclk_falling_edge = ~SCLK_sync2 & SCLK_prev;
wire nCS_rising_edge = nCS_sync2 & ~nCS_prev;
wire nCS_falling_edge = ~nCS_sync2 & nCS_prev;
reg [4:0] bit_count;
reg [15:0] shift_register;

always @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        bit_count <=5'b0;
        shift_register <=16'b0;
    end else if (nCS_falling_edge) begin
        bit_count <= 5'b0;
    end else if (sclk_rising_edge && !nCS_sync2) begin
        bit_count <= bit_count + 1;
        shift_register <= {shift_register[14:0], COPI_sync2};
    end
end

localparam max_address = 7'h4;

always @(posedge clk or negedge nrst) begin 
    if (!nrst) begin
        en_reg_out_7_0 <= 8'b0;
        en_reg_out_15_8 <= 8'b0;
        en_reg_pwm_7_0 <=8'b0;
        en_reg_pwm_15_8 <=8'b0;
        pwm_duty_cycle <=8'b0;
    end else if (bit_count == 5'd16 && nCS_rising_edge && shift_register[15] == 1 && shift_register[14:8] <= max_address) begin
        case(shift_register[14:8]) 
            7'h00: en_reg_out_7_0  <= shift_register[7:0];
            7'h01: en_reg_out_15_8 <= shift_register[7:0];
            7'h02: en_reg_pwm_7_0  <= shift_register[7:0];
            7'h03: en_reg_pwm_15_8 <= shift_register[7:0];
            7'h04: pwm_duty_cycle  <= shift_register[7:0]; 
            default :;
        endcase
    end
end

endmodule




