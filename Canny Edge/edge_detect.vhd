library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all; 

entity edge_detect is
generic
(
    constant WIDTH   : integer:= 720;
    constant HEIGHT  : integer:= 540
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
end entity edge_detect;


architecture behavior of edge_detect is 

    -- configure the grayscale architecture
    for all : grayscale use entity work.grayscale(combinational);
    --for all : grayscale use entity work.grayscale(behavior);
		
	signal in_dout      : std_logic_vector (23 downto 0);
	signal in_empty     : std_logic;
	signal in_rd_en     : std_logic;
	
    signal out_din      : std_logic_vector (7 downto 0);
	signal out_full     : std_logic;
	signal out_wr_en    : std_logic;
    
	signal gs_dout      : std_logic_vector (7 downto 0);
	signal gs_empty     : std_logic;
	signal gs_rd_en     : std_logic;
	signal gs_din       : std_logic_vector (7 downto 0);
	signal gs_full      : std_logic;
	signal gs_wr_en     : std_logic;

begin


    grayscale_inst : component grayscale
	port map
	(
		clock       => clock,
		reset       => reset,
		in_dout     => in_dout,
		in_rd_en    => in_rd_en,
		in_empty    => in_empty,
		out_din     => gs_din,
		out_full    => gs_full,
		out_wr_en   => gs_wr_en
	);
    

	sobel_inst : component sobel
	generic map
	(
		WIDTH       => WIDTH,
        HEIGHT      => HEIGHT
	)
	port map
	(
		clock       => clock,
		reset       => reset,
		in_dout     => gs_dout,
		in_rd_en    => gs_rd_en,
		in_empty    => gs_empty,
		out_din     => out_din,
		out_full    => out_full,
		out_wr_en   => out_wr_en
	);

	in_inst : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => 256,
		FIFO_DATA_WIDTH => 24
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => in_rd_en,
		wr_en   => in_wr_en,
		din     => in_din,
		dout    => in_dout,
		full    => in_full,
		empty   => in_empty
	);

	gs_inst : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => 256,
		FIFO_DATA_WIDTH => 8
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => gs_rd_en,
		wr_en   => gs_wr_en,
		din     => gs_din,
		dout    => gs_dout,
		full    => gs_full,
		empty   => gs_empty
	);

	out_inst : component fifo
	generic map
	(
		FIFO_BUFFER_SIZE => 256,
		FIFO_DATA_WIDTH => 8
	)
	port map
	(
		rd_clk  => clock,
		wr_clk  => clock,
		reset   => reset,
		rd_en   => out_rd_en,
		wr_en   => out_wr_en,
		din     => out_din,
		dout    => out_dout,
		full    => out_full,
		empty   => out_empty
	);
	
end architecture behavior;