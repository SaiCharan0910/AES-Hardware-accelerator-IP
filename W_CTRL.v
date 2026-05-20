module write_control #(
    parameter MEM_SIZE = 1024,
    parameter ADDR_WIDTH = $clog2(MEM_SIZE), 
    parameter AXI_DATA_WIDTH = 32
)
(
    input clk,
    input reset,

    input [127:0] AES_out,
    input [ADDR_WIDTH-1:0] AES_addr_out,
    input done,

    output [ADDR_WIDTH-1:0] aw_addr,
    output aw_valid,
    input aw_ready,

    output [AXI_DATA_WIDTH-1:0] w_data,
    output w_valid,
    input w_ready,
    output [AXI_DATA_WIDTH/8 -1:0] w_strb,

    input b_resp,
    output b_resp_ready,
    input b_resp_valid,
    input [6:0]num_blocks_to_process,

    output empty,
    output reg done_all
);

    localparam IDLE  = 1'b0;
    localparam WRITE = 1'b1;

    reg state;
    reg [2:0] addr_count;
    reg [2:0] w_count;
    reg [2:0] b_count;
    reg [ADDR_WIDTH-1:0] aw_addr_reg;
    reg [31:0] w_data_q[3:0];

    assign w_strb = 4'b1111;
    assign b_resp_ready = 1'b1;
    
    wire burst_crossover = (state == WRITE) && (b_count == 3) && b_resp_valid && done;

    assign empty = (state == IDLE) || burst_crossover;

    assign aw_valid = (state == WRITE) && ((addr_count <4) || burst_crossover);
    assign w_valid  = (state == WRITE) && ((w_count <4)    || burst_crossover);
    
    assign aw_addr = burst_crossover ? AES_addr_out : aw_addr_reg;
    assign w_data  = burst_crossover ? AES_out[127:96] : w_data_q[w_count[1:0]];

    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            state       <= IDLE;
            w_count     <= 0;
            b_count     <= 0;
            addr_count  <= 0;
            aw_addr_reg <= 0;
            w_data_q[0] <= 0; w_data_q[1] <= 0; w_data_q[2] <= 0; w_data_q[3] <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(done) begin
                        state        <= WRITE;
                        w_data_q[0]  <= AES_out[127:96];
                        w_data_q[1]  <= AES_out[95:64];
                        w_data_q[2]  <= AES_out[63:32];
                        w_data_q[3]  <= AES_out[31:0];
                        
                        aw_addr_reg  <= AES_addr_out;
                        w_count      <= 0;
                        b_count      <= 0;
                        addr_count   <= 0;
                    end
                end
                
                WRITE: begin
                    if(aw_valid && aw_ready) begin
                        aw_addr_reg <= aw_addr_reg + 4;
                        addr_count  <= addr_count + 1;
                    end
                    
                    if(w_valid && w_ready) begin
                        w_count <= w_count + 1;
                    end
                    
                    if(b_resp_ready && b_resp_valid) begin
                        if(b_count == 3) begin
                            if(done) begin
                                state <= WRITE;
                                
                                w_data_q[0] <= AES_out[127:96];
                                w_data_q[1] <= AES_out[95:64];
                                w_data_q[2] <= AES_out[63:32];
                                w_data_q[3] <= AES_out[31:0];
                                
                                aw_addr_reg <=(aw_ready&& aw_valid)?AES_addr_out+4:AES_addr_out; 
                                addr_count  <= (aw_ready&& aw_valid)?1:0; 
                                w_count     <= (w_ready && w_valid)?1:0; 
                                
                                b_count     <= 0; 
                            end else begin
                                state      <= IDLE;
                                addr_count <= 0;
                                b_count    <= 0;
                                w_count    <= 0;
                            end
                        end else begin
                            b_count <= b_count + 1;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

reg [6:0] block_counter;

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        block_counter <= 7'd0;
        done_all      <= 1'b0;
    end else begin
        if (state == IDLE) begin
            block_counter <= 7'd0;
            done_all      <= 1'b0;
        end 
        else if (b_count == 3) begin
            if (block_counter == (num_blocks_to_process - 1)) begin
                done_all      <= 1'b1;
                block_counter <= 7'd0;
            end else begin
                block_counter <= block_counter + 1;
                done_all      <= 1'b0;
            end
        end
    end
end





endmodule