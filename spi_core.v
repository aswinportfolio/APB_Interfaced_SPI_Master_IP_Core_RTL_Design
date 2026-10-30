`define SPI_APB_DATA_WIDTH 8
`define SPI_REG_WIDTH 8
`define SPI_APB_ADDR_WIDTH 3
 
module spi_core(
    input  wire                              pclk,
    input  wire                              preset_n,
    input  wire                              pwrite_i,
    input  wire [`SPI_APB_ADDR_WIDTH-1:0]    paddr_i,
    input  wire                              psel_i,
    input  wire                              penable_i,
    input  wire [`SPI_APB_DATA_WIDTH-1:0]    pwdata_i,
    output wire [`SPI_APB_DATA_WIDTH-1:0]    prdata_o,
    output wire                              pready_o,
    output wire                              pslverr_o,
    input  wire                              miso_i,
    output wire                              ss_o,
    output wire                              sclk_o,
    output wire                              spi_interrupt_req_o,
    output wire                              mosi_o
);
 
    wire [`SPI_APB_DATA_WIDTH-1:0] data_miso_s;
    wire [`SPI_APB_DATA_WIDTH-1:0] data_mosi_s;
 
    wire        send_data_s;
    wire        receive_data_s;
    wire        tip_s;
    wire [1:0]  spi_mode_s;
    wire        mstr_s;
    wire        cpol_s;
    wire        cpha_s;
    wire        lsbfe_s;
    wire        spiswai_s;
    wire        ssoe_s;      
    wire        modfen_s;    
    wire [2:0]  sppr_s;
    wire [2:0]  spr_s;
    wire [11:0] baudratedivisor_s;
    wire        miso_receive_sclk_s;
    wire        miso_receive_sclk0_s;
    wire        mosi_send_sclk0_s;
    wire        mosi_send_sclk_s;
 
    baud_generator m1(
        .pclk                 (pclk),
        .preset_n             (preset_n),
        .spi_mode_i           (spi_mode_s),
        .spiswai_i            (spiswai_s),
        .cpol_i               (cpol_s),
        .cpha_i               (cpha_s),
        .ss_i                 (ss_o),
        .sppr_i               (sppr_s),
        .spr_i                (spr_s),
        .sclk_o               (sclk_o),
        .miso_receive_sclk_o  (miso_receive_sclk_s),
        .mosi_send_sclk_o     (mosi_send_sclk_s),
        .mosi_send_sclk0_o    (mosi_send_sclk0_s),
        .miso_receive_sclk0_o (miso_receive_sclk0_s),   
        .baudratedivisor_o    (baudratedivisor_s)
    );
 
    spi_shifter m2(
        .PCLK                 (pclk),
        .PRESET_n             (preset_n),
        .ss_i                 (ss_o),
        .send_data_i          (send_data_s),
        .lsbfe_i              (lsbfe_s),
        .cpha_i               (cpha_s),
        .cpol_i               (cpol_s),
        .miso_receive_sclk_i  (miso_receive_sclk_s),
        .miso_receive_sclk0_i (miso_receive_sclk0_s),
        .mosi_send_sclk0_i    (mosi_send_sclk0_s),
        .mosi_send_sclk_i     (mosi_send_sclk_s),
        .data_mosi_i          (data_mosi_s),
        .miso_i               (miso_i),
        .receive_data_i       (receive_data_s),
        .data_miso_o          (data_miso_s),
        .mosi_o               (mosi_o)
    );
 
    spi_apb_interface m3(
        .pclk                    (pclk),
        .preset_n                (preset_n),
        .paddr_i                 (paddr_i),
        .pwrite_i                (pwrite_i),
        .psel_i                  (psel_i),
        .penable_i               (penable_i),            
        .pwdata_i                (pwdata_i),
        .prdata_i                (prdata_o),             
        .pready_o                (pready_o),
        .pslverr_o               (pslverr_o),
        .ss_i                    (ss_o),
        .data_miso_i             (data_miso_s),
        .send_data_o             (send_data_s),
        .receive_data_i          (receive_data_s),
        .tip_i                   (tip_s),
        .data_mosi_o             (data_mosi_s),
        .spi_mode_o              (spi_mode_s),
        .spiswai_o               (spiswai_s),
        .mstr_o                  (mstr_s),
        .cpol_o                  (cpol_s),
        .cpha_o                  (cpha_s),
        .lsbfe_o                 (lsbfe_s),
        .ssoe                    (ssoe_s),              
        .modfen_o                (modfen_s),
        .sppr_o                  (sppr_s),
        .spr_o                   (spr_s),
        .spi_interrupt_request_o (spi_interrupt_req_o) 
    );
 
    spi_slave_select m4(
        .preset_n          (preset_n),
        .spi_mode_i        (spi_mode_s),
        .mstr_i            (mstr_s),
        .spiswai_i         (spiswai_s),
        .pclk              (pclk),
        .send_data_i       (send_data_s),
        .baudratedivisor_i (baudratedivisor_s),
        .ss_o              (ss_o),
        .receive_data_o    (receive_data_s),
        .tip_o             (tip_s)
    );
 
endmodule
 
 
