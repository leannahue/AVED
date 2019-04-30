library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

package constants is

	constant IMG_WIDTH	: natural := 720;
	constant IMG_HEIGHT	: natural := 720;
	constant MAG_WIDTH	: natural := 8;

	constant FIFO_D_WIDTH	: natural := 8;
	constant FIFO_BUFF_SIZE	: natural := 256;

	constant BMP_HEADER_CNT : natural := 60;

component fifo is
generic
(
	constant FIFO_DATA_WIDTH : integer := FIFO_D_WIDTH;
	constant FIFO_BUFFER_SIZE : integer := FIFO_BUFF_SIZE
);
port
(
	signal rd_clk : in std_logic;
	signal wr_clk : in std_logic;
	signal reset : in std_logic;
	signal rd_en : in std_logic;
	signal wr_en : in std_logic;
	signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal full : out std_logic;
	signal empty : out std_logic
);
end component fifo;

	component grayscale is
	port
	(
		signal clock        : in  std_logic;
		signal reset        : in  std_logic;
		signal in_rd_en     : out std_logic;
		signal in_empty     : in  std_logic;
		signal in_dout      : in  std_logic_vector(23 downto 0);
		signal out_wr_en	: out std_logic;
		signal out_full     : in  std_logic;
		signal out_din      : out std_logic_vector(7 downto 0)
	);
	end component;

	component sobel is
	generic
	(
		constant WIDTH      : integer:= IMG_WIDTH;
		constant HEIGHT     : integer:= IMG_HEIGHT
	);
	port
	(
		signal clock        : in  std_logic;
		signal reset        : in  std_logic;
		signal in_rd_en     : out std_logic;
		signal in_empty     : in  std_logic;
		signal in_dout      : in  std_logic_vector(7 downto 0);
		signal out_wr_en	: out std_logic;
		signal out_full     : in  std_logic;
		signal out_din      : out std_logic_vector(7 downto 0)
	);
	end component sobel;

component Gaussian is
generic
(
	constant WIDTH_P     : integer:= IMG_WIDTH+4;
	constant HEIGHT      : integer:= IMG_HEIGHT+4
	--constant WIDTH_P     : integer:= 724;
	--constant HEIGHT      : integer:= 544
);
port
(
	signal clock         : in  std_logic;
    	signal reset         : in  std_logic;
	signal in_rd_en      : out std_logic;
	signal in_empty      : in  std_logic;
	signal in_dout       : in  std_logic_vector(MAG_WIDTH - 1 downto 0);
	signal out_wr_en     : out std_logic;
	signal out_full      : in  std_logic;
	signal out_din       : out std_logic_vector(MAG_WIDTH - 1 downto 0)
);
end component Gaussian;

component non_maximum_suppression is
	port (
		signal clock		: in std_logic;
		signal reset		: in std_logic;
		signal in_rd_en		: out std_logic;
		signal in_empty		: in std_logic;
		signal in_dout		: in std_logic_vector (MAG_WIDTH - 1 downto 0);
		signal out_wr_en	: out std_logic;
		signal out_full		: in std_logic;
		signal out_din		: out std_logic_vector (MAG_WIDTH - 1 downto 0)
		);
end component non_maximum_suppression;

component hysteresis is
generic
(
	constant WIDTH      : integer:= IMG_WIDTH;
	constant HEIGHT     : integer:= IMG_HEIGHT
);
port
(
	signal clock        : in  std_logic;
    signal reset        : in  std_logic;
	signal in_rd_en     : out std_logic;
	signal in_empty     : in  std_logic;
	signal in_dout      : in  std_logic_vector(MAG_WIDTH - 1 downto 0);
	signal out_wr_en	: out std_logic;
	signal out_full     : in  std_logic;
	signal out_din      : out std_logic_vector(MAG_WIDTH - 1 downto 0)
);
end component hysteresis;

component AVED_top is
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
end component AVED_top;


end package;
