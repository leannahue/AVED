library IEEE;
use IEEE.std_logic_1164.all;
-- use ieee.std_logic_arith.all;
use IEEE.numeric_std.all;
-- use IEEE.numeric_std_unsigned;
use work.hough_constants.all;

entity draw_lines is
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
end entity draw_lines;

architecture behavioral of draw_lines is

	type state_types is (IDLE,STORE_IMAGE,WAIT_XY,DRAW_XY,READ_IMAGE);
	signal draw_state      : state_types;
	signal draw_next_state : state_types;

	signal img_write_en    : std_logic;
	signal drawline_en     : std_logic;

	signal draw_pixel      : std_logic;
	signal drawline_wr_en  : std_logic;
	signal ram_wr_en       : std_logic;
	signal ram_wr_data     : std_logic_vector (7 downto 0);
	signal drawline_data   : std_logic_vector (7 downto 0);

	signal img_write_addr  : natural range 0 to 2**20-1;

	signal img_write_addr_nxt  : natural range 0 to 2**20-1;

	signal x1_lat       : std_logic_vector (9 downto 0);
	signal x2_lat       : std_logic_vector (9 downto 0);
	signal y1_lat       : std_logic_vector (9 downto 0);
	signal y2_lat       : std_logic_vector (9 downto 0);


	signal pixel_x         : natural range 0 to 2**10-1;
	signal pixel_y         : natural range 0 to 2**10-1;
	signal next_pixel_x    : natural range 0 to 2**10-1;
	signal yy              : natural range 0 to 2**20-1;
	signal next_yy         : natural range 0 to 2**20-1;

	signal drawline_addr   : natural range 0 to 2**20-1;
	signal drawline_done   : std_logic;


	-- Slope signals
	signal x_direction : std_logic;
	signal y_direction : std_logic;

	signal slope       : integer := 0;
	signal start_x     : integer := 0;
	signal end_x       : integer := 1;
	signal start_y     : integer := 0;
	signal end_y       : integer := 1;

	-- xy data store in FIFO
	signal xy_data_in      : std_logic_vector (XY_D_WIDTH-1 downto 0);
	signal fifo_rd_en      : std_logic;

begin

	xy_data_in   <= y2 & y1 & x2 & x1;

	drawline_data <=  "11111100" when (drawline_en = '1') else "00000000";
	ram_wr_data   <= in_dout when (img_write_en = '1') else drawline_data;  --line_pixel_value=252 (white line)
	ram_wr_en     <= img_write_en or draw_pixel;  -- To line up with starting write address, not '0' same as c code
	out_din       <= ram_wr_data;
	out_wr_en     <= ram_wr_en;

	-- Slope signals
	start_x    <= to_integer(unsigned(x1_lat));
	end_x      <= to_integer(unsigned(x2_lat));
	start_y    <= to_integer(unsigned(y1_lat));
	end_y      <= to_integer(unsigned(y2_lat));

	draw_next_proc: process (draw_state,xy_in_empty,in_empty,img_write_addr,drawline_addr,drawline_done,xy_done,out_full,accumulator_rd_en)
	begin

		draw_next_state    <= draw_state;
		in_rd_en           <= '0';
		img_write_en       <= '0';
		drawline_en        <= '0';
		draw_pixel         <= '0';
		img_write_addr_nxt <= img_write_addr;
		fifo_rd_en         <= '0';

		case draw_state is
			when IDLE =>
				draw_next_state <= STORE_IMAGE;  -- Need to lineup with Hough xy counters

			when STORE_IMAGE =>           -- output original hystersis output
				if (in_empty = '0') and (out_full = '0' and accumulator_rd_en = '1') then
					img_write_addr_nxt <= img_write_addr + 1;
					img_write_en       <= '1';
				end if;
				if (img_write_addr = IMG_SIZE-1) then
					draw_next_state  <= WAIT_XY;
				end if;
			when WAIT_XY =>
				img_write_addr_nxt <= 0;
				if (xy_in_empty = '0') then
					draw_next_state  <= DRAW_XY;
					fifo_rd_en       <= '1';
					in_rd_en         <= '1';
				elsif (xy_done = '1') then       -- Done drawing all lines
					draw_next_state  <= IDLE;
				end if;
			when DRAW_XY =>               -- output the lines, one frame per line
				if (out_full = '0') then
					draw_pixel         <= '1';
					img_write_addr_nxt <= img_write_addr + 1;
					if (drawline_done = '1') then
						drawline_en        <= '0';
					else
						if (img_write_addr = drawline_addr) then
							drawline_en        <= '1';
						end if;
					end if;
					if (img_write_addr = IMG_SIZE-1) then
						draw_next_state <= WAIT_XY;
					end if;
				end if;
			when others =>
				draw_next_state <= IDLE;
		end case;
	end process;

	xy_line_process : process (start_x,end_x,start_y,end_y,slope,pixel_x,pixel_y,yy,next_yy,y_direction,x_direction)
		variable delta_x     : integer := 1;
		variable delta_y     : integer := 0;
	begin

		-- slope
		if (start_x > end_x) then
			delta_x      :=  start_x - end_x;
			x_direction  <=  '1';           -- decrement
		else
			delta_x      :=  end_x - start_x;
			x_direction  <=  '0';           -- increment
		end if;

		if (start_y > end_y) then
			delta_y      :=  start_y - end_y;
			y_direction  <=  '1';           -- decrement
		else
			delta_y      :=  end_y - start_y;
			y_direction  <=  '0';           -- increment
		end if;

		if (delta_x = 0) then
			slope          <= 256;       -- avoid decide by 0
		else
			slope          <= ((delta_y*256)/delta_x);
		end if;

		-- Draw the lines
		-- project the liens on original image
		-- for y = start_y; y<end_y; y=y+slope
		if (y_direction = '1') then
			next_yy  <= yy - slope;
		else
			next_yy  <= yy + slope;
		end if;

		pixel_y  <= next_yy/256;
		if (x_direction = '1') then
			next_pixel_x <= pixel_x - 1;
		else
			next_pixel_x <= pixel_x + 1;
		end if;
		drawline_addr    <= (pixel_y*IMG_WIDTH) + pixel_x;

		-- stop drawline when y_pixel is at end_y
		drawline_done <= '0';
		if (y_direction = '1') then
			if (pixel_y <= end_y) then  -- decrement y
				drawline_done  <= '1';
			end if;
		else
			if (pixel_y >= end_y) then  -- increment y
				drawline_done  <= '1';
			end if;
		end if;

	end process;

	data_cntrl : process(clock, reset)
	begin
		if (reset = '1') then
			img_write_addr    <= 0;
			pixel_x           <= 0;
			yy                <= 0;
			x1_lat            <= (others => '0');
			x2_lat            <= "0000000001";
			y1_lat            <= (others => '0');
			y2_lat            <= "0000000001";  -- 10 bits
			draw_state        <= IDLE;
			drawline_wr_en    <= '0';

		elsif (rising_edge(clock)) then
			draw_state      <= draw_next_state;
			img_write_addr  <= img_write_addr_nxt;
			drawline_wr_en  <= drawline_en;
			if (fifo_rd_en = '1') then
				x1_lat     <= xy_data_in(RHO_WIDTH-1 downto 0);
				x2_lat     <= xy_data_in(2*RHO_WIDTH-1 downto RHO_WIDTH);
				y1_lat     <= xy_data_in(XY_D_WIDTH-RHO_WIDTH-1 downto XY_D_WIDTH-2*RHO_WIDTH);
				y2_lat     <= xy_data_in(XY_D_WIDTH-1 downto XY_D_WIDTH-RHO_WIDTH);
				pixel_x    <= to_integer(unsigned(xy_data_in(RHO_WIDTH-1 downto 0)));  -- starting x pixels
				yy         <= to_integer(unsigned(xy_data_in(XY_D_WIDTH-RHO_WIDTH-1 downto XY_D_WIDTH-2*RHO_WIDTH)));  -- starting y pixels
			elsif (draw_state = DRAW_XY) and (drawline_en = '1') then
				pixel_x    <=  next_pixel_x;
				yy         <=  next_yy;
			end if;
		end if;
	end process;

end architecture;
