// AXI4-Lite subordinate interface for DMA control and status registers
module axi_lite_regs #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (

    input logic clk,
    input logic aresetn,
    
    // AXI4-Lite subordinate control interface
    input  logic [ADDR_WIDTH-1:0] s_axi_araddr, /
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
    input  logic                        s_axi_wvalid,
    output logic                        s_axi_wready,

    output logic [1:0] s_axi_bresp, 
    input  logic       s_axi_bready,
    output logic       s_axi_bvalid

);


  // Memory-mapped register byte offsets
  localparam logic [ADDR_WIDTH-1:0] REG_DMA_CTRL   = 5'h00;  // Byte offset 0x00
  localparam logic [ADDR_WIDTH-1:0] REG_DMA_STATUS = 5'h04;
  localparam logic [ADDR_WIDTH-1:0] REG_SRC_ADDR = 5'h08;
  localparam logic [ADDR_WIDTH-1:0] REG_DST_ADDR = 5'h0C;
  localparam logic [ADDR_WIDTH-1:0] REG_LENGTH = 5'h10;

  // Control registers
  logic [DATA_WIDTH-1:0] control_reg;
  logic [DATA_WIDTH-1:0] status_reg; // read-only
  logic [ADDR_WIDTH-1:0] src_addr_reg;
  logic [ADDR_WIDTH-1:0] dst_addr_reg;
  logic [DATA_WIDTH-1:0] length_reg;

// Buffer AW and W independently because their handshakes
// may occur in either order.

  // Buffered write address
  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic                  awaddr_received;

  // Buffered write data and byte strobes
  logic [DATA_WIDTH-1:0]     wdata_reg;
  logic [(DATA_WIDTH/8)-1:0] wstrb_reg;
  logic                      wdata_received;
 
 
  // Only permit one outstanding write transaction
  // Block new requests while BVALID is 1 (pending response)
  logic write;
  assign write = awaddr_received && wdata_received && !s_axi_bvalid;
  
  
  assign s_axi_awready = !awaddr_received && !s_axi_bvalid;
  assign s_axi_wready = !wdata_received && !s_axi_bvalid;

  // Write address channel
  always_ff @(posedge clk) begin
    if (!aresetn) begin 
      awaddr_reg <= '0;
      awaddr_received <= 1'b0;
    end
    else begin
      if (write) begin
        awaddr_received <= 1'b0;
      end
      
      if (s_axi_awvalid && s_axi_awready) begin
        awaddr_reg <= s_axi_awaddr;
        awaddr_received <= 1'b1;
      end
    end
  end

  localparam logic [1:0] OKAY = 2'b00;
  localparam logic [1:0] SLVERR = 2'b10;

  // Write data channel
  always_ff @(posedge clk) begin
    if (!aresetn) begin
      wdata_reg <= '0;
      wstrb_reg <= '0;
      wdata_received <= 1'b0;
    end 
    else begin
      if (write) begin
        wdata_received <= 1'b0; 
      end
      
      if (s_axi_wvalid && s_axi_wready) begin
        wdata_reg <= s_axi_wdata;
        wstrb_reg <=s_axi_wstrb;
        wdata_received <= 1'b1;
      end
    end
  end

  // Write response channel
  always_ff @(posedge clk) begin
    if (!aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= 2'b00;
    end
    else begin
      if (s_axi_bready && s_axi_bvalid) begin // Complete the write response when accepted
        s_axi_bvalid <= 1'b0;
      end

      if (write) begin
        s_axi_bvalid <= 1'b1;
        case (awaddr_reg)
          REG_DMA_CTRL, REG_DST_ADDR, REG_SRC_ADDR, REG_LENGTH: begin
            s_axi_bresp <= OKAY;
          end

          default: begin
            s_axi_bresp <= SLVERR; 
          end
        endcase
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
      case (awaddr_reg)
        REG_DMA_CTRL: begin
          for (int i = 0; i < DATA_WIDTH/8; i++) begin
          if (wstrb_reg[i]) begin
            control_reg[8*i +: 8] <= wdata_reg[8*i +: 8];
          end
          end
        end

        REG_SRC_ADDR: begin
          for (int i = 0; i < DATA_WIDTH/8; i++) begin
          if (wstrb_reg[i]) begin
            src_addr_reg[8*i +: 8] <= wdata_reg[8*i +: 8];
          end
          end
        end

        REG_DST_ADDR: begin
          for (int i = 0; i < DATA_WIDTH/8; i++) begin
          if (wstrb_reg[i]) begin
            dst_addr_reg[8*i +: 8] <= wdata_reg[8*i +: 8];
          end
          end
        end

        REG_LENGTH: begin
          for (int i = 0; i < DATA_WIDTH/8; i++) begin
          if (wstrb_reg[i]) begin
            length_reg[8*i +: 8] <= wdata_reg[8*i +: 8];
          end
          end
        end

        default: begin
        end
      endcase
    end
  end

// Read address channel
// Only premits one outstanding read transaction
assign s_axi_arready = aresetn && !s_axi_rvalid;

// Read response channel 
always_ff @(posedge clk) begin
  if (!aresetn) begin
    s_axi_rvalid <= 1'b0;
    s_axi_rdata <= '0;
    s_axi_rresp <= OKAY;
  end
  else if (s_axi_arready && s_axi_arvalid) begin
    s_axi_rvalid <= 1;
    case (s_axi_araddr)
      REG_DMA_CTRL: begin
        s_axi_rdata <= control_reg;
        s_axi_rresp <= OKAY;
      end

      REG_DMA_STATUS: begin
        s_axi_rdata <= status_reg;
        s_axi_rresp <= OKAY;
      end

      REG_SRC_ADDR: begin
        s_axi_rdata <= src_addr_reg;
        s_axi_rresp <= OKAY;
      end

      REG_DST_ADDR: begin
        s_axi_rdata <= dst_addr_reg;
        s_axi_rresp <= OKAY;
      end

      REG_LENGTH: begin
        s_axi_rdata <= length_reg;
        s_axi_rresp <= OKAY;
      end

      default: begin
        s_axi_rdata <= '0;
        s_axi_rresp <= SLVERR;
      end
    endcase
  end
  else if (s_axi_rvalid && s_axi_rready) begin 
    s_axi_rvalid <= 1'b0;
  end
end

endmodule
