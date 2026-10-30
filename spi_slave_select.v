module spi_slave_select(input preset_n,
  input [1:0]spi_mode_i,
  input mstr_i,
  input spiswai_i,
  input pclk,
  input send_data_i,
  input [11:0]baudratedivisor_i,
  output reg ss_o,
  output reg receive_data_o,
  output tip_o);

reg[15:0]count_s;
wire [15:0]target_s;
reg rcv_s;

assign target_s=baudratedivisor_i*5'd16;
assign tip_o=(~ss_o);

always@(negedge preset_n or posedge pclk)
begin
  if(!preset_n)
  begin
    count_s<=16'h0000;
    ss_o<=1'b1;
    rcv_s<=1'b0;
  end
  else
    if(mstr_i &&(spi_mode_i==2'b00||(spi_mode_i==2'b01&&(~spiswai_i))))
    begin
      if(send_data_i)
      begin
        ss_o<=1'b0;
	count_s<=16'h0;
	rcv_s <= 1'b0;
      end
      else if(count_s<=(target_s))
      begin
	ss_o<=1'b0;
	count_s<=count_s+1'b1;
	if(count_s==(target_s-1'b1))
	  rcv_s<=1'b1;
      end
      else
      begin
        ss_o<=1'b1;
	rcv_s<=1'b0;
	count_s<=16'hffff;
      end
    end
    else
    begin
      ss_o<=1'b1;
      rcv_s<=1'b0;
      count_s<=16'hffff;
    end
end
always@(posedge pclk or negedge preset_n)
begin
  if(!preset_n)
  begin
    receive_data_o<=1'b0;
  end
  else
  begin
    receive_data_o<=rcv_s;
  end
end 
endmodule 