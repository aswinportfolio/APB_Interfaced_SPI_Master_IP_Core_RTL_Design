`define SPI_APB_DATA_WIDTH 8
`define SPI_REG_WIDTH 8
`define SPI_APB_ADDR_WIDTH 3
 
module spi_core_tb();
    reg                              pclk = 1'b0;
    reg                              preset_n;
    reg  [`SPI_APB_ADDR_WIDTH-1:0]   paddr;
    reg                              pwrite;
    reg                              psel;
    reg                              penable;
    reg  [`SPI_APB_DATA_WIDTH-1:0]   pwdata;
    wire [`SPI_APB_DATA_WIDTH-1:0]   prdata;
    wire                             pready;
    wire                             pslverr;
    reg                              miso;
    wire                             ss;
    wire                             sclk;
    wire                             spi_interrupt_request;
    wire                             mosi;
 
    integer i;
 

    spi_core SPI_CORE (
        .pclk                (pclk),
        .preset_n            (preset_n),
        .paddr_i             (paddr),
        .pwrite_i            (pwrite),
        .psel_i              (psel),
        .penable_i           (penable),
        .pwdata_i            (pwdata),
        .prdata_o            (prdata),
        .pready_o            (pready),
        .pslverr_o           (pslverr),
        .miso_i              (miso),
        .ss_o                (ss),
        .sclk_o              (sclk),
        .spi_interrupt_req_o (spi_interrupt_request),
        .mosi_o              (mosi)
    );
 

    always #5 pclk = ~pclk;
    task reset;
    begin
        @(posedge pclk);
        preset_n = 1'b0;
        @(posedge pclk);
        preset_n = 1'b1;
    end
    endtask
    task write_registers(input[7:0]contr1_data,input[7:0]contr2_data,input[7:0]baud_data);
    begin
        @(posedge pclk);
        paddr   = 3'b0;
        pwrite  = 1'b1;
        psel    = 1'b1;
        penable = 1'b0;
        pwdata  = contr1_data;          

        @(posedge pclk);
        paddr   = 3'b0;
        pwrite  = 1'b1;
        psel    = 1'b1;
        penable = 1'b1;
        pwdata  = contr1_data;

        @(posedge pclk);
	wait(pready);
        penable = 1'b0;

        @(posedge pclk);
        paddr   = 3'b1;
        pwrite  = 1'b1;
        psel    = 1'b1;
        penable = 1'b0;
        pwdata  = contr2_data;          

        @(posedge pclk);
        paddr   = 3'b1;
        pwrite  = 1'b1;
        psel    = 1'b1;
        penable = 1'b1;
        pwdata  = contr2_data;

        @(posedge pclk);
	wait(pready);
        penable = 1'b0;

        @(posedge pclk);
        paddr   = 3'b010;
        pwrite  = 1'b1;
        psel    = 1'b1;
        penable = 1'b0;
        pwdata  = baud_data;          

        @(posedge pclk);
        paddr   = 3'b010;
        pwrite  = 1'b1;
        psel    = 1'b1;
        penable = 1'b1;
        pwdata  = baud_data;

        @(posedge pclk);
	wait(pready);
        penable = 1'b0;

    end
    endtask
 
    task write_data_register(input [7:0] write_data);
        begin

            @(posedge pclk)
            paddr   = 3'b101;
            pwrite  = 1'b1;
            psel    = 1'b1;
            penable = 1'b1; //keep high
            pwdata  = write_data;

            @(posedge pclk)
            paddr   = 3'b101;
            pwrite  = 1'b1;
            psel    = 1'b1;
            penable = 1'b1;
            pwdata  = write_data;

            @(posedge pclk)
            wait(pready);
            paddr   = 3'b101;
            pwrite  = 1'b0;
            psel    = 1'b0;
            penable = 1'b0;
            pwdata  = write_data;
    end
    endtask

    task write_miso_data_low_lsbfe(input [7:0] miso_data);
    begin
        wait(~ss);
        miso = miso_data[0];
	@(negedge sclk)
        for (i = 1; i <= 7; i = i + 1) begin
            @(negedge sclk);
            miso = miso_data[i];
        end
    end
    endtask

    task write_miso_data_low_lsbfe0(input [7:0] miso_data);
    begin
        wait(~ss);
        for (i = 7; i >= 0; i = i - 1) begin
            @(negedge sclk);
            miso = miso_data[i];
        end
    end
    endtask
 
    task write_miso_data_high_lsbfe(input [7:0] miso_data);
    begin
        miso = 0;
        wait(~ss);
        for (i = 0; i <= 7; i = i + 1) begin
            @(posedge sclk);
            miso = miso_data[i];
        end
    end
    endtask
 
 
    task write_miso_data_high_lsbfe0(input [7:0] miso_data);
    begin
        wait(~ss);
        miso = miso_data[7];
        for (i = 6; i >= 0; i = i - 1) begin
            @(posedge sclk);
            miso = miso_data[i];
        end
    end
    endtask
 
    initial 
      begin
        miso = 0;
        reset;
        // Write Control Register with Cphase 1 (even edges), Cpol0, lsbfe 1-checked
        write_registers(8'b1111_0101, 8'b0000_0000, 8'b0000_0001);
        write_data_register(8'b1010_1010);
        //write_miso_data_high_lsbfe(8'b0101_0101);
        write_miso_data_low_lsbfe(8'b01010111);
        #100;
        write_registers(8'b1111_0101, 8'b0000_0000, 8'b0000_0010);
        write_data_register(8'b1010_1010);
        //write_miso_data_high_lsbfe(8'b0101_0101);
        write_miso_data_low_lsbfe(8'b01010101);

        // // Write Control Register with Cphase 1 (even edges), Cpol1, lsbfe 1-checked
        // write_registers(8'b1111_1101, 8'b1100_0001, 8'b0000_0010);
        // write_data_register(8'b0101_0101);
        // write_miso_data_high_lsbfe(8'b0101_0101);
        // #100;

        // // write control register with cphase 0 cpol 0, lsbfe 1-checked
        // // write_registers(8'b1111_0001, 8'b1100_0001, 8'b0010_0001);
        // // write_data_register(8'b1100_0011);
        // // write_miso_data_low_lsbfe(8'b1100_0011);
        #1000;
	$finish();
     end
 
endmodule
 

