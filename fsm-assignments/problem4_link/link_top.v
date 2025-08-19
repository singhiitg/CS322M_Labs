module top;
    logic clk, rst;
    logic req, ack, done;
    logic [7:0] data;

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
    always #5 clk = ~clk; // 100MHz clock

    // Reset generation
    initial begin
        rst = 1;
        #20 rst = 0;
    end
endmodule
