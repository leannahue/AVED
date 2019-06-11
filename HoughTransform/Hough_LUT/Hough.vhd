library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.constants.all;
use IEEE.MATH_REAL.ALL;

entity Hough is
generic
(
	constant accu_h      : integer := 101; --sqrt(2)*72
	constant accu_w      : integer:= 180;
	constant sqrt_2      : integer:= 23170; --sqrt(2)*2^14
	constant WIDTH       : integer:= 72;
	constant HEIGHT      : integer:= 72
);
port
(
	signal clock         : in  std_logic;
    	signal reset         : in  std_logic;
	signal in_rd_en      : out std_logic;
	signal in_empty      : in  std_logic;
	signal in_dout       : in  std_logic_vector(7 downto 0);
	signal out_wr_en     : out std_logic;
	signal out_full      : in  std_logic;
	signal out_din       : out std_logic_vector(7 downto 0)
);
end entity Hough;

architecture behavior of Hough is

component sin_table is
	port (
		signal theta        : in std_logic_vector (7 downto 0);
		signal sin_theta    : out std_logic_vector (15 downto 0)
	);
end component;

component cos_table is
	port (
		signal theta       : in std_logic_vector (7 downto 0);
		signal cos_theta   : out std_logic_vector (15 downto 0)
	);
end component;

	 type accumulator is array (natural range <> ) of integer;
	 --signal accu_h   	: integer := 1018;
	 --signal accu_w   	: integer := 180;
	 signal center_x        : integer := WIDTH/2;
	 signal center_y        : integer := HEIGHT/2;
	 signal x, x_c       		: integer;
   	 signal y, y_c       		: integer;
	 signal threshold  		: integer := 48;
	 --signal pixel			: std_logic_vector(7 downto 0);
	 TYPE state_types is (s0,s1,s2,s3);
         signal state        : state_types;
         signal next_state   : state_types;
	 signal accu_array, accu_array_c  : accumulator(0 to (accu_h*accu_w)-1);

	signal  hough_h : integer;

    signal theta,theta_c : integer;
    signal theta_in  : std_logic_vector (7 downto 0);
    signal cos_theta : std_logic_vector (15 downto 0);
    signal sin_theta : std_logic_vector (15 downto 0);
--sqrt2= 1.41421356
--PI=3.14159265

begin



sin_inst : sin_table
    port map (
        theta => theta_in,
	sin_theta => sin_theta
    );

cos_inst : cos_table
    port map (
	theta=> theta_in,
	cos_theta=> cos_theta
    );


    Accumulate_process : process( state, in_dout, x, y, in_empty, out_full, theta) is
	variable temp : unsigned(31 downto 0);
      	variable x_position, y_position, r : integer;
    begin
        next_state <= state;
        x_c <= x;
        y_c <= y;
	accu_array_c <= accu_array;
	in_rd_en <= '0';
        out_wr_en <= '0';
        out_din <= (others => '0');
	hough_h <= sqrt_2 *(WIDTH/2);
	theta_in <= std_logic_vector(to_unsigned(theta, 8));

        case ( state ) is
            when s0 =>
                x_c <= 0;
                y_c <= 0;
		theta_c   <= 0;
                accu_array_c <= (others => 0);
		next_state <= s1;
            when s1 =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
		    --pixel <= in_dout;
		    x_c <= x + 1;
		
  		if ( x = WIDTH - 1 ) then
                        x_c <= 0;
                        y_c <= y + 1;
                end if;
                if ( (x = (WIDTH -1)) AND (y = (HEIGHT -1)) )then
                        x_c <= 0;
                        y_c <= 0;
			next_state <= s3;
		end if;
		if (to_integer(unsigned(in_dout)) > threshold) then
			theta_c <= 0;
			next_state <= s2;
		end if;
                end if;
            when s2 =>
			in_rd_en <= '0';
			x_position :=  x - (WIDTH/2);
			y_position :=  y - (HEIGHT/2);
			r := x_position*to_integer(signed(cos_theta)) + y_position*to_integer(signed(sin_theta));
			temp := to_unsigned((hough_h + r),32) srl 14;
			accu_array_c(to_integer(temp)*accu_w + theta) <= accu_array(to_integer(unsigned(temp))*accu_w + theta) + 1;
		 	theta_c <= theta + 1;

		if (theta = 179) then
			theta_c <= 0;
			x_c <= x + 1;
			next_state <= s1;
  		    if ( x = WIDTH - 1 ) then
                        x_c <= 0;
                        y_c <= y + 1;
                    end if;
                    if ( (x = (WIDTH -1)) AND (y = (HEIGHT -1)) )then
                        x_c <= 0;
                        y_c <= 0;
			next_state <= s3;
                    end if;
		end if;
            when s3 =>
		if ( out_full = '0' ) then
		--output the accumulator
		out_wr_en <= '1';
		out_din <=  std_logic_vector(to_unsigned(accu_array(x + y*accu_w), 8));
		x_c <= x + 1;
		if ( x = (accu_w - 1) ) then
                        x_c <= 0;
                        y_c <= y + 1;
                end if;
		if ( (x = (accu_w -1)) AND (y = (accu_h -1))) then
                        x_c <= 0;
                        y_c <= 0;
                        next_state <= s0;
                end if;
		end if;
            when others =>
                x_c <= 0;
                y_c <= 0;
                next_state <= s0;
        end case;
    end process Accumulate_process;


    clock_process : process( clock, reset ) is
    begin
        if ( reset = '1' ) then
            state <= s0;
            x <= 0;
            y <= 0;
	    theta<= 0;
	    accu_array <= (others => 0);
        elsif ( rising_edge(clock) ) then
            state <= next_state;
            x <= x_c;
            y <= y_c;
	    theta <= theta_c;
	    accu_array <= accu_array_c;
        end if;
    end process clock_process;

end architecture behavior;
