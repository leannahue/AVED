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
	constant accu_h      : integer := 1018; --sqrt(2)*720
	constant accu_w      : integer:= 180;
	constant sqrt_2      : integer:= 92682; --sqrt(2)*2^16
	constant WIDTH       : integer:= 720;
	constant HEIGHT      : integer:= 720
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
	signal out_din       : out std_logic_vector(31 downto 0)
);
end entity Hough;

architecture behavior of Hough is

	 type accumulator is array (natural range <> ) of integer;
	 --signal accu_h   	: integer := 1018; 
	 --signal accu_w   	: integer := 180;
	 signal center_x        : integer := WIDTH/2;
	 signal center_y        : integer := HEIGHT/2;  
	 signal x, x_c       		: integer;
   	 signal y, y_c       		: integer;
	 signal threshold  		: integer := 50;
	 signal pixel			: std_logic_vector(7 downto 0);
	 TYPE state_types is (s0,s1,s2,s3);
         signal state        : state_types;
         signal next_state   : state_types;
	 signal accu_array, accu_array_c  : accumulator(0 to (accu_h*accu_w)-1);


    signal theta,theta_c : integer;
    signal theta_rd : std_logic_vector (31 downto 0);
    signal cos_theta : std_logic_vector (31 downto 0);
    signal out_cos_wr_en : std_logic;
    signal out_cos_full : std_logic := '0';
    signal sin_theta : std_logic_vector (31 downto 0);
    signal out_sin_wr_en : std_logic;
    signal out_sin_full : std_logic := '0';
--sqrt2= 1.41421356
--PI=3.14159265

function sra_func( val : signed; n : integer )
    return signed is
        variable temp : signed (val'length - 1 downto 0);
    begin
        temp := val srl n;
        temp(val'length - 1 downto val'length - n) := (others => val(val'length - 1));
        return temp;
    end function sra_func;


function quantize_n( val : integer; n : integer )
    return signed is
        variable temp : signed (63 downto 0);
    begin
        temp := to_signed(val, 64) sll n;
        return temp;
    end function;

begin

cordic_inst : cordic
    port map (
        clock => clock,
        reset => reset,
        in_dout => theta_rd,
        in_rd_en => in_rd_en,
        in_empty => in_empty,
        out_cos_wr_en => out_cos_wr_en,
        out_cos_din => cos_theta,
        out_cos_full => out_cos_full,
        out_sin_wr_en => out_sin_wr_en,
        out_sin_din => sin_theta,
        out_sin_full => out_sin_full
    );


    Accumulate_process : process( state, in_dout, x, y) is
	variable r, hough_h, temp : signed (47 downto 0);
      	variable x_position, y_position : signed (15 downto 0);
    begin
        next_state <= state;
        x_c <= x;
        y_c <= y;
	accu_array_c <= accu_array;
	in_rd_en <= '0';
        out_wr_en <= '0';
        out_din <= (others => '0');	
        
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
		    pixel <= in_dout; 
		if (to_integer(unsigned(pixel)) > threshold) then
			next_state <= s2;
		else
			x_c <= x + 1;
			next_state <= s1;
		end if;
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
            when s2 =>
		in_rd_en <= '0';
		  if ((out_cos_wr_en = '1') AND (out_sin_wr_en = '1')) then
			theta_rd<=  std_logic_vector(resize(sra_func(((((quantize_n(theta, 14) sll 14) + quantize_n(180, 13)) / quantize_n(180, 14)) * to_signed(PI, 64)) + quantize_n(1, 13), 14), 32));
			--just followed how to give input to cordic component in cordic_tb file 
			
			x_position :=  to_signed((x - (WIDTH/2)), 16);
			y_position :=  to_signed((y - (HEIGHT/2)), 16); 
			r := x_position*signed(cos_theta) + y_position*signed(sin_theta);
			hough_h := to_signed(sqrt_2, 32)*to_signed((WIDTH/2),16);
			temp:= (hough_h + r) srl 16;
			accu_array_c(to_integer(temp)*accu_w + theta) <= accu_array(to_integer(temp)*accu_w + theta) + 1;
		 	theta_c <= theta + 1;
 		  end if;
		if (theta = 180) then
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
		--output the accumulator
		out_wr_en <= '1';
		out_din <=  std_logic_vector(to_unsigned(accu_array(x + y*accu_w), 32));
		x_c <= x + 1;
		if ( x = WIDTH - 1 ) then
                        x_c <= 0;
                        y_c <= y + 1;
                end if;
		if ( (x = (accu_w -1)) AND (y = (accu_h -1))) then
                        x_c <= 0;
                        y_c <= 0;
                        next_state <= s0;
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