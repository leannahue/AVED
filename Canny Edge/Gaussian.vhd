library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.MATH_REAL.ALL;

entity Gaussian is
generic
(
	constant WIDTH_P     : integer:= 9;
	constant HEIGHT      : integer:= 9
	--constant WIDTH_P     : integer:= 724;
	--constant HEIGHT      : integer:= 544
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
end entity Gaussian;

architecture behavior of Gaussian is

    constant REG_SIZE   : integer := (WIDTH_P * 4) + 5;
    
    type ARRAY_INT is array (natural range <> ) of integer;
    type ARRAY_SLV is array (natural range <> ) of std_logic_vector(7 downto 0);
    signal shift_reg    : ARRAY_SLV (0 to REG_SIZE-1);
    signal shift_reg_c  : ARRAY_SLV (0 to REG_SIZE-1);
    signal temp_reg     : ARRAY_SLV (0 TO 1);
    signal temp_reg_c   : ARRAY_SLV (0 TO 1);

    TYPE state_types is (s0,s1,s2,s3,s4);
    signal state        : state_types;
    signal next_state   : state_types;

    signal x, x_c       : integer;
    signal y, y_c       : integer;


    function Gaussian_filter(data : ARRAY_SLV(0 to 24))
    return std_logic_vector is
    variable temp_out : integer;    
    variable output   : integer;
    constant filter   : ARRAY_INT(0 to 24) := (2,4,5,4,2,4,9,12,9,4,5,12,15,12,5,4,9,12,9,4,2,4,5,4,2);
         
    begin
        temp_out := 0;
        for j in 0 to 4 loop
            for i in 0 to 4 loop
                temp_out := temp_out + to_integer(unsigned(data(j*5+i))) * filter(j*5+i);
            end loop;
        end loop;
        output := integer(real(temp_out) / real(159));
        return std_logic_vector(to_unsigned(output,8));
    end Gaussian_filter;

begin
    Gaussian_process : process( state, in_empty, in_dout, out_full, x, y, shift_reg ) is
        variable blur_out   : std_logic_vector(7 downto 0);
        variable data   : ARRAY_SLV(0 to 24);
    begin
        next_state <= state;
        x_c <= x;
        y_c <= y;
        shift_reg_c <= shift_reg;
        in_rd_en <= '0';
        out_wr_en <= '0';
        out_din <= (others => '0');

        for i in 0 to 4 loop
            for j in 0 to 4 loop
                data(i*5+j) := shift_reg(i*WIDTH_P + j);
            end loop;
        end loop;

        blur_out := Gaussian_filter(data);
        
        case ( state ) is
            when s0 =>
                x_c <= 0;
                y_c <= 0;
                shift_reg_c <= (others => (others => '0'));
		temp_reg_c <= (others => (others => '0'));
                next_state <= s1;
                
            when s1 =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
		  if ( x = WIDTH_P - 5) then
                    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= in_dout;
		    x_c <= 0;
                    y_c <= y + 1;
		  elsif ((x= 0) or (x = 1)) then
		    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= x"00";
		    temp_reg_c(0) <= temp_reg(1);
		    temp_reg_c(1) <= in_dout;
		    x_c <= x + 1;
		  elsif (x = 2) then
		    shift_reg_c(0 to REG_SIZE-6) <= shift_reg(5 to REG_SIZE-1);
		    shift_reg_c(REG_SIZE-5) <= x"00";
		    shift_reg_c(REG_SIZE-4) <= x"00";
		    shift_reg_c(REG_SIZE-3) <= temp_reg(0);
		    shift_reg_c(REG_SIZE-2) <= temp_reg(1);
                    shift_reg_c(REG_SIZE-1) <= in_dout;
	     	    x_c <= x + 1;
		  else
		    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= in_dout;
		    x_c <= x + 1;
		  end if;
                    if ( (y * WIDTH_P + x) = (2 * WIDTH_P + 2) ) then
                        next_state <= s2;
                    end if;
                end if;
                
            when s2 =>
		if ( in_empty = '0' AND out_full = '0' ) then
                if ( x = WIDTH_P - 5) then
                    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= in_dout;
		    x_c <= 0;
                    y_c <= y + 1;
		  elsif ((x= 0) or (x = 1)) then
		    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= x"00";
		    temp_reg_c(0) <= temp_reg(1);
		    temp_reg_c(1) <= in_dout;
		    x_c <= x + 1;
		  elsif (x = 2) then
		    shift_reg_c(0 to REG_SIZE-6) <= shift_reg(5 to REG_SIZE-1);
		    shift_reg_c(REG_SIZE-5) <= x"00";
		    shift_reg_c(REG_SIZE-4) <= x"00";
		    shift_reg_c(REG_SIZE-3) <= temp_reg(0);
		    shift_reg_c(REG_SIZE-2) <= temp_reg(1);
                    shift_reg_c(REG_SIZE-1) <= in_dout;
	     	    x_c <= x + 1;
		  else
		    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= in_dout;
		    x_c <= x + 1;
		  end if;

                    out_din <= blur_out;
                    in_rd_en <= '1';
                    out_wr_en <= '1';
                    if ( y = HEIGHT-4 AND x = WIDTH_P -9 ) then
                        next_state <= s3;
                    else
                        next_state <= s2;
                    end if;
                end if;
                
            when s3 =>
                if ( out_full = '0' ) then

                  if ( x = WIDTH_P - 5) then
                    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= x"00";
		    x_c <= 0;
                    y_c <= y + 1;
		  elsif ((x= 0) or (x = 1)) then
		    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= x"00";
		    temp_reg_c(0) <= temp_reg(1);
		    temp_reg_c(1) <= x"00";
		    x_c <= x + 1;
		  elsif (x = 2) then
		    shift_reg_c(0 to REG_SIZE-6) <= shift_reg(5 to REG_SIZE-1);
		    shift_reg_c(REG_SIZE-5) <= x"00";
		    shift_reg_c(REG_SIZE-4) <= x"00";
		    shift_reg_c(REG_SIZE-3) <= temp_reg(0);
		    shift_reg_c(REG_SIZE-2) <= temp_reg(1);
                    shift_reg_c(REG_SIZE-1) <= x"00";
	     	    x_c <= x + 1;
		  else
		    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1); 
		    shift_reg_c(REG_SIZE-1) <= x"00";
		    x_c <= x + 1;
		  end if;
                    out_din <= blur_out;
                    out_wr_en <= '1';
                    if ( (x = WIDTH_P -5) AND (y = HEIGHT - 5) ) then
                        next_state <= s0;
                    end if;
                end if;
                
            when others =>
                x_c <= 0;
                y_c <= 0;
                shift_reg_c <= (others => (others => 'X'));
                next_state <= s0;
        end case;
    end process Gaussian_process;
    
    
    clock_process : process( clock, reset ) is
    begin
        if ( reset = '1' ) then
            state <= s0;
            x <= 0;
            y <= 0;
            shift_reg <= (others => (others => '0'));            
        elsif ( rising_edge(clock) ) then
            state <= next_state;
            x <= x_c;
            y <= y_c;
            shift_reg <= shift_reg_c;
	    temp_reg<= temp_reg_c;
        end if;
    end process clock_process;

end architecture behavior;
