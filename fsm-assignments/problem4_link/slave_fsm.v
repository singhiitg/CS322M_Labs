module slave (
    input  logic        clk,
    input  logic        rst,
    input  logic        req,
    input  logic [7:0]  data,
    output logic        ack
);

    typedef enum logic [1:0] {IDLE, ASSERT_ACK1, ASSERT_ACK2, WAIT_DROP} state_t;
    state_t state, next;

    logic [1:0] byte_cnt;
    logic [7:0] received_data [0:3];

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            byte_cnt <= 0;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        ack  = 0;
        next = state;

        case (state)
            IDLE:
                if (req) next = ASSERT_ACK1;

            ASSERT_ACK1: begin
                ack = 1;
                next = ASSERT_ACK2;
            end

            ASSERT_ACK2: begin
                ack = 1;
                next = WAIT_DROP;
            end

            WAIT_DROP:
                if (!req) next = IDLE;
                else ack = 1;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst && state == ASSERT_ACK1) begin
            received_data[byte_cnt] <= data;
            byte_cnt <= byte_cnt + 1;
        end
    end

endmodule
