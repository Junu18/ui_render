// flag_renderer.sv
// 깃발 렌더러 (고정 위치)

import color_pkg::*;

module flag_renderer #(
    parameter int FLAG_X          = 620,
    parameter int FLAG_TOP_Y      = 40,
    parameter int FLAG_HEIGHT     = 120,
    parameter int FLAG_POLE_WIDTH = 3,
    parameter int FLAG_WIDTH      = 20,
    parameter int FLAG_CLOTH_H    = 14
) (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);

    logic pole_region;
    logic cloth_region;
    logic finial_region;

    assign pole_region   = (x >= FLAG_X) && (x < FLAG_X + FLAG_POLE_WIDTH) &&
                           (y >= FLAG_TOP_Y) && (y < FLAG_TOP_Y + FLAG_HEIGHT);
    assign cloth_region  = (x >= FLAG_X) && (x < FLAG_X + FLAG_WIDTH) &&
                           (y >= FLAG_TOP_Y) && (y < FLAG_TOP_Y + FLAG_CLOTH_H);
    assign finial_region = (x >= FLAG_X - 1) && (x < FLAG_X + FLAG_POLE_WIDTH + 1) &&
                           (y >= FLAG_TOP_Y - 2) && (y < FLAG_TOP_Y + 1);

    always_comb begin
        enable = 1'b0;
        color  = BLACK;

        if (finial_region) begin
            enable = 1'b1;
            color  = FLAG_GOLD;
        end else if (pole_region) begin
            enable = 1'b1;
            color  = IC_SILVER;
        end else if (cloth_region) begin
            enable = 1'b1;
            color  = FLAG_GREEN;
        end
    end
endmodule
