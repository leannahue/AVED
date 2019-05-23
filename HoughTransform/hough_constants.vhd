library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

package hough_constants is

	constant IMG_WIDTH	: natural := 720;
	constant IMG_HEIGHT	: natural := 720;
	constant IMG_SIZE	: natural := IMG_WIDTH*IMG_HEIGHT;
	constant MAG_WIDTH	: natural := 8;
	constant RHO_WIDTH	: natural := 10;
	constant THETA_WIDTH	: natural := 8;

	constant ACCU_WIDTH	: natural := 180;
	constant ACCU_HEIGHT	: natural := 1018;  -- sqrt(2)*IMG_WIDTH + sqrt(2)*IMG_HEIGHT

	constant ACCU_THRESHOLD : natural := 110;

component hough_threshold is
	port (
		signal clock		: in std_logic;
		signal reset		: in std_logic;
		signal in_rd_en		: out std_logic;
		signal in_empty		: in std_logic;
		signal in_dout		: in std_logic_vector (MAG_WIDTH - 1 downto 0); -- accumulator input
		signal out_wr_en	: out std_logic;
		signal out_full		: in std_logic;
		signal out_rho	        : out std_logic_vector (RHO_WIDTH - 1 downto 0);
		signal out_theta	: out std_logic_vector (THETA_WIDTH - 1 downto 0)
		);
end component hough_threshold;

end package;
