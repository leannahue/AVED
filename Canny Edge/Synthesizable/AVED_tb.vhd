library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.constants.all; 

entity AVED_tb is
generic
(
    constant IMG_IN_NAME  : string (18 downto 1)  := "tracks_720_720.bmp";
    constant IMG_OUT_NAME : string (10 downto 1) := "output.bmp";
    constant COMPARE_NAME : string (21 downto 1) := "stage4_hysteresis.bmp";
    constant CLOCK_PERIOD : time := 10 ns
);
end entity AVED_tb;


architecture behavior of AVED_tb is 

    function to_slv(c : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(c),8));
    end function to_slv;
    
    function to_char(v : std_logic_vector) return character is
    begin
        return character'val(to_integer(unsigned(v)));
    end function to_char;
    
    type raw_file is file of character;

    signal clock : std_logic := '1';
    signal reset : std_logic := '0';
    signal start : std_logic := '0';
    signal done : std_logic := '0';
    
	signal in_full : std_logic;
	signal in_wr_en : std_logic;
	signal in_din: std_logic_vector (23 downto 0);
	signal out_rd_en : std_logic;
	signal out_empty : std_logic;
	signal out_dout: std_logic_vector (7 downto 0);

    signal hold_clock : std_logic := '0';
    signal in_write_done : std_logic := '0';
    signal out_read_done : std_logic := '0';
    signal out_errors : integer := 0;

begin

    edge_detect_inst : component AVED_top
    generic map
    (
        WIDTH       => IMG_WIDTH,
        HEIGHT      => IMG_HEIGHT
    )
    port map
    (
        clock       => clock,
        reset       => reset,
        in_full     => in_full,
        in_wr_en    => in_wr_en,
		in_din      => in_din,
        out_rd_en   => out_rd_en,
		out_empty   => out_empty,
        out_dout    => out_dout
    );

    clock_process : process
    begin
        clock <= '1';
        wait for  (CLOCK_PERIOD / 2);
        clock <= '0';
        wait for  (CLOCK_PERIOD / 2);
        if ( hold_clock = '1' ) then
            wait;
        end if;
    end process clock_process;


    reset_process : process
    begin
        reset <= '0';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '1';
        wait until  (clock = '0');
        wait until  (clock = '1');
        reset <= '0';
        wait;
    end process reset_process;


    tb_process : process
        variable errors : integer := 0;
        variable warnings : integer := 0;
        variable start_time : time;
        variable end_time : time;
        variable ln1, ln2, ln3, ln4 : line;
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');

        wait until  (clock = '0');
        wait until  (clock = '1');

        start_time := NOW;
        write( ln1, string'("@ ") );
        write( ln1, start_time );
        write( ln1, string'(": Beginning simulation...") );
        writeline( output, ln1 );

        start <= '1';
        wait until  (clock = '0');
        wait until  (clock = '1');
        start <= '0';
        wait until  (out_read_done = '1');

        end_time := NOW;
        write( ln2, string'("@ ") );
        write( ln2, end_time );
        write( ln2, string'(": Simulation completed.") );
        writeline( output, ln2 );

        errors := out_errors;

        write( ln3, string'("Total simulation cycle count: ") );
        write( ln3, (end_time - start_time) / CLOCK_PERIOD );
        writeline( output, ln3 );
        write( ln4, string'("Total error count: ") );
        write( ln4, errors );
        writeline( output, ln4 );

        hold_clock <= '1';
        wait;
    end process tb_process;

    
    img_read_process : process 
        file in_file : raw_file;
        variable char1, char2, char3 : character;
        variable ln1 : line;
        variable i : integer := 0;
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');

        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Loading file ") );
        write( ln1, IMG_IN_NAME );
        write( ln1, string'("...") );
        writeline( output, ln1 );

        file_open( in_file, IMG_IN_NAME, read_mode );
		in_wr_en <= '0';		

        -- read header
		while ( not ENDFILE( in_file) and i < 54 ) loop
            read( in_file, char1 );
            i := i + 1;
        end loop;
        
		while ( not ENDFILE( in_file) ) loop
			wait until (clock = '1');
			wait until (clock = '0');
			if ( in_full = '0' ) then
				read( in_file, char1 );
				read( in_file, char2 );
				read( in_file, char3 );
				in_din <= to_slv( char3 ) & to_slv( char2 ) & to_slv( char1 );
				in_wr_en <= '1';
			else
				in_wr_en <= '0';
			end if;
		end loop;		

		wait until (clock = '1');
		wait until (clock = '0');
		in_wr_en <= '0';
        file_close( in_file );
        in_write_done <= '1';
        wait;
    end process img_read_process;


            
    img_write_process : process 
        file cmp_file : raw_file;
        file out_file : raw_file;
        variable char : character;
        variable ln1, ln2, ln3 : line;
        variable i : integer := 0;
        variable out_data_read : std_logic_vector (7 downto 0);
        variable out_data_cmp : std_logic_vector (7 downto 0);
    begin
        wait until  (reset = '1');
        wait until  (reset = '0');
        
        wait until  (clock = '1');
        wait until  (clock = '0');

        write( ln1, string'("@ ") );
        write( ln1, NOW );
        write( ln1, string'(": Comparing file ") );
        write( ln1, IMG_OUT_NAME );
        write( ln1, string'("...") );
        writeline( output, ln1 );

        file_open( out_file, IMG_OUT_NAME, write_mode);
        file_open( cmp_file, COMPARE_NAME, read_mode );
		out_rd_en <= '0';

		while ( not ENDFILE(cmp_file) and i < 54 ) loop
            read( cmp_file, char );
            write( out_file, char);
            i := i + 1;
        end loop;
        
        i := 0;
        
		while ( not ENDFILE(cmp_file) ) loop
			wait until ( clock = '1');
			wait until ( clock = '0');
			if ( out_empty = '0' ) then
				out_rd_en <= '1';
				read( cmp_file, char );
				read( cmp_file, char );
				read( cmp_file, char );
				out_data_cmp := to_slv(char);
                write(out_file, to_char(out_dout));
                write(out_file, to_char(out_dout));
                write(out_file, to_char(out_dout));

                -- write( ln3, string'("@ ") );
                -- write( ln3, NOW );
                -- write( ln3, string'(": ") );
                -- write( ln3, i );
                -- write( ln3, string'(": ") );
                -- hwrite( ln3, out_dout );
                -- writeline( output, ln3 );
                                
				if ( to_01(unsigned(out_dout)) /= to_01(unsigned(out_data_cmp)) ) then
					out_errors <= out_errors + 1;
					write( ln2, string'("@ ") );
					write( ln2, NOW );
					write( ln2, string'(": ") );
					write( ln2, IMG_OUT_NAME );
					write( ln2, string'("(") );
					write( ln2, i + 1 );
					write( ln2, string'("): ERROR: ") );
					hwrite( ln2, out_dout );
					write( ln2, string'(" != ") );
					hwrite( ln2, out_data_cmp );
					write( ln2, string'(" at address 0x") );
					hwrite( ln2, std_logic_vector(to_unsigned(i,32)) );
					write( ln2, string'(".") );
					writeline( output, ln2 );
                    exit;
				end if;
                i := i + 1;
			else
				out_rd_en <= '0';
			end if;
        end loop;

		wait until (clock = '1');
		wait until (clock = '0');
		out_rd_en <= '0';
        file_close( cmp_file );
        file_close( out_file );
        out_read_done <= '1';
        wait;
    end process img_write_process;


end architecture behavior;
