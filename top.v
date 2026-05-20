`timescale 1ns / 1ps

module sys_top #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4,
    parameter C_M_AXI_DATA_WIDTH = 32,
    parameter MEM_SIZE           = 1024,
    parameter C_M_AXI_ADDR_WIDTH = $clog2(MEM_SIZE)
)(
    input  wire                              clk,
    input  wire                              resetn,

    // =========================================================
    // AXI4-Lite Slave Interface (CPU Control & Status)
    // =========================================================
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                              s_axi_awvalid,
    output wire                              s_axi_awready,
    
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                              s_axi_wvalid,
    output wire                              s_axi_wready,
    
    output wire [1:0]                        s_axi_bresp,
    output wire                              s_axi_bvalid,
    input  wire                              s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                              s_axi_arvalid,
    output wire                              s_axi_arready,
    
    output wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output wire [1:0]                        s_axi_rresp,
    output wire                              s_axi_rvalid,
    input  wire                              s_axi_rready,

    // =========================================================
    // Auxiliary IP Inputs (Key & Config)
    // =========================================================
    input  wire [127:0]                      aes_key,
    input  wire                              aes_key_valid,
    input  wire [6:0]                        num_blocks_to_process,
    
    output wire                              aes_key_ready
);

    // =========================================================
    // Internal AXI Interconnect Signals (AES Master <-> Slave Mem)
    // =========================================================
    wire [C_M_AXI_ADDR_WIDTH-1:0]     m_axi_awaddr;
    wire                              m_axi_awvalid;
    wire                              m_axi_awready;
    
    wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_wdata;
    wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb;
    wire                              m_axi_wvalid;
    wire                              m_axi_wready;
    
    wire                              m_axi_bresp; // Slave mem outputs 1-bit resp
    wire                              m_axi_bvalid;
    wire                              m_axi_bready;
    
    wire [C_M_AXI_ADDR_WIDTH-1:0]     m_axi_araddr;
    wire                              m_axi_arvalid;
    wire                              m_axi_arready;
    
    wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_rdata;
    wire                              m_axi_rresp; // Slave mem outputs 1-bit resp
    wire                              m_axi_rvalid;
    wire                              m_axi_rready;

    // =========================================================
    // AES Core Instantiation (Master)
    // =========================================================
    aes_top #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
        .MEM_SIZE(MEM_SIZE),
        .C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH)
    ) aes_inst (
        .aclk                  (clk),
        .aresetn               (resetn),

        // CPU Control Interface
        .s_axi_awaddr          (s_axi_awaddr),
        .s_axi_awvalid         (s_axi_awvalid),
        .s_axi_awready         (s_axi_awready),
        .s_axi_wdata           (s_axi_wdata),
        .s_axi_wstrb           (s_axi_wstrb),
        .s_axi_wvalid          (s_axi_wvalid),
        .s_axi_wready          (s_axi_wready),
        .s_axi_bresp           (s_axi_bresp),
        .s_axi_bvalid          (s_axi_bvalid),
        .s_axi_bready          (s_axi_bready),
        .s_axi_araddr          (s_axi_araddr),
        .s_axi_arvalid         (s_axi_arvalid),
        .s_axi_arready         (s_axi_arready),
        .s_axi_rdata           (s_axi_rdata),
        .s_axi_rresp           (s_axi_rresp),
        .s_axi_rvalid          (s_axi_rvalid),
        .s_axi_rready          (s_axi_rready),

        // Memory Interface (Connected to Slave Mem)
        .m_axi_araddr          (m_axi_araddr),
        .m_axi_arvalid         (m_axi_arvalid),
        .m_axi_arready         (m_axi_arready),
        .m_axi_rdata           (m_axi_rdata),
        // Map 1-bit slave response to 2-bit standard (SLVERR = 10)
        .m_axi_rresp           ({m_axi_rresp, 1'b0}), 
        .m_axi_rvalid          (m_axi_rvalid),
        .m_axi_rready          (m_axi_rready),
        
        .m_axi_awaddr          (m_axi_awaddr),
        .m_axi_awvalid         (m_axi_awvalid),
        .m_axi_awready         (m_axi_awready),
        .m_axi_wdata           (m_axi_wdata),
        .m_axi_wstrb           (m_axi_wstrb),
        .m_axi_wvalid          (m_axi_wvalid),
        .m_axi_wready          (m_axi_wready),
        // Map 1-bit slave response to 2-bit standard (SLVERR = 10)
        .m_axi_bresp           ({m_axi_bresp, 1'b0}), 
        .m_axi_bvalid          (m_axi_bvalid),
        .m_axi_bready          (m_axi_bready),

        // Aux Config
        .aes_key               (aes_key),
        .aes_key_valid         (aes_key_valid),
        .num_blocks_to_process (num_blocks_to_process),
        .aes_key_ready         (aes_key_ready)
    );

    // =========================================================
    // Memory Instantiation (Slave)
    // =========================================================
    slave_mem #(
        .AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
        .MEM_SIZE(MEM_SIZE),
        .AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH)
    ) mem_inst (
        .clk           (clk),
        .reset         (resetn),

        // Read Channel
        .ar_addr       (m_axi_araddr),
        .ar_valid      (m_axi_arvalid),
        .ar_ready      (m_axi_arready),
        
        .r_data        (m_axi_rdata),
        .r_valid       (m_axi_rvalid),
        .r_ready       (m_axi_rready),
        .r_resp        (m_axi_rresp), // 1-bit response

        // Write Channel
        .aw_addr       (m_axi_awaddr),
        .aw_valid      (m_axi_awvalid),
        .aw_ready      (m_axi_awready),
        
        .w_data        (m_axi_wdata),
        .w_valid       (m_axi_wvalid),
        .w_ready       (m_axi_wready),
        .w_strb        (m_axi_wstrb),
        
        .b_resp        (m_axi_bresp), // 1-bit response
        .b_resp_ready  (m_axi_bready),
        .b_resp_valid  (m_axi_bvalid)
    );

endmodule