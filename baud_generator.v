module baud_generator (
    input             pclk,
    input             preset_n,
    input      [1:0]  spi_mode_i,
    input             spiswai_i,
    input             cpol_i,
    input             cpha_i,
    input             ss_i,
    input      [2:0]  sppr_i,
    input      [2:0]  spr_i,
    output reg        sclk_o,
    output reg        miso_receive_sclk_o,
    output reg        miso_receive_sclk0_o,
    output reg        mosi_send_sclk_o,
    output reg        mosi_send_sclk0_o,
    output wire [11:0] baudratedivisor_o
);

reg  [11:0] count;
wire        mode_enable;
wire        sclk_enable;
wire        enable_flags;
wire        count_send;
wire        count_receive;
wire        pre_sclk;

assign baudratedivisor_o = (sppr_i + 1) * (1'b1 << (spr_i + 1));

assign mode_enable = (spi_mode_i == 2'b00) || ((spi_mode_i == 2'b01) && (~spiswai_i));
assign sclk_enable = mode_enable & (~ss_i);

always @(posedge pclk or negedge preset_n) 
  begin
    if (!preset_n)
        count <= 12'b0;
    else if (sclk_enable) 
      begin
        if (count == (baudratedivisor_o - 1'b1))
            count <= 12'b0;
        else
            count <= count + 1'b1;
      end
  end

assign pre_sclk = cpol_i;

always @(posedge pclk or negedge preset_n) 
  begin
    if (!preset_n)
        sclk_o <= pre_sclk;
    else if (sclk_enable) 
      begin
        if (count == (baudratedivisor_o - 1'b1))
            sclk_o <= ~sclk_o;
      end
    else
        sclk_o <= pre_sclk;
  end

assign enable_flags  = cpha_i ^ cpol_i;
assign count_send    = (count == (baudratedivisor_o - 2'b10));
assign count_receive = (count == (baudratedivisor_o - 1'b1));

always @(posedge pclk or negedge preset_n) 
  begin
    if (!preset_n) 
      begin
        miso_receive_sclk_o  <= 1'b0;
        miso_receive_sclk0_o <= 1'b0;
        mosi_send_sclk_o     <= 1'b0;
        mosi_send_sclk0_o    <= 1'b0;
      end
    else 
      begin
        miso_receive_sclk_o  <= 1'b0;
        miso_receive_sclk0_o <= 1'b0;
        mosi_send_sclk_o     <= 1'b0;
        mosi_send_sclk0_o    <= 1'b0;
	if (!ss_i && !spiswai_i)
	begin
        if (!enable_flags && !sclk_o) 
          begin
            miso_receive_sclk_o <= count_receive;
            mosi_send_sclk_o    <= count_send;
          end
        else if (enable_flags && sclk_o) 
          begin
            miso_receive_sclk0_o <= count_receive;
            mosi_send_sclk0_o    <= count_send;
          end
        end
       end
  end

endmodule
