`define APB_DATA_WIDTH 8
`define SPI_REG_WIDTH 8
`define APB_ADDR_WIDTH 3

module spi_apb_slave_tb();

reg pclk = 1'b0;
reg preset_n;
reg [`APB_ADDR_WIDTH-1:0] paddr;
reg pwrite;
reg psel;
reg penable;
reg [`APB_DATA_WIDTH-1:0] pwdata;
reg receive_data;
wire send_data;
wire [`APB_DATA_WIDTH-1:0] prdata;
wire pready;
wire pslverr;
reg tip;
reg ss;
reg [`APB_DATA_WIDTH-1:0] miso_data;
wire [`APB_DATA_WIDTH-1:0] mosi_data;
wire [1:0] spi_mode;
wire mstr;
wire cpol;
wire cpha;
wire lsbfe;
wire spiswai;
wire modfen;
wire [2:0] sppr;
wire [2:0] spr;
wire spi_interrupt_request;

spi_apb_interface dut(
    .pclk(pclk),
    .preset_n(preset_n),
    .paddr_i(paddr),
    .pwrite_i(pwrite),
    .psel_i(psel),
    .penable_i(penable),
    .pwdata_i(pwdata),
    .prdata_i(prdata),
    .pready_o(pready),
    .pslverr_o(pslverr),
    .receive_data_i(receive_data),
    .send_data_o(send_data),
    .ss_i(ss),
    .data_miso_i(miso_data),
    .data_mosi_o(mosi_data),
    .spi_mode_o(spi_mode),
    .mstr_o(mstr),
    .cpol_o(cpol),
    .cpha_o(cpha),
    .lsbfe_o(lsbfe),
    .spiswai_o(spiswai),
    .modfen_o(modfen),
    .sppr_o(sppr),
    .spr_o(spr),
    .spi_interrupt_request_o(spi_interrupt_request),
    .tip_i(tip)
);

always #5 pclk = ~pclk;

task reset;
begin
    @(negedge pclk)
    preset_n = 1'b0;
    @(negedge pclk)
    preset_n = 1'b1;
end
endtask

task initialize;
begin
    @(negedge pclk)
    paddr = 3'b0;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b1111_0100;
    ss = 1'b1;
    tip = 1'b0;

    @(negedge pclk)
    paddr = 3'b0;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b1;
    pwdata = 8'b1111_0100;

    @(negedge pclk)
    paddr = 3'b0;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b1111_0100;

    @(negedge pclk)
    paddr = 3'b1;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b1100_0010;

    @(negedge pclk)
    paddr = 3'b1;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b1;
    pwdata = 8'b1100_0010;

    @(negedge pclk)
    paddr = 3'b1;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b1100_0010;

    @(negedge pclk)
    paddr = 3'b010;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b0010_0111;

    @(negedge pclk)
    paddr = 3'b010;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b1;
    pwdata = 8'b0010_0111;

    @(negedge pclk)
    paddr = 3'b010;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b0010_0111;
end
endtask

task write;
begin
    @(negedge pclk)
    paddr = 3'b101;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b1100_1111;
    tip = 1'b0;

    @(negedge pclk)
    paddr = 3'b101;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b1;
    pwdata = 8'b1100_1111;

    @(negedge pclk)
    paddr = 3'b101;
    pwrite = 1'b1;
    psel = 1'b1;
    penable = 1'b0;
    pwdata = 8'b1100_1111;
end
endtask

task read;
begin
    @(negedge pclk)
    paddr = 3'b101;
    pwrite = 1'b0;
    psel = 1'b1;
    penable = 1'b0;

    @(negedge pclk)
    paddr = 3'b101;
    pwrite = 1'b0;
    psel = 1'b1;
    penable = 1'b1;

    @(negedge pclk)
    paddr = 3'b101;
    pwrite = 1'b0;
    psel = 1'b1;
    penable = 1'b0;
end
endtask

initial
begin
    #5;
    reset;
    #10;
    initialize;
    #10;
    write;
    #10;
    miso_data = 8'hff;
    ss = 1'b0;
    receive_data = 1'b1;
    read;
    #20;
    receive_data = 1'b0;
    #50 $finish();
end

endmodule
