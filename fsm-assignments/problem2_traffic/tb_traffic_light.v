`timescale 1ns / 1ps
// tb_traffic_light.sv
module tb_traffic_light;
    logic clk;
    logic reset;
    logic tick_1hz;
    logic ns_g, ns_y, ns_r, ew_g, ew_y, ew_r;

    // DUT
    traffic_light dut(
        .clk(clk), .reset(reset), .tick_1hz(tick_1hz),
        .ns_g(ns_g), .ns_y(ns_y), .ns_r(ns_r),
        .ew_g(ew_g), .ew_y(ew_y), .ew_r(ew_r)
    );

    // Clock generation (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Generate 1Hz tick (every 10 cycles of clk for simulation)
    integer cnt;
    always_ff @(posedge clk) begin
        if (reset) begin
            cnt <= 0;
            tick_1hz <= 0;
        end else begin
            if (cnt == 9) begin
                tick_1hz <= 1;
                cnt <= 0;
            end else begin
                tick_1hz <= 0;
                cnt <= cnt + 1;
            end
        end
    end

    // Simulation
    initial begin
        $dumpfile("traffic_light.vcd");
        $dumpvars(0, tb_traffic_light);

        reset = 1;
        #20 reset = 0;

        // Run long enough to cycle multiple times
        #10000 $finish;
    end

endmodule

