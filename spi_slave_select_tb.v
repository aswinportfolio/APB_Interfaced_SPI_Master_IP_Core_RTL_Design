module spi_slave_select_tb();
  reg preset_n;
  reg[1:0]spi_mode;
  reg mstr;
  reg spiswai;
  reg pclk=1'b0;
  reg send_data;
  reg[11:0]baudratedivisor;
  wire ss;
  wire receive_data;
  wire tip;

spi_slave_select dut(.preset_n(preset_n),
		     .spi_mode_i(spi_mode),
		     .mstr_i(mstr),
		     .spiswai_i(spiswai),
		     .pclk(pclk),
		     .send_data_i(send_data),
		     .baudratedivisor_i(baudratedivisor),
		     .ss_o(ss),
		     .receive_data_o(receive_data),
		     .tip_o(tip));
always #5pclk=~pclk;
task reset;
  begin 
    #10;
    preset_n=1'b0;
    #10;
    preset_n=1'b1;
  end
endtask
task ss_generation;
  begin 
    spi_mode=2'b00;
    send_data=1'b1;
    mstr=1'b1;
    spiswai=1'b0;
    baudratedivisor=12'h4;
    #10;
    @(negedge pclk)
    send_data=1'b0;
  end
endtask
task ss_generation_stop;
  begin
    spi_mode=2'b10;
    send_data=1'b0;
  end
endtask
initial
  begin
    reset;
    #10;
    ss_generation;
    #800;
    ss_generation_stop;
    #200 $finish();
  end
endmodule 