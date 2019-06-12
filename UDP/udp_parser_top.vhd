
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity udp_parser_top is
port
(
	signal clock        :   in 	std_logic;
	signal reset        :   in 	std_logic;

	-- input data FIFO stream
	signal in_din       :   in  std_logic_vector(7 downto 0); -- FIFO data
	signal in_sof       :   in  std_logic;                    -- FIFO start of frame
	signal in_eof       :   in  std_logic;                    -- FIFO end of frame
	signal in_full      :   out std_logic;                    -- FIFO is full 
	signal in_wr_en     :   in  std_logic;                    -- FIFO wr enable

	-- output data FIFO stream
	signal out_dout     :   out std_logic_vector(7 downto 0); -- FIFO data
	signal out_sof      :   out std_logic;                    -- FIFO start of frame
	signal out_eof      :   out std_logic;                    -- FIFO end of frame
	signal out_empty    :   out std_logic;                    -- FIFO is empty
	signal out_rd_en    :   in	std_logic                     -- FIFO rd enable
);
end entity udp_parser_top;


architecture structure of udp_reader is 


    component fifo_ctrl is
    generic
    (
        constant FIFO_DATA_WIDTH : integer := 32;
        constant FIFO_BUFFER_SIZE : integer := 256
    );
    port
    (
        signal reset    : in std_logic;

        signal rd_clk   : in std_logic;
        signal rd_en    : in std_logic;
        signal rd_dout  : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
        signal rd_empty : out std_logic;
        signal rd_sof   : out std_logic;
        signal rd_eof   : out std_logic;

        signal wr_clk   : in std_logic;
        signal wr_en    : in std_logic;
        signal wr_din   : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
        signal wr_full  : out std_logic;
        signal wr_sof   : in std_logic;
        signal wr_eof   : in std_logic
    );
    end component fifo_ctrl;

    component udp is
    port 
    (    
        signal clock        :   in std_logic;
        signal reset        :   in std_logic;

        -- input data FIFO stream
        signal in_dout      :   in  std_logic_vector(7 downto 0); -- FIFO data
        signal in_sof       :   in  std_logic;                    -- FIFO start of frame
        signal in_eof       :   in  std_logic;                    -- FIFO end of frame
        signal in_empty     :   in  std_logic;                    -- FIFO is empty
        signal in_rd_en     :   out std_logic;                    -- FIFO rd enable

        -- output data FIFO stream
        signal out_din      :   out std_logic_vector(7 downto 0); -- FIFO data
        signal out_sof      :   out std_logic;                    -- FIFO start of frame
        signal out_eof      :   out std_logic;                    -- FIFO end of frame
        signal out_full     :   in  std_logic;                     -- FIFO is full 
        signal out_wr_en    :   out std_logic                      -- FIFO wr enable
    );
    end component udp;


	signal rd_en 	: std_logic;
	signal rd_dout 	: std_logic_vector (7 downto 0);
	signal rd_empty : std_logic;
	signal rd_sof 	: std_logic;
	signal rd_eof 	: std_logic;

	signal wr_en 	: std_logic;
	signal wr_din 	: std_logic_vector (7 downto 0);
	signal wr_full 	: std_logic;
	signal wr_sof 	: std_logic;
	signal wr_eof 	: std_logic;

begin


	udp_inst : component udp
	port map
	(
		clock  		=> clock,
		reset      	=> reset,

		in_dout    	=> rd_dout,
		in_sof     	=> rd_sof,
		in_eof     	=> rd_eof,
		in_rd_en    => rd_en,
		in_empty    => rd_empty,

		out_din     => wr_din,
		out_sof     => wr_sof,
		out_eof     => wr_eof,
		out_wr_en   => wr_en,	
		out_full    => wr_full
	);


    in_fifo : fifo_ctrl
    generic map
    (
        FIFO_DATA_WIDTH     => 8,
        FIFO_BUFFER_SIZE    => 256
    )
    port map
    (
        reset       => reset,

        rd_clk      => clock,
        rd_en       => rd_en,
        rd_dout     => rd_dout,
        rd_sof      => rd_sof,
        rd_eof      => rd_eof,
        rd_empty    => rd_empty,

        wr_clk      => clock,
        wr_en       => in_wr_en,
        wr_din      => in_din,
        wr_sof      => in_sof,
        wr_eof      => in_eof,
        wr_full     => in_full        
	);
	

    out_fifo : fifo_ctrl
    generic map
    (
        FIFO_DATA_WIDTH     => 8,
        FIFO_BUFFER_SIZE    => 256
    )
    port map
    (
        reset       => reset,

        rd_clk      => clock,
        rd_en       => out_rd_en,
        rd_dout     => out_dout,
        rd_sof      => out_sof,
        rd_eof      => out_eof,
        rd_empty    => out_empty,

        wr_clk      => clock,
        wr_en       => wr_en,
        wr_din      => wr_din,
        wr_sof      => wr_sof,
        wr_eof      => wr_eof,
        wr_full     => wr_full         
    );	
	
end architecture structure;
