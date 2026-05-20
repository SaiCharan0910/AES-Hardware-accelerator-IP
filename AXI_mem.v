module slave_mem #(
    parameter AXI_DATA_WIDTH = 32,
    parameter MEM_SIZE = 1024,
    parameter AXI_ADDR_WIDTH = 10
)
(
    input clk,
    input reset,

    input [AXI_ADDR_WIDTH-1:0] ar_addr,
    input ar_valid,
    output ar_ready,

    output reg [AXI_DATA_WIDTH-1:0]r_data,
    output reg r_valid,
    input r_ready,
    output reg r_resp,

    input [AXI_ADDR_WIDTH-1:0]aw_addr,
    input aw_valid,
    output aw_ready,

    input [AXI_DATA_WIDTH-1:0]w_data,
    input  w_valid,
    output w_ready,
    input wire [AXI_DATA_WIDTH/8 -1:0]w_strb,

    output reg b_resp,
    input b_resp_ready,
    output reg b_resp_valid
);
    parameter OKAY =1'b0,
              SLVERR =1'b1;
  
    reg [7:0] mem [MEM_SIZE-1:0];

    // read adress handshake
    reg ar_hs_done;
    assign ar_ready = (!r_valid)||(r_ready); // adress and data handshake overlap for latency match
    always@(posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            ar_hs_done <= 0;
            r_valid <= 0;
            r_data <= 0;
            r_resp <= OKAY;
        end
        else
        begin
            if(ar_ready && ar_valid)
            begin
                r_valid <= 1'b1;
                if(ar_addr < MEM_SIZE -3)
                begin
                    r_data <= {mem[ar_addr],mem[ar_addr+1],mem[ar_addr+2],mem[ar_addr+3]}; //r_valid is driven high only after AR transaction according to AXI rule #1
                    r_resp <= OKAY;
                end
                else
                begin
                    r_resp <= SLVERR;
                    r_data <= 32'hDEADBEEF;
                end
            end
            else if (r_valid && r_ready)
            begin
                r_valid <= 1'b0; // the read transaction has been completed.
            end
        end
    end

    // write handshake
    reg aw_hs_done , w_hs_done;
    reg [AXI_ADDR_WIDTH-1:0]aw_addr_q;
    reg [AXI_DATA_WIDTH-1:0]w_data_q;
    reg [AXI_DATA_WIDTH/8 -1:0]w_strb_q;
    integer i;
    assign aw_ready = (!aw_hs_done)||(b_resp_valid && b_resp_ready);
    assign w_ready = (!w_hs_done)||(b_resp_valid && b_resp_ready);


    always@(posedge clk or negedge reset)
    begin
        if(!reset)
        begin
            aw_hs_done <= 1'b0;
            w_hs_done <= 1'b0;
            b_resp_valid <= 1'b0;
            b_resp <= OKAY;
        end
        else
        begin
            if(aw_ready && aw_valid && w_ready && w_valid)
            begin
                aw_hs_done <= 1'b1;
                w_hs_done <= 1'b1;
                b_resp_valid <=1'b1;
                if(aw_addr < MEM_SIZE -3)
                begin
                    b_resp <= OKAY;
                    for(i=0;i<(AXI_DATA_WIDTH/8);i=i+1)
                    begin
                        if(w_strb[i])// in our case the all bits of w_strb are high so all the 32 bit data would be replaced
                        begin
                            mem[aw_addr+i] <= w_data[(31-i*8)-:8];
                        end
                    end
                end
                else
                begin
                    b_resp <= SLVERR;
                end
            end
            else if (aw_ready && aw_valid)
            begin
                if(w_hs_done)
                begin
                    aw_hs_done <= 1'b1;
                    b_resp_valid <= 1'b1;// asserted as soon as both write adress and data handshake has happened
                    if(aw_addr < MEM_SIZE -3)
                    begin
                        b_resp <= OKAY;
                        for(i=0;i<(AXI_DATA_WIDTH/8);i=i+1)
                        begin
                            if(w_strb_q[i])// in our case the all bits of w_strb are high so all the 32 bit data would be replaced
                            begin
                                mem[aw_addr+i] <= w_data_q[(32-i*8) -:8]; // the stored w_data would come in use here
                            end
                        end
                    end
                    else
                    begin
                        b_resp <= SLVERR;
                    end
                end
                else
                begin
                    aw_addr_q <= aw_addr;
                    aw_hs_done <= 1'b1;
                end
            end
            else if (w_ready && w_valid)
            begin
                if(aw_hs_done)
                begin
                    w_hs_done <= 1'b1;
                    b_resp_valid <=1'b1;
                    if(aw_addr_q < MEM_SIZE -3)
                    begin
                        b_resp <= OKAY;
                        for(i=0;i<(AXI_DATA_WIDTH/8);i=i+1)
                        begin
                            if(w_strb[i])// in our case the all bits of w_strb are high so all the 32 bit data would be replaced
                            begin
                                mem[aw_addr_q+i] <= w_data[(32-i*8) -:8]; // the stored aw_addr would come in use here
                            end
                        end
                    end
                    else
                    begin
                        b_resp <= SLVERR;
                    end
                end
                else
                begin
                    w_data_q <= w_data;
                    w_strb_q <= w_strb;
                    w_hs_done <= 1'b1;
                end
            end
            else if(b_resp_ready && b_resp_valid)
            begin
                w_hs_done <=1'b0;
                aw_hs_done <= 1'b0;
                b_resp_valid <= 1'b0;
            end
        end
    end
endmodule