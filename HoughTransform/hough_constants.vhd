library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

package hough_constants is

-- Quantize 14 bits

	-- constant IMG_WIDTH			: natural := 720;
	-- constant IMG_HEIGHT			: natural := 720;
	constant IMG_WIDTH			: natural := 216;
	constant IMG_HEIGHT			: natural := 216;
	constant IMG_SIZE				: natural := IMG_WIDTH*IMG_HEIGHT;
	constant MAG_WIDTH			: natural := 8;
	constant RHO_WIDTH			: natural := 10;
	constant THETA_WIDTH		: natural := 8;

	constant W_div2         : integer := IMG_WIDTH / 2;
	constant H_div2         : integer := IMG_HEIGHT / 2; --sqrt(2)*720

	constant ACCU_WIDTH			: natural := 180;
	-- constant ACCU_HEIGHT		: natural := 1018;  -- sqrt(2)*IMG_WIDTH + sqrt(2)*IMG_HEIGHT
	constant ACCU_HEIGHT		: natural := 305;

	constant ACCU_h_div2    : integer := ACCU_HEIGHT / 2;

	-- int hough_h = sqrt2_quant * ((height > width? height : width) / 2.0);
	-- constant HOUGH_H				: natural := 509*2**14;
	constant HOUGH_H				: natural := ACCU_HEIGHT*2**13;

	constant IMG_THRESHOLD  : natural := 70;
	constant ACCU_THRESHOLD : natural := 110;

	constant PI_div_180  		: integer := 1143;  -- PI/180*2^16

	constant XY_D_WIDTH	: natural := RHO_WIDTH*4;  -- x1,x2,y1,y2
	constant XY_BUFF_SIZE	: natural := 32;

	constant FIFO_D_WIDTH	: natural := 8;
	constant FIFO_BUFF_SIZE	: natural := 32;

	-- Cordic Constants
	constant N_STAGES : integer := 16;
	constant DATA_LENGTH : integer := 721;
	constant K : std_logic_vector (31 downto 0) := x"000026dd";
	constant PI : integer := 51472;
	constant NEG_PI : integer := -51472;
	constant TWO_PI : integer := 102944;
	constant PI_OVER_TWO : integer := 25736;
	constant NEG_PI_OVER_TWO : integer := -25736;

	-- Main components

	component hough_top is
		generic (
		    constant WIDTH   : integer:= IMG_WIDTH;
		    constant HEIGHT  : integer:= IMG_HEIGHT
		);
		port (
			signal clock     : in std_logic;
			signal reset     : in std_logic;
			signal in_full   : out std_logic;
			signal in_wr_en  : in std_logic;
			signal in_din    : in std_logic_vector (7 downto 0);
			signal out_rd_en : in std_logic;
			signal out_empty : out std_logic;
			signal out_dout  : out std_logic_vector (7 downto 0)
		);
	end component hough_top;

	-- ACCUMULATOR GOES HERE

	component threshold is
	  port (
	    signal clock	       	: in std_logic;
	    signal reset	       	: in std_logic;
	    signal in_rd_en	    	: out std_logic;
	    signal in_empty		    : in std_logic;
	    signal out_full		    : in std_logic;
	    signal in_dout	     	: in std_logic_vector (MAG_WIDTH - 1 downto 0); -- accumulator input
	    signal out_wr_en     	: out std_logic;  -- '1' when out_rho and out_theta are valid
	    signal out_rho_done	  : out std_logic;  -- rho/theta calculation done
	    signal out_rho	      : out std_logic_vector (RHO_WIDTH - 1 downto 0);
	    signal out_theta	    : out std_logic_vector (THETA_WIDTH - 1 downto 0)
	  );
	end component threshold;

	component finite_lines is
	  port (
		  signal clock         : in  std_logic;
		  signal reset         : in  std_logic;
		  signal in_empty      : in  std_logic;
		  signal out_full      : in  std_logic;
		  signal in_rho        : in  std_logic_vector (RHO_WIDTH-1  downto 0);
		  signal in_theta      : in  std_logic_vector (7 downto 0);
		  signal in_rho_done   : in  std_logic;
		  signal in_rd_en      : out std_logic;
		  signal out_wr_en     : out std_logic;
		  signal out_xy_done   : out std_logic;
		  signal x1            : out std_logic_vector (RHO_WIDTH-1 downto 0);
		  signal x2            : out std_logic_vector (RHO_WIDTH-1  downto 0);
		  signal y1            : out std_logic_vector (RHO_WIDTH-1  downto 0);
		  signal y2            : out std_logic_vector (RHO_WIDTH-1  downto 0)
	  );
	end component finite_lines;

	component draw_lines is
		port (
			signal clock			 			     	: in std_logic;
			signal reset			 			     	: in std_logic;
			signal x1   	     			      : in std_logic_vector (RHO_WIDTH - 1 downto 0);
			signal x2 	       			      : in std_logic_vector (RHO_WIDTH - 1 downto 0);
			signal y1	        			      : in std_logic_vector (RHO_WIDTH - 1 downto 0);
			signal y2        			      	: in std_logic_vector (RHO_WIDTH - 1 downto 0);
			signal xy_in_empty				    : in std_logic;  -- 0: input data available; 1: no data available
			signal xy_done					      : in std_logic;  -- xy coordinates calculation done, all lines have been calculated.
			signal in_rd_en					      : out std_logic; -- 0: not ready to read, 1: read enable
			signal in_empty	 				     	: in std_logic;  -- 0: input data available; 1: no data available
			signal accumulator_rd_en      : in std_logic;  -- Need to lineup with Hough block, not reading every cycle
			signal in_dout		      			: in std_logic_vector (MAG_WIDTH - 1 downto 0); -- accumulator input
			signal out_wr_en	  			    : out std_logic; -- 0: output data not valid; 1: valid output
			signal out_full		 			 	    : in std_logic;  -- 0: output buffer not full, 1: output buffer full (PAUSE)
			signal out_din	   			  	  : out std_logic_vector (MAG_WIDTH - 1 downto 0)
		);
	end component draw_lines;

	-- Supporting Components

	component cordic_stage is
	port (
		i : in integer;
		atan : in std_logic_vector (15 downto 0);
		x_i : in std_logic_vector (31 downto 0);
		y_i : in std_logic_vector (31 downto 0);
		z_i : in std_logic_vector (31 downto 0);
		x_o : out std_logic_vector (31 downto 0);
		y_o : out std_logic_vector (31 downto 0);
		z_o : out std_logic_vector (31 downto 0)
	);
	end component cordic_stage;

	component fifo is
		generic	(
			constant FIFO_DATA_WIDTH : integer := 32;
			constant FIFO_BUFFER_SIZE : integer := 16
		);
		port (
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

	component cordic is
		port (
			clock : in std_logic;
			reset : in std_logic;
			in_dout : in std_logic_vector (31 downto 0);
			in_rd_en : out std_logic;
			in_empty : in std_logic;
			out_cos_wr_en : out std_logic;
			out_cos_din : out std_logic_vector (31 downto 0);
			out_cos_full : in std_logic;
			out_sin_wr_en : out std_logic;
			out_sin_din : out std_logic_vector (31 downto 0);
			out_sin_full : in std_logic
		);
	end component cordic;

	component cos_table is
		port (
			signal theta       : in std_logic_vector (7 downto 0);
			signal cos_theta   : out std_logic_vector (15 downto 0)
		);
	end component cos_table;

	component sin_table is
		port (
			signal theta        : in std_logic_vector (7 downto 0);
			signal sin_theta    : out std_logic_vector (15 downto 0)
		);
	end component sin_table;

end package;
