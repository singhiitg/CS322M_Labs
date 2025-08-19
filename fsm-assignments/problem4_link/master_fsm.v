module master (
    input  logic        clk,
    input  logic        rst,
    input  logic        ack,
    output logic        req,
    output logic [7:0]  data,
    output logic        done
);

    typedef enum logic [2:0] {IDLE, SEND, WAIT_ACK, DROP_REQ, DONE} state_t;
    state_t state, next;

    logic [1:0] byte_cnt;
    logic [7:0] data_array [0:3];

    initial begin
        data_array[0] = 8'hA1;
        data_array[1] = 8'hB2;
        data_array[2] = 8'hC3;
        data_array[3] = 8'hD4;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            byte_cnt <= 0;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        req  = 0;
        done = 0;
        data = 8'h00;
        next = state;

        case (state)
            IDLE: next = SEND;

            SEND: begin
                data = data_array[byte_cnt];
                req  = 1;
                next = WAIT_ACK;
            end

            WAIT_ACK: begin
                data = data_array[byte_cnt];
                req  = 1;
                if (ack) next = DROP_REQ;
            end

            DROP_REQ: begin
                if (!ack) begin
                    if (byte_cnt == 2'd3) next = DONE;
                    else next = SEND;
                end
            end

            DONE: begin
                done = 1;
                next = DONE;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst && state == DROP_REQ && !ack)
            byte_cnt <= byte_cnt + 1;
    end

endmodule
