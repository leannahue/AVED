-- For 5x5 image, run 800 ns
-- For 10x10 image, run 2.4 us
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.canny_constants.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity non_maximum_suppression_tb is

end non_maximum_suppression_tb;


architecture tb of non_maximum_suppression_tb is

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

	signal clock		: std_logic;
	signal reset		: std_logic;

	-- Outputs from Sobel
	signal Gmag_ready	: std_logic;
	signal Gmag_in		: std_logic_vector (MAG_WIDTH - 1 downto 0);

	-- Non-max suppression outputs
	signal nmax_supp_ready	: std_logic;
	signal nmax_supp_pixel	: std_logic_vector (MAG_WIDTH-1 downto 0);

	file Gmag_in_file	: text open read_mode is "./Gmag.txt";

	file nmax_out		: text open write_mode is "nmax.out";

begin

	reset_init : process
	begin
		reset <= '1';
		for i in 0 to 2 loop
			wait until rising_edge(clock);
		end loop;
		reset <= '0';
		wait;
	end process;

	clock_gen : process
	begin
		clock <= transport '1';
		wait for 10 ns;
		clock <= transport '0';
		wait for 10 ns;
	end process clock_gen;
        
 	gen_vec: process(clock,reset) is
		variable my_line	: line;
		variable Gmag_in_int	: integer;
	begin
		if (reset = '1') then
			Gmag_in <= (others => '0');
		elsif (falling_edge(clock)) then
			if (Gmag_ready = '1') then
				readline(Gmag_in_file, my_line);
				read(my_line,Gmag_in_int);
				Gmag_in <= conv_std_logic_vector(Gmag_in_int,MAG_WIDTH);
			end if;
		end if;
	end process;


	-- Instantiations
	non_max_supp_inst : non_maximum_suppression
		port map (
			clock   => clock,
			reset  	=> reset,
			in_rd_en => Gmag_ready,
			in_empty  => '0',
			in_dout   => Gmag_in,
			out_wr_en => nmax_supp_ready,
			out_full => '0',
			out_din => nmax_supp_pixel
			);

	-- Outputs
	nmax_output : process(clock)
		variable my_line : line;
		variable nmax_supp_out_int : integer;
	begin
		if (rising_edge(clock)) then
			if (nmax_supp_ready='1') then
				nmax_supp_out_int := conv_integer(ieee.std_logic_arith.unsigned(nmax_supp_pixel));
				write(my_line,nmax_supp_out_int);
				writeline(nmax_out,my_line);
			end if;
		end if; -- rising_edge clock
	end process nmax_output;

end tb;	-- architecture
