library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.constants.all;

entity grayscale is 
port 
(
	signal clock        : in  std_logic;
   signal reset        : in  std_logic;
	signal in_rd_en     : out std_logic; 
	signal in_empty     : in  std_logic; 
	signal in_dout      : in  std_logic_vector(23 downto 0); 
	signal out_wr_en	: out std_logic; 
	signal out_full     : in  std_logic; 
	signal out_din      : out std_logic_vector(7 downto 0)
);
end entity;

architecture behavior of grayscale is 	
	type state_type is (s0, s1); 
	signal state, next_state 	 : state_type;
	signal grey_sel, grey_sel_c : std_logic_vector(7 downto 0);
begin 

	fsm_process : process(state, in_empty, in_dout, out_full, grey_sel) is 
		variable gs : std_logic_vector(15 downto 0);
	begin 
		next_state <= state; 
		grey_sel_c <= grey_sel; 
		in_rd_en <= '0'; 
		out_wr_en <= '0'; 
		out_din <= (others => '0'); 
		
		case (state) is
			when s0 =>
				if (in_empty = '0') then 
					in_rd_en <= '1'; 
					-- 16 so that there are enough bits -- 
					gs := std_logic_vector((resize(unsigned(in_dout(23 downto 16)), 16) + resize(unsigned(in_dout(15 downto 8)), 16) + resize(unsigned(in_dout(7 downto 0)), 16)) / to_unsigned(3, 16));
				    grey_sel_c <= gs(7 downto 0);
                    next_state <= s1;
				end if; 
			
			when s1 => 
				out_din <= grey_sel; 
				if (out_full = '0') then 
					out_wr_en <= '1'; 
					next_state <= s0; 
				end if;
		
			when others => 
				grey_sel_c <= (others => '0'); 
				next_state <= s0; 
		end case;
	end process fsm_process; 
	
	clock_process : process( clock, reset ) is
    begin
        if ( reset = '1' ) then
            state <= s0;
            grey_sel <= (others => '0');
        elsif ( rising_edge(clock) ) then
            state <= next_state;
            grey_sel <= grey_sel_c;
        end if;
    end process clock_process;

end architecture behavior;
