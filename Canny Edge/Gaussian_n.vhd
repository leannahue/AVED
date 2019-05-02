
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Gaussian_n is
generic
(
	constant WIDTH      : integer:= 720;
	constant HEIGHT     : integer:= 540;
	constant ADDS        : integer := 159
);
port
(
	signal clock        : in  std_logic;
    signal reset        : in  std_logic;
	signal in_rd_en     : out std_logic; 
	signal in_empty     : in  std_logic; 
	signal in_dout      : in  std_logic_vector(7 downto 0); 
	signal out_wr_en	: out std_logic; 
	signal out_full     : in  std_logic; 
	signal out_din      : out std_logic_vector(7 downto 0)
);
end entity Gaussian_n;

architecture behavior of Gaussian_n is
    
	function log2( input : integer )
	return integer is 
		variable log : integer;
		variable tmp : integer;
	begin
		tmp := input;
		log := 0;
		while tmp > 1 loop
			tmp := tmp / 2;
			log := log + 1;
		end loop;
		if ( (input /= 0) and (input /= (to_unsigned(1, 32) SLL log)) ) then
			log := log + 1;
		end if;
		return log;
	end log2;

	constant W_SIZE     : integer := log2(WIDTH);    
	constant H_SIZE     : integer := log2(HEIGHT);    
    constant REG_SIZE   : integer := (WIDTH * 4) + 5;
    
    type ARRAY_INT is array (natural range <> ) of integer;
    type ARRAY_SLV is array (natural range <> ) of std_logic_vector(7 downto 0);
    signal shift_reg    : ARRAY_SLV (0 to REG_SIZE-1);
    signal shift_reg_c  : ARRAY_SLV (0 to REG_SIZE-1);

    TYPE state_types is (s0,s1,s2,s3,s4);
    signal state        : state_types;
    signal next_state   : state_types;

    signal x, x_c       : integer;
    signal y, y_c       : integer;

function Gaussian_filter_1(data : ARRAY_SLV(0 to 24))
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
        output := integer(temp_out / ADDS);
        return std_logic_vector(to_unsigned(output,8));
    end Gaussian_filter_1;






   function Gaussian_filter_2(data : ARRAY_SLV(0 to 24))
    return std_logic_vector is
    variable temp_out : std_logic_vector(31 downto 0);    
    variable output   : std_logic_vector(31 downto 0);
    constant filter   : ARRAY_INT(0 to 24) := (2,4,5,4,2,4,9,12,9,4,5,12,15,12,5,4,9,12,9,4,2,4,5,4,2);
         
    begin
        temp_out := (others => '0');
        for j in 0 to 4 loop
            for i in 0 to 4 loop
                temp_out := std_logic_vector(unsigned(temp_out) + resize(resize(unsigned(data(j*5+i)),32) * to_unsigned(filter(j*5+i),32),32));
            end loop;
        end loop;
        -- output := integer(real(temp_out) / real(159));
		  return std_logic_vector(resize(unsigned(temp_out) / to_unsigned(159,32),8));
    end Gaussian_filter_2;

begin


    Gaussian_process : process( state, in_empty, in_dout, out_full, x, y, shift_reg ) is
        variable grad   : std_logic_vector(7 downto 0);
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
                data(i*3+j) := shift_reg(i*WIDTH + j);
            end loop;
        end loop;

        grad := (others => '0');
        if ( (x > 1) AND (x < WIDTH-2) AND (y > 1) AND (y < HEIGHT-2) ) then
            grad := Gaussian_filter_1(data);
        end if;
        
        case ( state ) is
            when s0 =>
                x_c <= 0;
                y_c <= 0;
                shift_reg_c <= (others => (others => '0'));
                next_state <= s1;
                
            when s1 =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1);
                    shift_reg_c(REG_SIZE-1) <= in_dout;
                    x_c <= x + 1;
                    if ( x = WIDTH - 1 ) then
                        x_c <= 0;
                        y_c <= y + 1;
                    end if;
                    if ( (y * WIDTH + x) = (WIDTH*2 + 2) ) then
                        x_c <= 0;
                        y_c <= 0;
                        next_state <= s2;
                    end if;
                end if;
                
            when s2 =>
                if ( in_empty = '0' AND out_full = '0' ) then
                    shift_reg_c(0 to REG_SIZE-2) <= shift_reg(1 to REG_SIZE-1);
                    shift_reg_c(REG_SIZE-1) <= in_dout;
                    x_c <= x + 1;
                    if ( x = WIDTH - 1 ) then
                        x_c <= 0;
                        y_c <= y + 1;
                    end if;

                    out_din <= grad;
                    in_rd_en <= '1';
                    out_wr_en <= '1';
                    if ( y = HEIGHT-3 AND x = WIDTH-3 ) then
                        next_state <= s3;
                    else
                        next_state <= s2;
                    end if;
                end if;
                
            when s3 =>
                if ( out_full = '0' ) then
                    x_c <= x + 1;
                    if ( x = WIDTH - 1 ) then
                        x_c <= 0;
                        y_c <= y + 1;
                    end if;
                    out_din <= grad;
                    out_wr_en <= '1';
                    if ( (x = WIDTH-1) AND (y = HEIGHT-1) ) then
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
        end if;
    end process clock_process;

end architecture behavior;
