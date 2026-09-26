// Subordinate interface (DMA acts as subordinate)
module axi_lite_regs #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (

    input logic clk,
    input logic aresetn,

    input  logic [ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic                  s_axi_arvalid,
    output logic                  s_axi_arready,

    input  logic [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic                  s_axi_awvalid,
    output logic                  s_axi_awready,

    output logic [DATA_WIDTH-1:0] s_axi_rdata,
    output logic [           1:0] s_axi_rresp,
    output logic                  s_axi_rvalid,
    input  logic                  s_axi_rready,

    input  logic [DATA_WIDTH-1:0]       s_axi_wdata,
    input  logic [(DATA_WIDTH/8) - 1:0] s_axi_wstrb,
    input  logic                          s_axi_wvalid,
    output logic                          s_axi_wready,

    output logic [1:0] s_axi_bresp,
    input  logic       s_axi_bready,
    output logic       s_axi_bvalid





);

  localparam logic [4:0] REG_DMA_CTRL   = 5'h00;  // Byte offset 0x00
  localparam logic [4:0] REG_DMA_STATUS = 5'h04;
  localparam logic [4:0] REG_SRC_ADDR = 5'h08;
  localparam logic [4:0] REG_DST_ADDR = 5'h0C;
  localparam logic [4:0] REG_LENGTH = 5'h10;


  logic [DATA_WIDTH-1:0] control_reg;
  logic [DATA_WIDTH-1:0] status_reg;
  logic [ADDR_WIDTH-1:0] src_addr_reg;
  logic [ADDR_WIDTH-1:0] dst_addr_reg;
  logic [DATA_WIDTH-1:0] length_reg;

  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic                  awaddr_received;

  always_ff @(posedge clk) begin
    if (!aresetn) begin
      awaddr_reg <= '0;
      awaddr_received <= 1'b0;
    end
    else begin
      if (s_axi_awvalid && s_axi_awready) begin
        awaddr_reg <= s_axi_awaddr;
        awaddr_received <= 1'b1;
      end

    end

  end

  assign s_axi_awready = !awaddr_received;
  assign s_axi_wready = 1'b0;

  logic [DATA_WIDTH-1:0]     wdata_reg;
  logic [(DATA_WIDTH/8)-1:0] wstrb_reg;
  logic                      wdata_received;




endmodule
