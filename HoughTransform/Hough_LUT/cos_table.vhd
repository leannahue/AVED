library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use work.hough_constants.all;

entity cos_table is
	port (
		signal theta       : in std_logic_vector (7 downto 0);
		signal cos_theta   : out std_logic_vector (17 downto 0)
	);
end entity cos_table;

architecture behavioral of cos_table is

	signal theta_int              : integer;
	
begin

	theta_int <= to_integer(unsigned(theta));

	cos_t: process (theta_int)
	begin
		case theta_int is
			when 0  =>    cos_theta <= std_logic_vector(to_signed(16384,18));
			when 1  =>    cos_theta <= std_logic_vector(to_signed(16381,18));
			when 2  =>    cos_theta <= std_logic_vector(to_signed(16374,18));
			when 3  =>    cos_theta <= std_logic_vector(to_signed(16361,18));
			when 4  =>    cos_theta <= std_logic_vector(to_signed(16344,18));
			when 5  =>    cos_theta <= std_logic_vector(to_signed(16321,18));
			when 6  =>    cos_theta <= std_logic_vector(to_signed(16294,18));
			when 7  =>    cos_theta <= std_logic_vector(to_signed(16261,18));
			when 8  =>    cos_theta <= std_logic_vector(to_signed(16224,18));
			when 9  =>    cos_theta <= std_logic_vector(to_signed(16182,18));
			when 10  =>    cos_theta <= std_logic_vector(to_signed(16135,18));
			when 11  =>    cos_theta <= std_logic_vector(to_signed(16082,18));
			when 12  =>    cos_theta <= std_logic_vector(to_signed(16025,18));
			when 13  =>    cos_theta <= std_logic_vector(to_signed(15964,18));
			when 14  =>    cos_theta <= std_logic_vector(to_signed(15897,18));
			when 15  =>    cos_theta <= std_logic_vector(to_signed(15825,18));
			when 16  =>    cos_theta <= std_logic_vector(to_signed(15749,18));
			when 17  =>    cos_theta <= std_logic_vector(to_signed(15668,18));
			when 18  =>    cos_theta <= std_logic_vector(to_signed(15582,18));
			when 19  =>    cos_theta <= std_logic_vector(to_signed(15491,18));
			when 20  =>    cos_theta <= std_logic_vector(to_signed(15395,18));
			when 21  =>    cos_theta <= std_logic_vector(to_signed(15295,18));
			when 22  =>    cos_theta <= std_logic_vector(to_signed(15190,18));
			when 23  =>    cos_theta <= std_logic_vector(to_signed(15081,18));
			when 24  =>    cos_theta <= std_logic_vector(to_signed(14967,18));
			when 25  =>    cos_theta <= std_logic_vector(to_signed(14848,18));
			when 26  =>    cos_theta <= std_logic_vector(to_signed(14725,18));
			when 27  =>    cos_theta <= std_logic_vector(to_signed(14598,18));
			when 28  =>    cos_theta <= std_logic_vector(to_signed(14466,18));
			when 29  =>    cos_theta <= std_logic_vector(to_signed(14329,18));
			when 30  =>    cos_theta <= std_logic_vector(to_signed(14188,18));
			when 31  =>    cos_theta <= std_logic_vector(to_signed(14043,18));
			when 32  =>    cos_theta <= std_logic_vector(to_signed(13894,18));
			when 33  =>    cos_theta <= std_logic_vector(to_signed(13740,18));
			when 34  =>    cos_theta <= std_logic_vector(to_signed(13582,18));
			when 35  =>    cos_theta <= std_logic_vector(to_signed(13420,18));
			when 36  =>    cos_theta <= std_logic_vector(to_signed(13254,18));
			when 37  =>    cos_theta <= std_logic_vector(to_signed(13084,18));
			when 38  =>    cos_theta <= std_logic_vector(to_signed(12910,18));
			when 39  =>    cos_theta <= std_logic_vector(to_signed(12732,18));
			when 40  =>    cos_theta <= std_logic_vector(to_signed(12550,18));
			when 41  =>    cos_theta <= std_logic_vector(to_signed(12365,18));
			when 42  =>    cos_theta <= std_logic_vector(to_signed(12175,18));
			when 43  =>    cos_theta <= std_logic_vector(to_signed(11982,18));
			when 44  =>    cos_theta <= std_logic_vector(to_signed(11785,18));
			when 45  =>    cos_theta <= std_logic_vector(to_signed(11585,18));
			when 46  =>    cos_theta <= std_logic_vector(to_signed(11381,18));
			when 47  =>    cos_theta <= std_logic_vector(to_signed(11173,18));
			when 48  =>    cos_theta <= std_logic_vector(to_signed(10963,18));
			when 49  =>    cos_theta <= std_logic_vector(to_signed(10748,18));
			when 50  =>    cos_theta <= std_logic_vector(to_signed(10531,18));
			when 51  =>    cos_theta <= std_logic_vector(to_signed(10310,18));
			when 52  =>    cos_theta <= std_logic_vector(to_signed(10086,18));
			when 53  =>    cos_theta <= std_logic_vector(to_signed(9860,18));
			when 54  =>    cos_theta <= std_logic_vector(to_signed(9630,18));
			when 55  =>    cos_theta <= std_logic_vector(to_signed(9397,18));
			when 56  =>    cos_theta <= std_logic_vector(to_signed(9161,18));
			when 57  =>    cos_theta <= std_logic_vector(to_signed(8923,18));
			when 58  =>    cos_theta <= std_logic_vector(to_signed(8682,18));
			when 59  =>    cos_theta <= std_logic_vector(to_signed(8438,18));
			when 60  =>    cos_theta <= std_logic_vector(to_signed(8191,18));
			when 61  =>    cos_theta <= std_logic_vector(to_signed(7943,18));
			when 62  =>    cos_theta <= std_logic_vector(to_signed(7691,18));
			when 63  =>    cos_theta <= std_logic_vector(to_signed(7438,18));
			when 64  =>    cos_theta <= std_logic_vector(to_signed(7182,18));
			when 65  =>    cos_theta <= std_logic_vector(to_signed(6924,18));
			when 66  =>    cos_theta <= std_logic_vector(to_signed(6663,18));
			when 67  =>    cos_theta <= std_logic_vector(to_signed(6401,18));
			when 68  =>    cos_theta <= std_logic_vector(to_signed(6137,18));
			when 69  =>    cos_theta <= std_logic_vector(to_signed(5871,18));
			when 70  =>    cos_theta <= std_logic_vector(to_signed(5603,18));
			when 71  =>    cos_theta <= std_logic_vector(to_signed(5334,18));
			when 72  =>    cos_theta <= std_logic_vector(to_signed(5062,18));
			when 73  =>    cos_theta <= std_logic_vector(to_signed(4790,18));
			when 74  =>    cos_theta <= std_logic_vector(to_signed(4516,18));
			when 75  =>    cos_theta <= std_logic_vector(to_signed(4240,18));
			when 76  =>    cos_theta <= std_logic_vector(to_signed(3963,18));
			when 77  =>    cos_theta <= std_logic_vector(to_signed(3685,18));
			when 78  =>    cos_theta <= std_logic_vector(to_signed(3406,18));
			when 79  =>    cos_theta <= std_logic_vector(to_signed(3126,18));
			when 80  =>    cos_theta <= std_logic_vector(to_signed(2845,18));
			when 81  =>    cos_theta <= std_logic_vector(to_signed(2563,18));
			when 82  =>    cos_theta <= std_logic_vector(to_signed(2280,18));
			when 83  =>    cos_theta <= std_logic_vector(to_signed(1996,18));
			when 84  =>    cos_theta <= std_logic_vector(to_signed(1712,18));
			when 85  =>    cos_theta <= std_logic_vector(to_signed(1427,18));
			when 86  =>    cos_theta <= std_logic_vector(to_signed(1142,18));
			when 87  =>    cos_theta <= std_logic_vector(to_signed(857,18));
			when 88  =>    cos_theta <= std_logic_vector(to_signed(571,18));
			when 89  =>    cos_theta <= std_logic_vector(to_signed(285,18));
			when 179  =>    cos_theta <= std_logic_vector(to_signed(-16384,18));
			when 178  =>    cos_theta <= std_logic_vector(to_signed(-16381,18));
			when 177  =>    cos_theta <= std_logic_vector(to_signed(-16374,18));
			when 176  =>    cos_theta <= std_logic_vector(to_signed(-16361,18));
			when 175  =>    cos_theta <= std_logic_vector(to_signed(-16344,18));
			when 174  =>    cos_theta <= std_logic_vector(to_signed(-16321,18));
			when 173  =>    cos_theta <= std_logic_vector(to_signed(-16294,18));
			when 172  =>    cos_theta <= std_logic_vector(to_signed(-16261,18));
			when 171  =>    cos_theta <= std_logic_vector(to_signed(-16224,18));
			when 170  =>    cos_theta <= std_logic_vector(to_signed(-16182,18));
			when 169  =>    cos_theta <= std_logic_vector(to_signed(-16135,18));
			when 168  =>    cos_theta <= std_logic_vector(to_signed(-16082,18));
			when 167  =>    cos_theta <= std_logic_vector(to_signed(-16025,18));
			when 166  =>    cos_theta <= std_logic_vector(to_signed(-15964,18));
			when 165  =>    cos_theta <= std_logic_vector(to_signed(-15897,18));
			when 164  =>    cos_theta <= std_logic_vector(to_signed(-15825,18));
			when 163  =>    cos_theta <= std_logic_vector(to_signed(-15749,18));
			when 162  =>    cos_theta <= std_logic_vector(to_signed(-15668,18));
			when 161  =>    cos_theta <= std_logic_vector(to_signed(-15582,18));
			when 160  =>    cos_theta <= std_logic_vector(to_signed(-15491,18));
			when 159  =>    cos_theta <= std_logic_vector(to_signed(-15395,18));
			when 158  =>    cos_theta <= std_logic_vector(to_signed(-15295,18));
			when 157  =>    cos_theta <= std_logic_vector(to_signed(-15190,18));
			when 156  =>    cos_theta <= std_logic_vector(to_signed(-15081,18));
			when 155  =>    cos_theta <= std_logic_vector(to_signed(-14967,18));
			when 154  =>    cos_theta <= std_logic_vector(to_signed(-14848,18));
			when 153  =>    cos_theta <= std_logic_vector(to_signed(-14725,18));
			when 152  =>    cos_theta <= std_logic_vector(to_signed(-14598,18));
			when 151  =>    cos_theta <= std_logic_vector(to_signed(-14466,18));
			when 150  =>    cos_theta <= std_logic_vector(to_signed(-14329,18));
			when 149  =>    cos_theta <= std_logic_vector(to_signed(-14188,18));
			when 148  =>    cos_theta <= std_logic_vector(to_signed(-14043,18));
			when 147  =>    cos_theta <= std_logic_vector(to_signed(-13894,18));
			when 146  =>    cos_theta <= std_logic_vector(to_signed(-13740,18));
			when 145  =>    cos_theta <= std_logic_vector(to_signed(-13582,18));
			when 144  =>    cos_theta <= std_logic_vector(to_signed(-13420,18));
			when 143  =>    cos_theta <= std_logic_vector(to_signed(-13254,18));
			when 142  =>    cos_theta <= std_logic_vector(to_signed(-13084,18));
			when 141  =>    cos_theta <= std_logic_vector(to_signed(-12910,18));
			when 140  =>    cos_theta <= std_logic_vector(to_signed(-12732,18));
			when 139  =>    cos_theta <= std_logic_vector(to_signed(-12550,18));
			when 138  =>    cos_theta <= std_logic_vector(to_signed(-12365,18));
			when 137  =>    cos_theta <= std_logic_vector(to_signed(-12175,18));
			when 136  =>    cos_theta <= std_logic_vector(to_signed(-11982,18));
			when 135  =>    cos_theta <= std_logic_vector(to_signed(-11785,18));
			when 134  =>    cos_theta <= std_logic_vector(to_signed(-11585,18));
			when 133  =>    cos_theta <= std_logic_vector(to_signed(-11381,18));
			when 132  =>    cos_theta <= std_logic_vector(to_signed(-11173,18));
			when 131  =>    cos_theta <= std_logic_vector(to_signed(-10963,18));
			when 130  =>    cos_theta <= std_logic_vector(to_signed(-10748,18));
			when 129  =>    cos_theta <= std_logic_vector(to_signed(-10531,18));
			when 128  =>    cos_theta <= std_logic_vector(to_signed(-10310,18));
			when 127  =>    cos_theta <= std_logic_vector(to_signed(-10086,18));
			when 126  =>    cos_theta <= std_logic_vector(to_signed(-9860,18));
			when 125  =>    cos_theta <= std_logic_vector(to_signed(-9630,18));
			when 124  =>    cos_theta <= std_logic_vector(to_signed(-9397,18));
			when 123  =>    cos_theta <= std_logic_vector(to_signed(-9161,18));
			when 122  =>    cos_theta <= std_logic_vector(to_signed(-8923,18));
			when 121  =>    cos_theta <= std_logic_vector(to_signed(-8682,18));
			when 120  =>    cos_theta <= std_logic_vector(to_signed(-8438,18));
			when 119  =>    cos_theta <= std_logic_vector(to_signed(-8191,18));
			when 118  =>    cos_theta <= std_logic_vector(to_signed(-7943,18));
			when 117  =>    cos_theta <= std_logic_vector(to_signed(-7691,18));
			when 116  =>    cos_theta <= std_logic_vector(to_signed(-7438,18));
			when 115  =>    cos_theta <= std_logic_vector(to_signed(-7182,18));
			when 114  =>    cos_theta <= std_logic_vector(to_signed(-6924,18));
			when 113  =>    cos_theta <= std_logic_vector(to_signed(-6663,18));
			when 112  =>    cos_theta <= std_logic_vector(to_signed(-6401,18));
			when 111  =>    cos_theta <= std_logic_vector(to_signed(-6137,18));
			when 110  =>    cos_theta <= std_logic_vector(to_signed(-5871,18));
			when 109  =>    cos_theta <= std_logic_vector(to_signed(-5603,18));
			when 108  =>    cos_theta <= std_logic_vector(to_signed(-5334,18));
			when 107  =>    cos_theta <= std_logic_vector(to_signed(-5062,18));
			when 106  =>    cos_theta <= std_logic_vector(to_signed(-4790,18));
			when 105  =>    cos_theta <= std_logic_vector(to_signed(-4516,18));
			when 104  =>    cos_theta <= std_logic_vector(to_signed(-4240,18));
			when 103  =>    cos_theta <= std_logic_vector(to_signed(-3963,18));
			when 102  =>    cos_theta <= std_logic_vector(to_signed(-3685,18));
			when 101  =>    cos_theta <= std_logic_vector(to_signed(-3406,18));
			when 100  =>    cos_theta <= std_logic_vector(to_signed(-3126,18));
			when 99  =>    cos_theta <= std_logic_vector(to_signed(-2845,18));
			when 98  =>    cos_theta <= std_logic_vector(to_signed(-2563,18));
			when 97  =>    cos_theta <= std_logic_vector(to_signed(-2280,18));
			when 96  =>    cos_theta <= std_logic_vector(to_signed(-1996,18));
			when 95  =>    cos_theta <= std_logic_vector(to_signed(-1712,18));
			when 94  =>    cos_theta <= std_logic_vector(to_signed(-1427,18));
			when 93  =>    cos_theta <= std_logic_vector(to_signed(-1142,18));
			when 92  =>    cos_theta <= std_logic_vector(to_signed(-857,18));
			when 91  =>    cos_theta <= std_logic_vector(to_signed(-571,18));
			when 90  =>    cos_theta <= std_logic_vector(to_signed(-285,18));
			when others =>  cos_theta <= std_logic_vector(to_signed(-285,18));
		end case;
	end process;

end architecture;
