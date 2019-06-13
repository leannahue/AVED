library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.aved_constants.all;

entity aved_top is
  port (
    signal clock     : in std_logic;
    signal reset     : in std_logic;
    signal in_wr_en  : in std_logic;
    signal in_din    : in std_logic_vector (23 downto 0);
    signal out_rd_en : in std_logic;
    signal in_full   : out std_logic;
    signal out_empty : out std_logic;
    signal out_dout  : out std_logic_vector (7 downto 0);

    -- HDMI Interface
    signal vsync	        : out std_logic; -- 0: output data not valid; 1: valid output
    signal hsync	        : out std_logic; -- 0: output data not valid; 1: valid output
    signal hdmi_de 	        : out std_logic; -- Data Enable
    signal hdmi_dout        : out std_logic_vector (23 downto 0);
    signal hdmi_clk         : out std_logic  -- Max clock freq 165Mhz
  );
end entity aved_top;


architecture behavior of aved_top is

  signal canny_rd_en         : std_logic;
  signal canny_out_dout      : std_logic_vector(7 downto 0);
  signal canny_out_empty     : std_logic;
  signal hough_wr_en         : std_logic;
  signal hough_in_full       : std_logic;

  signal in_fifo_empty     : std_logic;
  signal in_fifo_rd_en     : std_logic;  -- Read enable from grayscale
  signal in_fifo_dout      : std_logic_vector(23 downto 0);

begin

  edge_detect_inst : component Canny_Edge_top
  port map (
    clock       => clock,
    reset       => reset,
    in_wr_en    => in_wr_en,          -- input
    in_din      => in_din,            -- input [23:0]
    out_rd_en   => canny_rd_en,       -- input
    in_fifo_empty  => in_fifo_empty,  -- output
    in_fifo_rd_en  => in_fifo_rd_en,  -- output
    in_fifo_dout   => in_fifo_dout,
    in_full     => in_full,
    out_empty   => canny_out_empty,   -- output
    out_dout    => canny_out_dout     -- output
  );



  Hough_top_inst : component hough_top
  generic map (
    WIDTH         => IMG_WIDTH,
    HEIGHT        => IMG_HEIGHT
  )
  port map (
    clock       => clock,
    reset       => reset,
    canny_out_empty  => canny_out_empty,
    in_din      => canny_out_dout,
    out_rd_en   => out_rd_en,       -- block input, goes to output FIFO
    in_fifo_empty  => in_fifo_empty,  -- input
    in_fifo_rd_en  => in_fifo_rd_en,  -- input
    in_fifo_dout   => in_fifo_dout,
    in_rd_en    => canny_rd_en,   -- block outputs
    out_empty   => out_empty,
    out_dout    => out_dout,
    -- HDMI Interface
    vsync         => vsync,
    hsync         => hsync,
    hdmi_de       => hdmi_de,
    hdmi_dout     => hdmi_dout,
    hdmi_clk      => hdmi_clk
  );


end architecture behavior;
