library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.hough_constants.all;

entity threshold_finite_tb is
  generic
  (
  constant IMG_IN_NAME  : string (10 downto 1) := "accu_c.txt";
  constant THRESHOLD_OUT_NAME : string (24 downto 1) := "hough_threshold_vhdl.txt";
  constant FINITE_OUT_NAME : string (20 downto 1) := "hough_lines_vhdl.txt";
  --    constant IMG_IN_NAME  : string (18 downto 1) := "track_accu.bmp";
  --    constant IMG_OUT_NAME : string (19 downto 1) := "track_output.bmp";
  --    constant COMPARE_NAME : string (21 downto 1) := "stage4_hysteresis.bmp";
  constant CLOCK_PERIOD : time := 10 ns
  );
end entity threshold_finite_tb;


architecture behavior of threshold_finite_tb is

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

  signal in_rd_en   : std_logic;
  signal in_empty   : std_logic;
  signal in_din     : std_logic_vector (7 downto 0);
  signal out_theta  : std_logic_vector (7 downto 0);
  signal out_rho    : std_logic_vector (9 downto 0);
  signal out_full   : std_logic;
  signal out_rho_done     : std_logic;
  signal thresh_wr_en     : std_logic;
  signal thresh_in_empty  : std_logic;

  signal xy_rd_en : std_logic;
  signal xy_wr_en : std_logic;
  signal xy_done  : std_logic;
  signal x1       : std_logic_vector (9 downto 0);
  signal x2       : std_logic_vector (9 downto 0);
  signal y1       : std_logic_vector (9 downto 0);
  signal y2       : std_logic_vector (9 downto 0);

  signal hold_clock    : std_logic := '0';
  signal in_write_done : std_logic := '0';
  signal out_read_done : std_logic := '0';
  signal out_errors    : integer := 0;
  signal in_count      : integer := 0;
  signal pixel_cnt     : integer := 0;
  signal wait_cnt      : integer := 0;

  -- signal out_data_read : std_logic_vector (7 downto 0);
  --    signal out_data_cmp : std_logic_vector (7 downto 0);

  file out_file_threshold : text;
  file out_file_finite : text;

begin

  h_threshold_inst : threshold
  port map  (
  clock         => clock,
  reset         => reset,
  in_rd_en      => in_rd_en,         -- output
  in_empty      => in_empty,         -- input
  in_dout       => in_din,           -- input
  out_wr_en     => thresh_wr_en,        -- output
  out_full      => out_full,         -- input
  out_rho_done  => out_rho_done,
  out_rho       => out_rho,          -- output
  out_theta     => out_theta         -- output
  );

  thresh_in_empty <= not (thresh_wr_en);

  finite_lines_inst : finite_lines
  port map (
  clock         => clock,
  reset         => reset,
  in_empty      => thresh_in_empty,
  out_full      => '0',
  in_rho        => out_rho,
  in_theta      => out_theta,
  in_rho_done   => out_rho_done,

  in_rd_en      => xy_rd_en,
  out_wr_en     => xy_wr_en,
  out_xy_done   => xy_done,
  x1            => x1,
  x2            => x2,
  y1            => y1,
  y2            => y2
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

    file_open( out_file_threshold, THRESHOLD_OUT_NAME, write_mode);
    file_open( out_file_finite, FINITE_OUT_NAME, write_mode);
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
    wait until  (in_write_done = '1');

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

  -- Read input
  img_read_process : process
  file in_file : text;
    variable accu1   : integer;
    variable accu_in : line;
    variable ln1     : line;
    variable i       : integer := 0;
  begin
    in_empty <= '1';
    wait until  (reset = '1');
    wait until  (reset = '0');

    write( ln1, string'("@ ") );
    write( ln1, NOW );
    write( ln1, string'(": Loading file ") );
    write( ln1, IMG_IN_NAME );
    write( ln1, string'("...") );
    writeline( output, ln1 );

    file_open( in_file, IMG_IN_NAME, read_mode );
    in_empty <= '0';

    -- read header
    --	while ( not ENDFILE( in_file) and i < 54 ) loop
    --            read( in_file, char1 );
    --            i := i + 1;
    --        end loop;

    while ( not ENDFILE( in_file) ) loop
      wait until (clock = '1');
      wait until (clock = '0');
      if ( in_empty = '0' ) then
        readline( in_file, accu_in );
        read( accu_in, accu1 );
        in_din <= std_logic_vector(to_unsigned(accu1,8));
      end if;
      in_count <= in_count + 1;
    end loop;

    wait until (clock = '1');
    wait until (clock = '0');
    in_empty <= '1';    -- end of file
    file_close( in_file );
    in_write_done <= '1';
    wait;
  end process img_read_process;



  -- Write output
  hough_output : process(clock,reset)
    variable char : character;
    variable hough_out : line;
    variable ln1, ln2, ln3 : line;
    variable i : integer := 0;
    variable rho_int   : integer;
    variable theta_int : integer;
    variable x1_int   : integer;
    variable x2_int   : integer;
    variable y1_int   : integer;
    variable y2_int   : integer;

  begin

    out_full <= '0';
    --          write( ln1, string'("@ ") );
    --          write( ln1, NOW );
    --          write( ln1, string'(": Comparing file ") );
    --          write( ln1, IMG_OUT_NAME );
    --          write( ln1, string'("...") );
    --          writeline( output, ln1 );

    rho_int   := to_integer(unsigned(out_rho));
    theta_int := to_integer(unsigned(out_theta));
    x1_int    := to_integer(unsigned(x1));
    x2_int    := to_integer(unsigned(x2));
    y1_int    := to_integer(unsigned(y1));
    y2_int    := to_integer(unsigned(y2));

    if (reset = '1') then
      wait_cnt <= wait_cnt + 1;
    elsif (falling_edge(clock)) then
      pixel_cnt <= pixel_cnt + 1;
      if (thresh_wr_en = '1') then
        write( ln3, rho_int );
        write( ln3, string'(" "));
        write( ln3, theta_int );
        writeline( out_file_threshold, ln3 );
      end if;
      if (xy_wr_en = '1') then
        write( ln3, x1_int );
        write( ln3, string'(" "));
        write( ln3, x2_int );
        write( ln3, string'(" "));
        write( ln3, y1_int );
        write( ln3, string'(" "));
        write( ln3, y2_int );
        writeline( out_file_finite, ln3 );
      end if;
    end if;

  end process hough_output;


end architecture behavior;
