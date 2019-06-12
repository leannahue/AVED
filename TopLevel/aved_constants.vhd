library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.canny_constants.all;
use work.hough_constants.all;

package aved_constants is

  constant IMG_WIDTH      : natural := 216;
  constant IMG_HEIGHT     : natural := 216;
  constant IMG_SIZE       : natural := IMG_WIDTH*IMG_HEIGHT;

  component aved_top is
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
  end component aved_top;

  component Canny_Edge_top is
  generic
  (
      constant WIDTH   : integer:= IMG_WIDTH;
      constant HEIGHT  : integer:= IMG_HEIGHT
  );
  port
  (
  	signal clock     : in std_logic;
  	signal reset     : in std_logic;
  	signal in_full   : out std_logic;
  	signal in_wr_en  : in std_logic;
  	signal in_din    : in std_logic_vector (23 downto 0);
  	signal out_rd_en : in std_logic;
  	signal out_empty : out std_logic;
  	signal out_dout  : out std_logic_vector (7 downto 0)
  );
  end component Canny_Edge_top;

  component hough_top is
		generic (
			constant WIDTH   : integer:= IMG_WIDTH;
			constant HEIGHT  : integer:= IMG_HEIGHT
		);
		port (
			signal clock     : in std_logic;
			signal reset     : in std_logic;
			signal canny_out_empty  : in std_logic;
			signal in_din    : in std_logic_vector (7 downto 0);
			signal out_rd_en : in std_logic;
			signal in_rd_en  : out std_logic;
			signal out_empty : out std_logic;
			signal out_dout  : out std_logic_vector (7 downto 0);
			-- HDMI Interface
			signal vsync	        : out std_logic; -- 0: output data not valid; 1: valid output
			signal hsync	        : out std_logic; -- 0: output data not valid; 1: valid output
			signal hdmi_de 	        : out std_logic; -- Data Enable
			signal hdmi_dout        : out std_logic_vector (23 downto 0);
			signal hdmi_clk         : out std_logic  -- Max clock freq 165Mhz
		);
	end component hough_top;


end package;
