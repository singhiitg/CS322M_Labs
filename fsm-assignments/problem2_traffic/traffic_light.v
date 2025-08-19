`timescale 1ns / 1ps


// traffic_light.sv
module traffic_light (
    input  logic clk,       // system clock
    input  logic reset,     // synchronous, active-high
    input  logic tick_1hz,  // 1 Hz tick pulse
    output logic ns_g, ns_y, ns_r,
    output logic ew_g, ew_y, ew_r
);

    // FSM States
    typedef enum logic [1:0] {NS_G, NS_Y, EW_G, EW_Y} state_t;
    state_t state, next_state;

    logic [2:0] tick_count; // counts ticks within a state

    // Sequential block: state + tick_count
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= NS_G;
            tick_count <= 0;
        end else if (tick_1hz) begin
            if ((state == NS_G && tick_count == 4) ||
                (state == NS_Y && tick_count == 1) ||
                (state == EW_G && tick_count == 4) ||
                (state == EW_Y && tick_count == 1)) begin
                state <= next_state;
                tick_count <= 0;
            end else begin
                tick_count <= tick_count + 1;
            end
        end
    end

    // Next state logic
    always_comb begin
        case (state)
            NS_G: next_state = NS_Y;
            NS_Y: next_state = EW_G;
            EW_G: next_state = EW_Y;
            EW_Y: next_state = NS_G;
            default: next_state = NS_G;
        endcase
    end

    // Output logic (Moore)
    always_comb begin
        ns_g = 0; ns_y = 0; ns_r = 0;
        ew_g = 0; ew_y = 0; ew_r = 0;

        case (state)
            NS_G: begin ns_g = 1; ew_r = 1; end
            NS_Y: begin ns_y = 1; ew_r = 1; end
            EW_G: begin ew_g = 1; ns_r = 1; end
            EW_Y: begin ew_y = 1; ns_r = 1; end
        endcase
    end

endmodule

