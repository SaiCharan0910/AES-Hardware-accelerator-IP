`timescale 1ns / 1ps

module axi_ctrl_reg #(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 4 
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]                s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,

    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,

    output wire                      start_sig,
    output wire                      stop_sig
);

    reg [31:0] control_reg;

    assign start_sig = control_reg[0];
    assign stop_sig  = control_reg[1];


    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00; 
            control_reg   <= 32'h0;
        end else begin
            if (s_axi_awvalid && s_axi_wvalid && !s_axi_awready && !s_axi_wready) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                if (s_axi_wstrb[0]) control_reg[7:0]   <= s_axi_wdata[7:0];
                if (s_axi_wstrb[1]) control_reg[15:8]  <= s_axi_wdata[15:8];
                if (s_axi_wstrb[2]) control_reg[23:16] <= s_axi_wdata[23:16];
                if (s_axi_wstrb[3]) control_reg[31:24] <= s_axi_wdata[31:24];
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end
            if (s_axi_awready && s_axi_wready) begin
                s_axi_bvalid <= 1'b1;
                if(s_axi_awaddr == 4'h0)
                s_axi_bresp  <= 2'b00;
                else
                s_axi_bresp <= 2'b01;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
endmodule