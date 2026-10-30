
module spi_shifter_tb;

    reg PCLK=1'b0;
    reg PRESETn;
    reg [1:0] spi_mode;
    reg spiswai;
    reg ss;
    reg cpol;
    reg cpha;
    reg lsbfe;
    reg miso;
    reg send_data;
    reg receive_data;
    reg [7:0] data_mosi;
    wire [7:0] data_miso;
    reg [2:0] sppr=1;
    reg [2:0] spr=1;

    reg [11:0] BaudRateDivisor;
    reg [11:0] count;
    reg sclk;

    reg miso_receive_sclk_o;
    reg miso_receive_sclk0_o;
    reg mosi_send_sclk_o;
    reg mosi_send_sclk0_o;
    
    wire mosi; // Added wire for MOSI output from MUT

    wire pre_sclk;

    integer i;
spi_shifter mut(
    .PCLK(PCLK),
    .PRESET_n(PRESETn),
    .ss_i(ss),
    .send_data_i(send_data),
    .lsbfe_i(lsbfe),
    .cpha_i(cpha),
    .cpol_i(cpol),
    .miso_receive_sclk_i(miso_receive_sclk_o),
    .miso_receive_sclk0_i(miso_receive_sclk0_o),
    .mosi_send_sclk0_i(mosi_send_sclk0_o),
    .mosi_send_sclk_i(mosi_send_sclk_o),
    .data_mosi_i(data_mosi),
    .miso_i(miso),
    .receive_data_i(receive_data),
    .data_miso_o(data_miso), 
    .mosi_o(mosi)            
);


always #5 PCLK = ~PCLK;

assign pre_sclk = cpol ? 1'b1 : 1'b0;

always @(*)
  begin
    BaudRateDivisor = ((sppr+1)*(2**(spr+1)));
  end

always @(posedge PCLK or negedge PRESETn)
  begin
    if (!PRESETn)
      begin
        count <= 12'd0;
        sclk <= pre_sclk;
      end
    else if ((~ss) && (spi_mode==2'b00 || (spi_mode==2'b01 && (~spiswai))))
      begin
        if (count == (BaudRateDivisor/2 - 1'b1))
          begin
            count <= 12'd0;
            sclk <= ~sclk;
          end
          else
            count <= count + 1'b1;
       end
    else
      begin
        sclk <= pre_sclk;
        count <= 12'd0;
      end
  end

always @(posedge PCLK or negedge PRESETn)
  begin
    if(!PRESETn)
      begin
        miso_receive_sclk_o  <= 1'b0;
        miso_receive_sclk0_o <= 1'b0;
      end
    else
      begin
        if((!cpha&&cpol)||(cpha&&!cpol))
          begin
          if(sclk)
            if (count == (BaudRateDivisor/2 - 2'b01))
              miso_receive_sclk0_o  <= 1'b1;
            else
              miso_receive_sclk0_o <= 1'b0;
          else 
            miso_receive_sclk0_o  <= 1'b0;
          end
        else
          begin
            if(~sclk)
              if(count == (BaudRateDivisor/2 - 2'b01))
                 miso_receive_sclk_o <= 1'b1;
              else
                 miso_receive_sclk_o  <= 1'b0;
            else
               miso_receive_sclk_o  <= 1'b0; 
           end
      end                
  end            

always @(posedge PCLK or negedge PRESETn)
  begin
    if (!PRESETn)
      begin
        mosi_send_sclk0_o <= 1'b0;
        mosi_send_sclk_o  <= 1'b0;
      end
    else
      begin
        mosi_send_sclk0_o <= 1'b0;
        mosi_send_sclk_o  <= 1'b0;

        if ((!cpha && cpol) || (cpha && !cpol))
          begin
            if (sclk)
              begin
                if (count == (BaudRateDivisor/2 - 2'b10))
                  begin
                    mosi_send_sclk0_o <= 1'b1;
                  end
              end
          end
        else
          begin
            if (!sclk)
              begin
                if (count == (BaudRateDivisor/2 - 2'b10))
                  begin
                    mosi_send_sclk_o <= 1'b1;
                  end
              end
          end
      end
  end        

task reset;
  begin
    #1;
    PRESETn = 1'b0;
    #25;
    PRESETn = 1'b1;
  end
endtask

task initialize;
  begin 
    PRESETn = 1'b1;
    ss = 1'b1;
    lsbfe = 1'b1;
    cpha = 1'b0;
    cpol = 1'b1;
    miso = 1'b0;
    send_data = 1'b0;
    receive_data = 1'b0;
  end
endtask

task Sample_posedge;
  begin
    PRESETn = 1'b1;
    @(posedge PCLK);
    send_data = 1'b1;
    data_mosi = 8'b1100_0011;
    @(posedge PCLK);
    @(posedge PCLK);
    ss = 1'b0;
    send_data = 1'b0;
    lsbfe = 1'b1;
    cpha = 1'b0;
    cpol = 1'b0;
    repeat (8)
      @(posedge sclk);
    @(posedge PCLK);
    receive_data = 1'b1;
      ss = 1'b1;
    @(posedge PCLK);
    @(posedge PCLK);
    receive_data = 1'b0;
    end
endtask

task Sample_negedge;
  begin
    PRESETn = 1'b1;
    @(negedge PCLK);
    send_data = 1'b1;
    data_mosi = 8'b0011_1101;
     @(posedge PCLK);
     @(posedge PCLK);
     ss = 1'b0;
     send_data = 1'b0;
     lsbfe = 1'b0;
     cpha = 1'b0;
     cpol = 1'b1;
       repeat (8)
         @(negedge sclk);
     @(negedge PCLK);
     receive_data = 1'b1;
     ss = 1'b1;
     @(posedge PCLK);
     @(posedge PCLK);
     receive_data = 1'b0;
   end
endtask

task send_miso_not_cphase;
  begin
    for (i = 0; i <= 7; i = i + 1)
      begin
        @(negedge sclk);
        begin
          miso = 1'b1;
        end
       end
  end
endtask

task baud_gen(input [2:0] i, input [2:0] j, input m, input n);
  begin
    spi_mode = 2'b00;
    sppr = i;
    spr = j;
    cpol = m;
    cpha = n;
    ss = 1'b0;
    spiswai = 1'b0;
  end
endtask

initial
begin
    initialize;
    #10;
    reset;
    #10;
    fork
        begin
            baud_gen(3'd0,3'd2,1'b0,1'b1);
            Sample_posedge;
        end
        send_miso_not_cphase;
    join
    fork
        begin
            baud_gen(3'd0,3'd2,1'b0,1'b1);
            Sample_negedge;
        end
        send_miso_not_cphase;
    join
    #150 $finish();
end

endmodule
