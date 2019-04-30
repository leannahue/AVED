library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

use work.constants.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity hysteresis_img_tb is

end hysteresis_img_tb;


architecture tb of hysteresis_img_tb is

component hysteresis_filter is
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
end component hysteresis_filter;

	constant IM_SIZE	: integer := IMG_WIDTH*IMG_HEIGHT;

	signal clock		: std_logic;
	signal reset		: std_logic;
	signal clock_div3	: std_logic;
	signal div_cnt	        : integer;

	-- Outputs from NMS
	signal Gmag_ready	: std_logic;
	signal Gmag_in		: std_logic_vector (MAG_WIDTH - 1 downto 0);

	-- Hysteresis outputs
	signal	hyst_ready	: std_logic;
	signal	hyst_pixel	: std_logic_vector (MAG_WIDTH - 1 downto 0);

	-- Input Image
	type t_char_file is file of character;
	type t_byte_arr is array (natural range <>) of bit_vector(7 downto 0);
        type t_char_arr is array (1079 downto 0) of character;
	file Gmag_in_file	: t_char_file open read_mode is "./stage3_nonmax_suppression.bmp";
	file hyst_exp_file	: t_char_file open read_mode is "./stage4_hysteresis.bmp";

	file fp_hyst_out	: text open write_mode is "hyst.out";
	file fp_hyst_bmp	: t_char_file open write_mode is "hysteresis_filter.bmp";

	signal hyst_rd_en   	: std_logic;

	signal pixel_count	: integer := 0;
	signal hyst_count	: integer := 0;

	-- BMP signals
	signal bmp_not_ready	: std_logic;
	signal bmp_not_ready_d1	: std_logic;
	signal bmp_header_count	: integer;
	signal bmp_header	: character;
	signal bmp_header_array	: t_char_arr;
	signal bmp_header_int	: integer;

	-- Hysteresis outputs
	signal hyst_exp_int	: integer;
	signal hyst_int_d1	: integer;
	signal hyst_err_cnt	: integer;

	signal hyst_done	: std_logic;

begin

	reset_init : process
	begin
		reset <= '1';
		for i in 0 to 10 loop
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

	clk_div3 : process(clock,reset)
	begin
		if (reset = '1') then
			clock_div3 <= '0';
			div_cnt    <= 0;
		elsif (rising_edge(clock)) then
			if (div_cnt = 2) then
				div_cnt    <= 0;
				clock_div3 <= '0';
			else
				div_cnt <= div_cnt+1;
				clock_div3 <= '1';
			end if;
		end if;
	end process clk_div3;

	-- BMP file : 720x720x3 (data is repeated 3 times)
	-- Input
 	gen_vec: process(clock,reset) is
		variable char_buf	: character;
		variable my_line	: line;
		variable Gmag_in_int	: integer;
		variable gmag_in_eof	: integer := 0;
	begin
	if (reset = '1') then
  		Gmag_in <= (others => '0');
		bmp_not_ready  <= '1';
		bmp_not_ready_d1 <= '1';
		bmp_header_count <= 0;
		bmp_header <= 'A';
		bmp_header_int <= 0;
	elsif (falling_edge(clock)) then
		if (not endfile(Gmag_in_file)) then
			bmp_not_ready_d1 <= bmp_not_ready;
			read(Gmag_in_file,char_buf);
			if (Gmag_ready = '0') then
				bmp_header <= char_buf;
				bmp_header_int <= character'pos(bmp_header);  -- character to integer conversion
				bmp_header_array(bmp_header_count) <= char_buf;
				if (bmp_header_count = (BMP_HEADER_CNT - 6)) then  -- lineup
					bmp_not_ready <= '0';
				else
					bmp_not_ready <= '1';
					bmp_header_count <= bmp_header_count + 1;
				end if;
			else
				Gmag_in_int := character'pos(char_buf);  -- character to integer conversion
				Gmag_in <= conv_std_logic_vector(Gmag_in_int, MAG_WIDTH);
				pixel_count <= pixel_count + 1;
			end if; -- Gmag_ready
		else
			if (gmag_in_eof = 0) then
				write(my_line, string'(" ... End of Input File ... "));
				writeline(output, my_line);  -- write to stdout
				gmag_in_eof := 1;
			end if;
		end if; -- end of file
	end if; -- clock edge
	end process;

	-- Instantiations
	hyst_inst : hysteresis_filter
		port map (
			clock		=> clock_div3,
			reset		=> reset,
			in_rd_en	=> Gmag_ready,
			in_empty	=> bmp_not_ready,
			in_dout		=> Gmag_in,
			out_wr_en	=> hyst_ready,
			out_full	=> '0',
			out_din		=> hyst_pixel
			);

	-- Outputs
	canny_output : process(clock,reset)
		variable hyst_line	: line;
		variable hyst_line2	: line;
		variable hyst_int	: integer;
		variable hyst_char	: character;
		variable wait_cnt	: integer := 0;
		variable hyst_exp_char  : character;
		variable hyst_bmp_eof	: integer := 0;
	begin
		if (reset = '1') then
			wait_cnt := wait_cnt  + 1;
			hyst_exp_int <= 0;
			hyst_err_cnt <= 0;
			hyst_int_d1 <= 0;
			hyst_done <= '0';
		elsif (rising_edge(clock)) then
			if (Gmag_ready = '0') and (hyst_count < 100) then
				write(fp_hyst_bmp, bmp_header);
				read(hyst_exp_file, hyst_exp_char);  -- remove the headers of hysterisis output
			end if;

			if (hyst_ready = '1')then
				hyst_int := conv_integer(ieee.std_logic_arith.unsigned(hyst_pixel));
                                hyst_char := character'val(hyst_int);
                                if (not endfile(hyst_exp_file)) then
                                  read(hyst_exp_file, hyst_exp_char);   -- read hysterisis output
	                          hyst_exp_int  <= character'pos(hyst_exp_char);  -- character to integer conversion
                                  hyst_int_d1  <= hyst_int;

                                  -- Compare
                                  if (hyst_int_d1 /= hyst_exp_int) then
                                    write(hyst_line2, string'("... Hysterisis ERROR : Expected = "));
                                    write(hyst_line2, hyst_exp_int);
                                    write(hyst_line2, string'("... Actual = "));
                                    write(hyst_line2, hyst_int_d1);
                                    write(hyst_line2, string'("... hyst_count = "));
                                    write(hyst_line2, hyst_count);
                                    writeline(output, hyst_line2);
                                    hyst_err_cnt  <= hyst_err_cnt + 1;
                                  end if;
                                else
                                   if (hyst_bmp_eof = 0) then
 		                       write(hyst_line2, string'(" ... Hysterisis end of compare file. Compare done ... "));
 		                       writeline(output, hyst_line2);  -- write to stdout
                                       hyst_bmp_eof := 1;
                                   end if;
                                end if; -- end of compare file

                                if (hyst_count < IM_SIZE*3) then
				   write(hyst_line, hyst_int);
				   writeline(fp_hyst_out, hyst_line);
				   write(fp_hyst_bmp, hyst_char);
                                   hyst_count    <= hyst_count + 1;
                                else
                                  if (hyst_done = '0') then
                                      file_close(fp_hyst_out);
					file_close(fp_hyst_bmp);
                                      hyst_done <= '1';
                                      if (hyst_err_cnt /= 0) then
					write(hyst_line2, string'("... HYSTERISIS SIM FAILED: OUTPUTS DO NOT MATCH ..."));
                                      else
					write(hyst_line2, string'("... HYSTERISIS SIM PASSED ..."));
                                      end if;
                                      writeline(output, hyst_line2);
					assert false report "... SIMULATION DONE ..." severity failure;
                                  end if; -- hyst_done
                                end if;

			end if;         -- hyst_ready

		end if; -- rising_edge clock
	end process canny_output;

end tb;
