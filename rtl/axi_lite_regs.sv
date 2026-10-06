// Subordinate interface (DMA acts as subordinate)
module axi_lite_regs #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (

    input logic clk,
    input logic aresetn,
    
    // AXI4-Lite subordinate control interface
    input  logic [ADDR_WIDTH-1:0] s_axi_araddr, // Where to read data from
    input  logic                  s_axi_arvalid,
    output logic                  s_axi_arready,

    input  logic [ADDR_WIDTH-1:0] s_axi_awaddr, // Where to write data to
    input  logic                  s_axi_awvalid,
    output logic                  s_axi_awready,

    output logic [DATA_WIDTH-1:0] s_axi_rdata, 
    output logic [           1:0] s_axi_rresp, // Read response
    output logic                  s_axi_rvalid,
    input  logic                  s_axi_rready,

    input  logic [DATA_WIDTH-1:0]       s_axi_wdata,  
    input  logic [(DATA_WIDTH/8) - 1:0] s_axi_wstrb,
    input  logic                        s_axi_wvalid,
    output logic                        s_axi_wready,

    output logic [1:0] s_axi_bresp, // Write response
    input  logic       s_axi_bready,
    output logic       s_axi_bvalid

);


  // Set local byte offsets for control registers
  localparam logic [ADDR_WIDTH-1:0] REG_DMA_CTRL   = 5'h00;  // Byte offset 0x00
  localparam logic [ADDR_WIDTH-1:0] REG_DMA_STATUS = 5'h04;
  localparam logic [ADDR_WIDTH-1:0] REG_SRC_ADDR = 5'h08;
  localparam logic [ADDR_WIDTH-1:0] REG_DST_ADDR = 5'h0C;
  localparam logic [ADDR_WIDTH-1:0] REG_LENGTH = 5'h10;

  // Control registers
  logic [DATA_WIDTH-1:0] control_reg;
  logic [DATA_WIDTH-1:0] status_reg;
  logic [ADDR_WIDTH-1:0] src_addr_reg;
  logic [ADDR_WIDTH-1:0] dst_addr_reg;
  logic [DATA_WIDTH-1:0] length_reg;

  // Temporarily store address
  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic                  awaddr_received;

  // Temporarily store data
  logic [DATA_WIDTH-1:0]     wdata_reg;
  logic [(DATA_WIDTH/8)-1:0] wstrb_reg;
  logic                      wdata_received;
 
 
  logic write;
  assign write = awaddr_received && wdata_received && !s_axi_bvalid;
  
  // CHANGE TO ACCOUNT FOR WRITE RESPONSE SIGNAL
  assign s_axi_awready = !awaddr_received;
  assign s_axi_wready = !wdata_received;

  // write address channel
  always_ff @(posedge clk) begin
    if (!aresetn) begin // Reset is active low
      awaddr_reg <= '0;
      awaddr_received <= 1'b0;
    end
    else if (write) begin
      awaddr_received <= 1'b0; // received flag is reset after writing
    end
    else if (s_axi_awvalid && s_axi_awready) begin
        awaddr_reg <= s_axi_awaddr;
        awaddr_received <= 1'b1;
    end
  end

  // write data channel
  always_ff @(posedge clk) begin
    if (!aresetn) begin
      wdata_reg <= '0;
      wstrb_reg <= '0;
      wdata_received <= 1'b0;
    end 
    else if (write) begin
      wdata_received <= 1'b0; // received flag is reset after writing
    end
    else if (s_axi_wvalid && s_axi_wready) begin
        wdata_reg <= s_axi_wdata;
        wstrb_reg <=s_axi_wstrb;
        wdata_received <= 1'b1;
    end
  end

  // write response channel
  always_ff @(posedge clk) begin
    if (!aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= 2'b00;
    end
    else begin
      if (s_axi_bready && s_axi_bvalid) begin // Reset valid reg after handshake
        s_axi_bvalid <= 1'b0;
      end

      if (write) begin
        s_axi_bvalid <= 1'b1;
        s_axi_bresp <= 2'b00; // OKAY

      end
    end




  end

  // Update control registers
  always_ff @(posedge clk) begin
    if (!aresetn) begin
      control_reg <= '0;
      status_reg <= '0;
      src_addr_reg <= '0;
      dst_addr_reg <= '0;
      length_reg <= '0;
    end
    else if (write) begin
      if (awaddr_reg == REG_SRC_ADDR) begin
        src_addr_reg <= wdata_reg;

      end
      else if (awaddr_reg == REG_DST_ADDR) begin
        dst_addr_reg <= wdata_reg;

      end
      end
    end






  



  end

endmodule
