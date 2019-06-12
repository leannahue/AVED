library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use work.hough_constants.all;

entity sin_table is
	port (
		signal theta        : in std_logic_vector (7 downto 0);
		signal sin_theta    : out std_logic_vector (17 downto 0)
	);
end entity sin_table;

architecture behavioral of sin_table is

	signal theta_int              : integer;
	signal theta_in		: integer;
begin
	theta_int <= to_integer(unsigned(theta));
	
	sin_t: process (theta_int)
	begin
		if (to_integer(unsigned(theta)) < 90) then
		theta_in  <= to_integer(unsigned(theta));
		else
		theta_in  <= (179 - to_integer(unsigned(theta)));
		end if;
		case theta_in is
			when 0  =>    sin_theta <= std_logic_vector(to_unsigned(0,18));
			when 1  =>    sin_theta <= std_logic_vector(to_unsigned(285,18));
			when 2  =>    sin_theta <= std_logic_vector(to_unsigned(571,18));
			when 3  =>    sin_theta <= std_logic_vector(to_unsigned(857,18));
			when 4  =>    sin_theta <= std_logic_vector(to_unsigned(1142,18));
			when 5  =>    sin_theta <= std_logic_vector(to_unsigned(1427,18));
			when 6  =>    sin_theta <= std_logic_vector(to_unsigned(1712,18));
			when 7  =>    sin_theta <= std_logic_vector(to_unsigned(1996,18));
			when 8  =>    sin_theta <= std_logic_vector(to_unsigned(2280,18));
			when 9  =>    sin_theta <= std_logic_vector(to_unsigned(2563,18));
			when 10  =>    sin_theta <= std_logic_vector(to_unsigned(2845,18));
			when 11  =>    sin_theta <= std_logic_vector(to_unsigned(3126,18));
			when 12  =>    sin_theta <= std_logic_vector(to_unsigned(3406,18));
			when 13  =>    sin_theta <= std_logic_vector(to_unsigned(3685,18));
			when 14  =>    sin_theta <= std_logic_vector(to_unsigned(3963,18));
			when 15  =>    sin_theta <= std_logic_vector(to_unsigned(4240,18));
			when 16  =>    sin_theta <= std_logic_vector(to_unsigned(4516,18));
			when 17  =>    sin_theta <= std_logic_vector(to_unsigned(4790,18));
			when 18  =>    sin_theta <= std_logic_vector(to_unsigned(5062,18));
			when 19  =>    sin_theta <= std_logic_vector(to_unsigned(5334,18));
			when 20  =>    sin_theta <= std_logic_vector(to_unsigned(5603,18));
			when 21  =>    sin_theta <= std_logic_vector(to_unsigned(5871,18));
			when 22  =>    sin_theta <= std_logic_vector(to_unsigned(6137,18));
			when 23  =>    sin_theta <= std_logic_vector(to_unsigned(6401,18));
			when 24  =>    sin_theta <= std_logic_vector(to_unsigned(6663,18));
			when 25  =>    sin_theta <= std_logic_vector(to_unsigned(6924,18));
			when 26  =>    sin_theta <= std_logic_vector(to_unsigned(7182,18));
			when 27  =>    sin_theta <= std_logic_vector(to_unsigned(7438,18));
			when 28  =>    sin_theta <= std_logic_vector(to_unsigned(7691,18));
			when 29  =>    sin_theta <= std_logic_vector(to_unsigned(7943,18));
			when 30  =>    sin_theta <= std_logic_vector(to_unsigned(8191,18));
			when 31  =>    sin_theta <= std_logic_vector(to_unsigned(8438,18));
			when 32  =>    sin_theta <= std_logic_vector(to_unsigned(8682,18));
			when 33  =>    sin_theta <= std_logic_vector(to_unsigned(8923,18));
			when 34  =>    sin_theta <= std_logic_vector(to_unsigned(9161,18));
			when 35  =>    sin_theta <= std_logic_vector(to_unsigned(9397,18));
			when 36  =>    sin_theta <= std_logic_vector(to_unsigned(9630,18));
			when 37  =>    sin_theta <= std_logic_vector(to_unsigned(9860,18));
			when 38  =>    sin_theta <= std_logic_vector(to_unsigned(10086,18));
			when 39  =>    sin_theta <= std_logic_vector(to_unsigned(10310,18));
			when 40  =>    sin_theta <= std_logic_vector(to_unsigned(10531,18));
			when 41  =>    sin_theta <= std_logic_vector(to_unsigned(10748,18));
			when 42  =>    sin_theta <= std_logic_vector(to_unsigned(10963,18));
			when 43  =>    sin_theta <= std_logic_vector(to_unsigned(11173,18));
			when 44  =>    sin_theta <= std_logic_vector(to_unsigned(11381,18));
			when 45  =>    sin_theta <= std_logic_vector(to_unsigned(11585,18));
			when 46  =>    sin_theta <= std_logic_vector(to_unsigned(11785,18));
			when 47  =>    sin_theta <= std_logic_vector(to_unsigned(11982,18));
			when 48  =>    sin_theta <= std_logic_vector(to_unsigned(12175,18));
			when 49  =>    sin_theta <= std_logic_vector(to_unsigned(12365,18));
			when 50  =>    sin_theta <= std_logic_vector(to_unsigned(12550,18));
			when 51  =>    sin_theta <= std_logic_vector(to_unsigned(12732,18));
			when 52  =>    sin_theta <= std_logic_vector(to_unsigned(12910,18));
			when 53  =>    sin_theta <= std_logic_vector(to_unsigned(13084,18));
			when 54  =>    sin_theta <= std_logic_vector(to_unsigned(13254,18));
			when 55  =>    sin_theta <= std_logic_vector(to_unsigned(13420,18));
			when 56  =>    sin_theta <= std_logic_vector(to_unsigned(13582,18));
			when 57  =>    sin_theta <= std_logic_vector(to_unsigned(13740,18));
			when 58  =>    sin_theta <= std_logic_vector(to_unsigned(13894,18));
			when 59  =>    sin_theta <= std_logic_vector(to_unsigned(14043,18));
			when 60  =>    sin_theta <= std_logic_vector(to_unsigned(14188,18));
			when 61  =>    sin_theta <= std_logic_vector(to_unsigned(14329,18));
			when 62  =>    sin_theta <= std_logic_vector(to_unsigned(14466,18));
			when 63  =>    sin_theta <= std_logic_vector(to_unsigned(14598,18));
			when 64  =>    sin_theta <= std_logic_vector(to_unsigned(14725,18));
			when 65  =>    sin_theta <= std_logic_vector(to_unsigned(14848,18));
			when 66  =>    sin_theta <= std_logic_vector(to_unsigned(14967,18));
			when 67  =>    sin_theta <= std_logic_vector(to_unsigned(15081,18));
			when 68  =>    sin_theta <= std_logic_vector(to_unsigned(15190,18));
			when 69  =>    sin_theta <= std_logic_vector(to_unsigned(15295,18));
			when 70  =>    sin_theta <= std_logic_vector(to_unsigned(15395,18));
			when 71  =>    sin_theta <= std_logic_vector(to_unsigned(15491,18));
			when 72  =>    sin_theta <= std_logic_vector(to_unsigned(15582,18));
			when 73  =>    sin_theta <= std_logic_vector(to_unsigned(15668,18));
			when 74  =>    sin_theta <= std_logic_vector(to_unsigned(15749,18));
			when 75  =>    sin_theta <= std_logic_vector(to_unsigned(15825,18));
			when 76  =>    sin_theta <= std_logic_vector(to_unsigned(15897,18));
			when 77  =>    sin_theta <= std_logic_vector(to_unsigned(15964,18));
			when 78  =>    sin_theta <= std_logic_vector(to_unsigned(16025,18));
			when 79  =>    sin_theta <= std_logic_vector(to_unsigned(16082,18));
			when 80  =>    sin_theta <= std_logic_vector(to_unsigned(16135,18));
			when 81  =>    sin_theta <= std_logic_vector(to_unsigned(16182,18));
			when 82  =>    sin_theta <= std_logic_vector(to_unsigned(16224,18));
			when 83  =>    sin_theta <= std_logic_vector(to_unsigned(16261,18));
			when 84  =>    sin_theta <= std_logic_vector(to_unsigned(16294,18));
			when 85  =>    sin_theta <= std_logic_vector(to_unsigned(16321,18));
			when 86  =>    sin_theta <= std_logic_vector(to_unsigned(16344,18));
			when 87  =>    sin_theta <= std_logic_vector(to_unsigned(16361,18));
			when 88  =>    sin_theta <= std_logic_vector(to_unsigned(16374,18));
			when 89  =>    sin_theta <= std_logic_vector(to_unsigned(16381,18));
			when others =>  sin_theta <= std_logic_vector(to_unsigned(16381,18));
		end case;
	end process;

end architecture;
