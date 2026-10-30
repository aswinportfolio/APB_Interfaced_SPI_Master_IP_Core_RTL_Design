`timescale 1ns/1ps

module baud_generator_tb();
  reg pclk = 1'b0;
  reg preset_n;
  reg [1:0] spi_mode_i;
  reg spiswai_i;
  reg cpol_i;
  reg cpha_i;
  reg ss_i;
  reg [2:0] sppr_i;
  reg [2:0] spr_i;
  wire sclk_o;
  wire miso_receive_sclk_o;
  wire miso_receive_sclk0_o;
  wire mosi_send_sclk_o;
  wire mosi_send_sclk0_o;
  wire [11:0] baudratedivisor_o;

  baud_generator dut(pclk, preset_n, spi_mode_i, spiswai_i, cpol_i, cpha_i, ss_i,
                     sppr_i, spr_i, sclk_o, miso_receive_sclk_o, miso_receive_sclk0_o,
                     mosi_send_sclk_o, mosi_send_sclk0_o, baudratedivisor_o);

  always #5 pclk = ~pclk;

  task initialize;
    begin
      spi_mode_i = 2'b00;
      spiswai_i  = 1'b0;
      cpol_i     = 1'b0;
      cpha_i     = 1'b0;
      ss_i       = 1'b1;
      sppr_i     = 3'd0;
      spr_i      = 3'd0;
      preset_n   = 1'b0;
    end
  endtask

  task reset;
    begin
      preset_n = 1'b0;
      #20;
      preset_n = 1'b1;
    end
  endtask

  task baud_gen(input [2:0] i, j, input m, n);
    begin
      ss_i       = 1'b1;
      #20;
      spi_mode_i = 2'b00;
      sppr_i     = i;
      spr_i      = j;
      cpol_i     = m;
      cpha_i     = n;
      spiswai_i  = 1'b0;
      #20;
      ss_i       = 1'b0;
      repeat (8 * baudratedivisor_o) @(posedge pclk);
    end
  endtask

  initial begin
    initialize;
    #10;
    reset;
    #10;
    baud_gen(3'd0, 3'd1, 1'b0, 1'b0);
    #200;
    baud_gen(3'd0, 3'd1, 1'b0, 1'b1);
    #200;
    baud_gen(3'd1, 3'd1, 1'b1, 1'b0);
    #660
    baud_gen(3'd0, 3'd1, 1'b1, 1'b1);
    #660;
    spiswai_i = 1'b1;
    #660;
    $finish;
  end
endmodule