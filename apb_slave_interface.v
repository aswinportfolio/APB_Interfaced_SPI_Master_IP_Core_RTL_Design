`define SPI_APB_DATA_WIDTH 8
`define SPI_REG_WIDTH 8
`define SPI_APB_ADDR_WIDTH 3

module spi_apb_interface (
    input pclk,
    input preset_n,
    input [`SPI_APB_ADDR_WIDTH-1:0] paddr_i,
    input pwrite_i,
    input psel_i,
    input penable_i,
    input [`SPI_APB_DATA_WIDTH-1:0] pwdata_i,
    output reg [`SPI_APB_DATA_WIDTH-1:0] prdata_i,
    output pready_o,
    output pslverr_o,
    input ss_i,
    input [`SPI_APB_DATA_WIDTH-1:0] data_miso_i,
    output reg send_data_o,
    input receive_data_i,
    input tip_i,
    output reg [`SPI_APB_DATA_WIDTH-1:0] data_mosi_o,
    output reg [1:0] spi_mode_o,
    output spiswai_o,
    output mstr_o,
    output cpol_o,
    output cpha_o,
    output lsbfe_o,
    output ssoe,
    output modfen_o,
    output [2:0] sppr_o,
    output [2:0] spr_o,
    output spi_interrupt_request_o
);

localparam idle   = 2'b00;
localparam setup  = 2'b01;
localparam enable = 2'b10;

localparam spi_run  = 2'b00;
localparam spi_wait = 2'b01;
localparam spi_stop = 2'b10;

localparam cr2_mask = 8'b0001_1011;
localparam br_mask  = 8'b0111_0111;

reg [1:0] state;
reg [1:0] next_state;
reg [1:0] next_mode;

wire spie;
wire sptie;
wire spe;
wire modf;

reg sptef;
reg spif;
wire wr_enb;
wire rd_enb;

reg [7:0] spi_cr_1;
reg [7:0] spi_cr_2;
reg [7:0] spi_br;
reg [7:0] spi_sr;
reg [7:0] spi_dr;

always @(posedge pclk or negedge preset_n)
begin
    if (!preset_n)
        state <= idle;
    else
        state <= next_state;
end

always @(*)
begin
    case (state)
        idle:
        begin
            if (psel_i && !penable_i)
                next_state = setup;
            else
                next_state = idle;
        end

        setup:
        begin
            if (psel_i && penable_i)
                next_state = enable;
            else if (psel_i && !penable_i)
                next_state = setup;
            else
                next_state = idle;
        end

        enable:
        begin
            if (psel_i)
                next_state = setup;
            else
                next_state = idle;
        end

        default: next_state = idle;
    endcase
end

assign pready_o = (state == enable) ? 1'b1 : 1'b0;
assign pslverr_o = (state == enable) ? ~tip_i : 1'b0;

assign wr_enb = pwrite_i && (state == enable);
assign rd_enb = !pwrite_i && (state == enable);

always @(posedge pclk or negedge preset_n)
begin
    if (!preset_n)
    begin
        spi_cr_1   <= 8'b0000_0100;
        spi_cr_2   <= 8'b0000_0000;
        spi_br     <= 8'b0000_0000;
        spi_dr     <= 8'b0000_0000;
        data_mosi_o<=8'b0000_0000;
        send_data_o <= 1'b0;
    end
    else if (wr_enb)
    begin
        case (paddr_i)
            3'b000: spi_cr_1 <= pwdata_i;
            3'b001: spi_cr_2 <= (pwdata_i & cr2_mask);
            3'b010: spi_br   <= (pwdata_i & br_mask);
            3'b101: spi_dr   <= pwdata_i;
            default: spi_dr  <= pwdata_i;
        endcase
    end
    else if (((spi_dr == pwdata_i) &&
              (spi_dr != data_miso_i)) &&
             (spi_mode_o == spi_run || spi_mode_o == spi_wait))
    begin
        send_data_o <= 1'b1;
        data_mosi_o <= spi_dr;
        spi_dr      <= 8'b0;
    end
    else if (receive_data_i &&
             (spi_mode_o == spi_run || spi_mode_o == spi_wait))
    begin
        spi_dr      <= data_miso_i;
        send_data_o <= 1'b0;
    end
    else
    begin
        send_data_o <= 1'b0;
    end
end

always @(*)
begin
    if (rd_enb)
    begin
        case (paddr_i)
            3'b000: prdata_i = spi_cr_1;
            3'b001: prdata_i = spi_cr_2;
            3'b010: prdata_i = spi_br;
            3'b011: prdata_i = spi_sr;
            3'b101: prdata_i = spi_dr;
            default: prdata_i = 8'b0;
        endcase
    end
    else
        prdata_i = 8'b0;
end

assign mstr_o  = spi_cr_1[4];
assign cpol_o  = spi_cr_1[3];
assign cpha_o  = spi_cr_1[2];
assign ssoe    = spi_cr_1[1];
assign lsbfe_o = spi_cr_1[0];

assign spie  = spi_cr_1[7];
assign spe   = spi_cr_1[6];
assign sptie = spi_cr_1[5];

assign modfen_o    = spi_cr_2[4];
assign spiswai_o = spi_cr_2[1];

assign sppr_o = spi_br[6:4];
assign spr_o  = spi_br[2:0];

assign modf = ((!ss_i) && mstr_o && modfen_o && (!ssoe));

assign spi_interrupt_request_o =
    (!spie && !sptie) ? 1'b0 :
    (spie && !sptie)  ? (spif || modf) :
    (!spie && sptie)  ? sptef :
                        (spif || sptef || modf);

always @(posedge pclk or negedge preset_n)
begin
    if (!preset_n)
        spi_mode_o <= spi_run;
    else
        spi_mode_o <= next_mode;
end

always @(*)
begin
    case (spi_mode_o)
        spi_run:
        begin
            if (!spe)
                next_mode = spi_wait;
            else
                next_mode = spi_run;
        end

        spi_wait:
        begin
            if (spe)
                next_mode = spi_run;
            else if (spiswai_o)
                next_mode = spi_stop;
            else
                next_mode = spi_wait;
        end

        spi_stop:
        begin
            if (spe)
                next_mode = spi_run;
            else if (!spiswai_o)
                next_mode = spi_wait;
            else
                next_mode = spi_stop;
        end

        default: next_mode = spi_run;
    endcase
end

always @(*)
begin
    if (!preset_n)
    begin
        spi_sr = 8'b0010_0000;
        sptef  = 1'b1;  
        spif   = 1'b0;   
    end
    else
    begin
        if (spi_dr == 8'b0000_0000)
            sptef = 1'b1;
        else
            sptef = 1'b0;

        if (spi_dr != 8'b0000_0000)
            spif = 1'b1;
        else
            spif = 1'b0;

        spi_sr = {spif, 1'b0, sptef, modf, 4'b0};
    end
end

endmodule
