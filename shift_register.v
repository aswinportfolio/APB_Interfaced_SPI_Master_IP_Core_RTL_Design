
`define SPI_APB_DATA_WIDTH 8
`define SPI_REG_WIDTH 8
`define SPI_APB_ADDR_WIDTH 3

module spi_shifter(
    input PCLK,
    input PRESET_n,
    input ss_i,
    input send_data_i,
    input lsbfe_i,
    input cpha_i,
    input cpol_i,
    input miso_receive_sclk_i,
    input miso_receive_sclk0_i,
    input mosi_send_sclk0_i,
    input mosi_send_sclk_i,
    input [`SPI_APB_DATA_WIDTH-1:0] data_mosi_i,
    input miso_i,
    input receive_data_i,
    output [`SPI_APB_DATA_WIDTH-1:0] data_miso_o,
    output reg mosi_o
);

reg [`SPI_APB_DATA_WIDTH-1:0] shift_register_s;
reg [`SPI_APB_DATA_WIDTH-1:0] temp_reg_s;

reg [2:0] count_s;
reg [2:0] count1_s;
reg [2:0] count2_s;
reg [2:0] count3_s;

always @(posedge PCLK or negedge PRESET_n)
begin
    if (!PRESET_n)
    begin
        shift_register_s <= 8'b0;
    end
    else if (send_data_i)
    begin
        shift_register_s <= data_mosi_i;
    end
end

assign data_miso_o = receive_data_i ? temp_reg_s : 8'b00000000;

always @(posedge PCLK or negedge PRESET_n)
begin
    if (!PRESET_n)
    begin
        mosi_o   <= 1'b0;
        count_s  <= 3'd0;
        count1_s <= 3'd7;
    end
    else
    begin
        if (ss_i)
        begin
            mosi_o   <= 1'b0;
            count_s  <= 3'd0;
            count1_s <= 3'd7;
        end
        else
        begin
            if ((!cpha_i && cpol_i) || (cpha_i && !cpol_i))
            begin
                if (lsbfe_i)
                begin
                    if (mosi_send_sclk0_i)
                    begin
                        mosi_o <= shift_register_s[count_s];
                        count_s <= count_s + 1'b1;
                    end
                end
                else
                begin
                    if (mosi_send_sclk0_i)
                    begin
                        mosi_o <= shift_register_s[count1_s];
                        count1_s <= count1_s - 1'b1;
                    end
                end
            end
            else
            begin
                if (lsbfe_i)
                begin
                    if (mosi_send_sclk_i)
                    begin
                        mosi_o <= shift_register_s[count_s];
                        count_s <= count_s + 1'b1;
                    end
                end
                else
                begin
                    if (mosi_send_sclk_i)
                    begin
                        mosi_o <= shift_register_s[count1_s];
                        count1_s <= count1_s - 1'b1;
                    end
                end
            end
        end
    end
end

always @(posedge PCLK or negedge PRESET_n)
begin
    if (!PRESET_n)
    begin
        count2_s   <= 3'd0;
        count3_s   <= 3'd7;
        temp_reg_s <= 8'b0;
    end
    else
    begin
        if (ss_i)
        begin
            count2_s   <= 3'd0;
            count3_s   <= 3'd7;
            temp_reg_s <= 8'b0;
        end
        else
        begin
            if ((!cpha_i && cpol_i) || (cpha_i && !cpol_i))
            begin
                if (lsbfe_i)
                begin
                    if (miso_receive_sclk0_i)
                    begin
                        temp_reg_s[count2_s] <= miso_i;
                        count2_s <= count2_s + 1'b1;
                    end
                end
                else
                begin
                    if (miso_receive_sclk0_i)
                    begin
                        temp_reg_s[count3_s] <= miso_i;
                        count3_s <= count3_s - 1'b1;
                    end
                end
            end
            else
            begin
                if (lsbfe_i)
                begin
                    if (miso_receive_sclk_i)
                    begin
                        temp_reg_s[count2_s] <= miso_i;
                        count2_s <= count2_s + 1'b1;
                    end
                end
                else
                begin
                    if (miso_receive_sclk_i)
                    begin
                        temp_reg_s[count3_s] <= miso_i;
                        count3_s <= count3_s - 1'b1;
                    end
                end
            end
        end
    end
end

endmodule

