`timescale 1ns/1ps

module tb;
    logic clk, rst;
    logic req, ack, done;
    logic [7:0] data;

    // Instantiate DUT
    master u_master (
        .clk(clk),
        .rst(rst),
        .ack(ack),
        .req(req),
        .data(data),
        .done(done)
    );

    slave u_slave (
        .clk(clk),
        .rst(rst),
        .req(req),
        .data(data),
        .ack(ack)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset and test control
    initial begin
        $dumpfile("handshake.vcd");
        $dumpvars(0, tb);
        
        rst = 1;
        #20 rst = 0;

        // Wait for done
        wait(done);
        #10;

        $display("Simulation finished.");
        $finish;
    end
endmodule
