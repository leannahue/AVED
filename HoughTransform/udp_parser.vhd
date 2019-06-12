library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity udp_parser is
port 
(    
    signal clock        :   in std_logic;
    signal reset        :   in std_logic;
    signal in_dout      :   in  std_logic_vector(7 downto 0); 
    signal in_sof       :   in  std_logic;                    
    signal in_eof       :   in  std_logic;                    
    signal in_empty     :   in  std_logic;                    
    signal in_rd_en     :   out std_logic;                    
    signal out_din      :   out std_logic_vector(7 downto 0);
    signal out_sof      :   out std_logic;                    
    signal out_eof      :   out std_logic;                    
    signal out_full     :   in  std_logic;                   
    signal out_wr_en    :   out std_logic                      
);
end entity udp_parser;

architecture behavior of udp_parser is
  
    type STATE_TYPES is 
    (
        INIT, WAIT_FOR_SOF_STATE, ETH_DST_ADDR_STATE, ETH_SRC_ADDR_STATE, ETH_PROTOCOL, 
        IP_VERSION, IP_TYPE, IP_LENGTH, IP_ID, IP_FLAG, IP_TIME, 
        IP_PROTOCOL, IP_CHECKSUM, IP_SRC_ADDR_STATE, IP_DST_ADDR_STATE, IP_OPTIONS_STATE, 
        UPD_SRC_PORT_STATE, UDP_DST_PORT_STATE, UDP_LENGTH_STATE, UDP_CHECKSUM_STATE, UDP_WRITE_DATA_STATE,
        UDP_VALIDATE_STATE, UDP_READ_DATA_STATE, DONE_STATE  
    );

    function IF_COND( test : boolean; true_cond : std_logic; false_cond : std_logic )
    return std_logic is 
    begin
        if ( test ) then
            return true_cond;
        else
            return false_cond;
        end if;
    end IF_COND;
    
    function IF_COND( test : boolean; true_cond : std_logic_vector; false_cond : std_logic_vector )
    return std_logic_vector is 
    begin
        if ( test ) then
            return true_cond;
        else
            return false_cond;
        end if;
    end IF_COND;

    function slv2hstr(slv: std_logic_vector) return string is
        variable hexlen: integer;
        variable longslv : std_logic_vector(127 downto 0) := (others => '0');
        variable hex : string(1 to 16);
        variable fourbit : std_logic_vector(3 downto 0);
    begin
        hexlen := (slv'left+1)/4;
        if (slv'left+1) mod 4 /= 0 then
            hexlen := hexlen + 1;
        end if;
        longslv(slv'left downto 0) := slv;
        for i in (hexlen -1) downto 0 loop
            fourbit := longslv(((i*4)+3) downto (i*4));
            case fourbit is
                when "0000" => hex(hexlen-i) := '0';
                when "0001" => hex(hexlen-i) := '1';
                when "0010" => hex(hexlen-i) := '2';
                when "0011" => hex(hexlen-i) := '3';
                when "0100" => hex(hexlen-i) := '4';
                when "0101" => hex(hexlen-i) := '5';
                when "0110" => hex(hexlen-i) := '6';
                when "0111" => hex(hexlen-i) := '7';
                when "1000" => hex(hexlen-i) := '8';
                when "1001" => hex(hexlen-i) := '9';
                when "1010" => hex(hexlen-i) := 'A';
                when "1011" => hex(hexlen-i) := 'B';
                when "1100" => hex(hexlen-i) := 'C';
                when "1101" => hex(hexlen-i) := 'D';
                when "1110" => hex(hexlen-i) := 'E';
                when "1111" => hex(hexlen-i) := 'F';
                when "ZZZZ" => hex(hexlen-i) := 'z';
                when "UUUU" => hex(hexlen-i) := 'u';
                when "XXXX" => hex(hexlen-i) := 'x';
                when others => hex(hexlen-i) := '?';
            end case;
        end loop;
        return hex(1 to hexlen);
    end slv2hstr;

    constant ETH_DST_ADDR_BYTES     :   integer := 6;
    constant ETH_SRC_ADDR_BYTES     :   integer := 6;
    constant ETH_PROTOCOL_BYTES     :   integer := 2;
    constant IP_VERSION_BYTES       :   integer := 1;
    constant IP_HEADER_BYTES        :   integer := 1;
    constant IP_TYPE_BYTES          :   integer := 1;
    constant IP_LENGTH_BYTES        :   integer := 2;
    constant IP_ID_BYTES            :   integer := 2;
    constant IP_FLAG_BYTES          :   integer := 2;
    constant IP_TIME_BYTES          :   integer := 1;
    constant IP_PROTOCOL_BYTES      :   integer := 1;
    constant IP_CHECKSUM_BYTES      :   integer := 2;
    constant IP_SRC_ADDR_BYTES      :   integer := 4;
    constant IP_DST_ADDR_BYTES      :   integer := 4;
    constant UDP_DST_PORT_BYTES     :   integer := 2;
    constant UDP_SRC_PORT_BYTES     :   integer := 2;
    constant UDP_LENGTH_BYTES       :   integer := 2;
    constant UDP_CHECKSUM_BYTES     :   integer := 2;
    
    constant IP_PROTOCOL_DEF        :   std_logic_vector((ETH_PROTOCOL_BYTES*8)-1 downto 0) := X"0800";
    constant IP_VERSION_DEF         :   std_logic_vector((IP_VERSION_BYTES*4)-1 downto 0) := X"4";
    constant UDP_PROTOCOL_DEF       :   std_logic_vector((IP_PROTOCOL_BYTES*8)-1 downto 0) := X"11";
    
    signal state                    :   STATE_TYPES;    
    signal next_state               :   STATE_TYPES;    

    signal num_bytes                :   integer;
    signal num_bytes_c              :   integer;
    signal checksum                 :   std_logic_vector(31 downto 0);
    signal checksum_c               :   std_logic_vector(31 downto 0);
    signal udp_bytes                :   integer;
    signal udp_bytes_c              :   integer;

    signal eth_dst_addr             :   std_logic_vector((ETH_SRC_ADDR_BYTES*8)-1 downto 0);
    signal eth_dst_addr_c           :   std_logic_vector((ETH_SRC_ADDR_BYTES*8)-1 downto 0);
    signal eth_src_addr             :   std_logic_vector((ETH_DST_ADDR_BYTES*8)-1 downto 0);
    signal eth_src_addr_c           :   std_logic_vector((ETH_DST_ADDR_BYTES*8)-1 downto 0);
    signal eth_protocol             :   std_logic_vector((ETH_PROTOCOL_BYTES*8)-1 downto 0);        
    signal eth_protocol_c           :   std_logic_vector((ETH_PROTOCOL_BYTES*8)-1 downto 0);        
    signal ip_ver                   :   std_logic_vector((IP_VERSION_BYTES*4)-1 downto 0);        
    signal ip_ver_c                 :   std_logic_vector((IP_VERSION_BYTES*4)-1 downto 0);        
    signal ip_ihl                   :   std_logic_vector((IP_HEADER_BYTES*4)-1 downto 0);        
    signal ip_ihl_c                 :   std_logic_vector((IP_HEADER_BYTES*4)-1 downto 0);        
    signal ip_id                    :   std_logic_vector((IP_ID_BYTES*8)-1 downto 0);
    signal ip_id_c                  :   std_logic_vector((IP_ID_BYTES*8)-1 downto 0);
    signal ip_type                  :   std_logic_vector((IP_TYPE_BYTES*8)-1 downto 0);
    signal ip_type_c                :   std_logic_vector((IP_TYPE_BYTES*8)-1 downto 0);
    signal ip_length                :   std_logic_vector((IP_LENGTH_BYTES*8)-1 downto 0);
    signal ip_length_c              :   std_logic_vector((IP_LENGTH_BYTES*8)-1 downto 0);
    signal ip_flag                  :   std_logic_vector((IP_FLAG_BYTES*8)-1 downto 0);
    signal ip_flag_c                :   std_logic_vector((IP_FLAG_BYTES*8)-1 downto 0);
    signal ip_time                  :   std_logic_vector((IP_TIME_BYTES*8)-1 downto 0);
    signal ip_time_c                :   std_logic_vector((IP_TIME_BYTES*8)-1 downto 0);
    signal ip_protocol              :   std_logic_vector((IP_PROTOCOL_BYTES*8)-1 downto 0);
    signal ip_protocol_c            :   std_logic_vector((IP_PROTOCOL_BYTES*8)-1 downto 0);
    signal ip_checksum              :   std_logic_vector((IP_CHECKSUM_BYTES*8)-1 downto 0);
    signal ip_checksum_c            :   std_logic_vector((IP_CHECKSUM_BYTES*8)-1 downto 0);
    signal ip_dst_addr              :   std_logic_vector((IP_SRC_ADDR_BYTES*8)-1 downto 0);
    signal ip_dst_addr_c            :   std_logic_vector((IP_SRC_ADDR_BYTES*8)-1 downto 0);
    signal ip_src_addr              :   std_logic_vector((IP_DST_ADDR_BYTES*8)-1 downto 0);
    signal ip_src_addr_c            :   std_logic_vector((IP_DST_ADDR_BYTES*8)-1 downto 0);
    signal udp_dst_port             :   std_logic_vector((UDP_DST_PORT_BYTES*8)-1 downto 0);
    signal udp_dst_port_c           :   std_logic_vector((UDP_DST_PORT_BYTES*8)-1 downto 0);
    signal udp_src_port             :   std_logic_vector((UDP_SRC_PORT_BYTES*8)-1 downto 0);
    signal udp_src_port_c           :   std_logic_vector((UDP_SRC_PORT_BYTES*8)-1 downto 0);
    signal udp_length               :   std_logic_vector((UDP_LENGTH_BYTES*8)-1 downto 0);
    signal udp_length_c             :   std_logic_vector((UDP_LENGTH_BYTES*8)-1 downto 0);
    signal udp_checksum             :   std_logic_vector((UDP_CHECKSUM_BYTES*8)-1 downto 0);
    signal udp_checksum_c           :   std_logic_vector((UDP_CHECKSUM_BYTES*8)-1 downto 0);  
    
    signal fifo_wr_din              :   std_logic_vector(7 downto 0);
    signal fifo_wr_full             :   std_logic;
    signal fifo_wr_en               :   std_logic;
    signal fifo_wr_sof              :   std_logic;
    signal fifo_wr_eof              :   std_logic;

    signal fifo_rd_en               :   std_logic;
    signal fifo_rd_sof              :   std_logic;
    signal fifo_rd_eof              :   std_logic;
    signal fifo_rd_dout             :   std_logic_vector(7 downto 0);
    signal fifo_rd_empty            :   std_logic;
    
    signal fifo_reset               :   std_logic;
    signal fifo_clear               :   std_logic;
    signal fifo_clear_c             :   std_logic;
      
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
        
        
    
begin

    udp_fifo : fifo_ctrl
    generic map
    (
        FIFO_DATA_WIDTH     => 8,
        FIFO_BUFFER_SIZE    => 2048
    )
    port map
    (
        reset       => fifo_reset,

        rd_clk      => clock,
        rd_en       => fifo_rd_en,
        rd_dout     => fifo_rd_dout,
        rd_sof      => fifo_rd_sof,
        rd_eof      => fifo_rd_eof,
        rd_empty    => fifo_rd_empty,

        wr_clk      => clock,
        wr_en       => fifo_wr_en,
        wr_din      => fifo_wr_din,
        wr_sof      => fifo_wr_sof,
        wr_eof      => fifo_wr_eof,
        wr_full     => fifo_wr_full        
    );
    
    fifo_reset <= reset or fifo_clear;

    reg_process : process (clock, reset)
    begin
        if ( reset = '1' ) then
            state <= INIT;
            udp_bytes <= 0;
            fifo_clear <= '0';
            checksum <= (others => '0');
            eth_dst_addr <= (others => '0');
            eth_src_addr <= (others => '0');
            eth_protocol <= (others => '0');
            ip_ver <= (others => '0');
            ip_ihl <= (others => '0');
            ip_type <= (others => '0');
            ip_length <= (others => '0');
            ip_id <= (others => '0');
            ip_flag <= (others => '0');
            ip_time <= (others => '0');
            ip_protocol <= (others => '0');
            ip_checksum <= (others => '0');
            ip_dst_addr <= (others => '0');
            ip_src_addr <= (others => '0');
            udp_dst_port <= (others => '0');
            udp_src_port <= (others => '0');
            udp_length <= (others => '0');
            udp_checksum <= (others => '0');  
            num_bytes <= 0;
        elsif ( rising_edge(clock) ) then
            state <= next_state;
            udp_bytes <= udp_bytes_c;
            fifo_clear <= fifo_clear_c;            
            checksum <= checksum_c;
            eth_dst_addr <= eth_dst_addr_c;
            eth_src_addr <= eth_src_addr_c;
            eth_protocol <= eth_protocol_c;
            ip_ver <= ip_ver_c;
            ip_ihl <= ip_ihl_c;
            ip_type <= ip_type_c;
            ip_length <= ip_length_c;
            ip_id <= ip_id_c;
            ip_flag <= ip_flag_c;
            ip_time <= ip_time_c;
            ip_protocol <= ip_protocol_c;
            ip_checksum <= ip_checksum_c;
            ip_dst_addr <= ip_dst_addr_c;
            ip_src_addr <= ip_src_addr_c;
            udp_dst_port <= udp_dst_port_c;
            udp_src_port <= udp_src_port_c;
            udp_length <= udp_length_c;
            udp_checksum <= udp_checksum_c;   
            num_bytes <= num_bytes_c;  
        end if;
    end process reg_process;
             
                    
                    
    udp_ctrl_process : process ( state, num_bytes, num_bytes_c, checksum, udp_bytes, eth_dst_addr, eth_src_addr, 
                                 eth_protocol, ip_ver, ip_ihl, ip_type, ip_length, ip_id, ip_flag, ip_time, ip_protocol, 
                                 ip_checksum, ip_dst_addr, ip_src_addr, udp_dst_port, udp_src_port, udp_length, udp_checksum, 
                                 in_dout, in_sof, in_eof, in_empty, fifo_wr_full, fifo_rd_empty, fifo_rd_dout, fifo_rd_sof, fifo_rd_eof )  
                    
        variable eth_protocol_t           :   std_logic_vector((ETH_PROTOCOL_BYTES*8)-1 downto 0);        
        variable ip_ver_t                 :   std_logic_vector((IP_VERSION_BYTES*4)-1 downto 0);        
        variable ip_length_t              :   std_logic_vector((IP_LENGTH_BYTES*8)-1 downto 0);
        variable ip_time_t                :   std_logic_vector((IP_TIME_BYTES*8)-1 downto 0);
        variable ip_protocol_t            :   std_logic_vector((IP_PROTOCOL_BYTES*8)-1 downto 0);
        variable ip_dst_addr_t            :   std_logic_vector((IP_DST_ADDR_BYTES*8)-1 downto 0);
        variable ip_src_addr_t            :   std_logic_vector((IP_SRC_ADDR_BYTES*8)-1 downto 0);
        variable udp_dst_port_t           :   std_logic_vector((UDP_DST_PORT_BYTES*8)-1 downto 0);
        variable udp_src_port_t           :   std_logic_vector((UDP_SRC_PORT_BYTES*8)-1 downto 0);
        variable udp_length_t             :   std_logic_vector((UDP_LENGTH_BYTES*8)-1 downto 0);
        variable udp_checksum_t           :   std_logic_vector((UDP_CHECKSUM_BYTES*8)-1 downto 0);    

    begin

        -- default assignments for each state
        num_bytes_c <= num_bytes;

        in_rd_en <= '0';      

        out_wr_en <= '0';
        out_din <= (others => '0');
        out_sof <= '0';
        out_eof <= '0';

        fifo_rd_en <= '0';
        fifo_wr_din <= (others => '0');
        fifo_wr_en <= '0';
        fifo_wr_sof <= '0';
        fifo_wr_eof <= '0';
        fifo_clear_c <= '0';
        
        -- signals
        next_state <= state;
        checksum_c <= checksum;
        eth_dst_addr_c <= eth_dst_addr;
        eth_src_addr_c <= eth_src_addr;
        eth_protocol_c <= eth_protocol;
        ip_ver_c <= ip_ver;
        ip_ihl_c <= ip_ihl;
        ip_type_c <= ip_type;
        ip_length_c <= ip_length;
        ip_id_c <= ip_id;
        ip_flag_c <= ip_flag;
        ip_time_c <= ip_time;
        ip_protocol_c <= ip_protocol;
        ip_checksum_c <= ip_checksum;
        ip_dst_addr_c <= ip_dst_addr;
        ip_src_addr_c <= ip_src_addr;
        udp_dst_port_c <= udp_dst_port;
        udp_src_port_c <= udp_src_port;
        udp_length_c <= udp_length;
        udp_checksum_c <= udp_checksum;    
        udp_bytes_c <= udp_bytes;

        -- variables
        eth_protocol_t := (others => '0');
        ip_ver_t := (others => '0');
        ip_length_t := (others => '0');
        ip_time_t := (others => '0');
        ip_protocol_t := (others => '0');
        ip_dst_addr_t := (others => '0');
        ip_src_addr_t := (others => '0');
        udp_dst_port_t := (others => '0');
        udp_src_port_t := (others => '0');
        udp_length_t := (others => '0');
        udp_checksum_t := (others => '0');        
                    
        case ( state ) is                                    
                
            when INIT =>
                udp_bytes_c <= 0;
                eth_dst_addr_c <= (others => '0');
                eth_src_addr_c <= (others => '0');
                eth_protocol_c <= (others => '0');
                ip_ver_c <= (others => '0');
                ip_ihl_c <= (others => '0');
                ip_type_c <= (others => '0');
                ip_length_c <= (others => '0');
                ip_id_c <= (others => '0');
                ip_flag_c <= (others => '0');
                ip_time_c <= (others => '0');
                ip_protocol_c <= (others => '0');
                ip_checksum_c <= (others => '0');
                ip_dst_addr_c <= (others => '0');
                ip_src_addr_c <= (others => '0');
                udp_dst_port_c <= (others => '0');
                udp_src_port_c <= (others => '0');
                udp_length_c <= (others => '0');
                udp_checksum_c <= (others => '0');
                checksum_c <= (others => '0');
                num_bytes_c <= 0;
                next_state <= WAIT_FOR_SOF_STATE;
                
            when WAIT_FOR_SOF_STATE =>
                -- wait for start-of-frame 
                if ( (in_sof = '1') and (in_empty = '0') ) then
                    next_state <= ETH_DST_ADDR_STATE;
                elsif ( in_empty = '0' ) then
                    in_rd_en <= '1';
                end if;
                
            when ETH_DST_ADDR_STATE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    eth_dst_addr_c <= std_logic_vector((unsigned(eth_dst_addr) sll 8) or resize(unsigned(in_dout),ETH_DST_ADDR_BYTES*8));
                    num_bytes_c <= (num_bytes + 1) mod ETH_DST_ADDR_BYTES;                        
                    if ( num_bytes = ETH_DST_ADDR_BYTES-1 ) then
                        next_state <= ETH_SRC_ADDR_STATE;                        
                    end if;
                end if;

            when ETH_SRC_ADDR_STATE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    eth_src_addr_c <= std_logic_vector((unsigned(eth_src_addr) sll 8) or resize(unsigned(in_dout),ETH_SRC_ADDR_BYTES*8));
                    num_bytes_c <= (num_bytes + 1) mod ETH_SRC_ADDR_BYTES;                        
                    if ( num_bytes = ETH_SRC_ADDR_BYTES-1 ) then
                        next_state <= ETH_PROTOCOL;                        
                    end if;
                end if;
                
            when ETH_PROTOCOL =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    eth_protocol_t := std_logic_vector((unsigned(eth_protocol) sll 8) or resize(unsigned(in_dout),ETH_PROTOCOL_BYTES*8));
                    eth_protocol_c <= eth_protocol_t;
                    num_bytes_c <= (num_bytes + 1) mod ETH_PROTOCOL_BYTES;                        
                    if ( num_bytes = ETH_PROTOCOL_BYTES-1 ) then
                        if ( eth_protocol_t = IP_PROTOCOL_DEF ) then
                            next_state <= IP_VERSION;
                        else
                            report "ERROR: Bad Ethernet Protocol: " & slv2hstr(eth_protocol_t);
                            next_state <= INIT;
                        end if;
                    end if;
                end if;
                    
            when IP_VERSION =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_ver_t := in_dout(7 downto 4);
                    ip_ver_c <= ip_ver_t;
                    ip_ihl_c <= in_dout(3 downto 0);
                    if ( ip_ver_t = IP_VERSION_DEF ) then
                        next_state <= IP_TYPE;
                    else
                        report "ERROR: Incorrect IP Version!";
                        next_state <= INIT;
                    end if;
                end if;

            when IP_TYPE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_type_c <= std_logic_vector((unsigned(ip_type) sll 8) or resize(unsigned(in_dout),IP_TYPE_BYTES*8));
                    num_bytes_c <= (num_bytes + 1) mod IP_TYPE_BYTES;                        
                    if ( num_bytes = IP_TYPE_BYTES-1 ) then
                        next_state <= IP_LENGTH;                        
                    end if;
                end if;
                          
            when IP_LENGTH =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_length_t := std_logic_vector((unsigned(ip_length) sll 8) or resize(unsigned(in_dout),IP_LENGTH_BYTES*8));
                    ip_length_c <= ip_length_t;
                    num_bytes_c <= (num_bytes + 1) mod IP_LENGTH_BYTES;                        
                    if ( num_bytes = IP_LENGTH_BYTES-1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(ip_length_t),32) - to_unsigned(20,32));
                        report "IP Length: " & slv2hstr(ip_length_t);
                        next_state <= IP_ID;                        
                    end if;
                end if;
                                                          
            when IP_ID => 
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_id_c <= std_logic_vector((unsigned(ip_id) sll 8) or resize(unsigned(in_dout),IP_ID_BYTES*8));
                    num_bytes_c <= (num_bytes + 1) mod IP_ID_BYTES;                        
                    if ( num_bytes = IP_ID_BYTES-1 ) then
                        next_state <= IP_FLAG; 
                    end if;
                end if;
                                
            when IP_FLAG =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_flag_c <= std_logic_vector((unsigned(ip_flag) sll 8) or resize(unsigned(in_dout),IP_FLAG_BYTES*8));
                    num_bytes_c <= (num_bytes + 1) mod IP_FLAG_BYTES;                        
                    if ( num_bytes = IP_FLAG_BYTES-1 ) then
                        next_state <= IP_TIME;                        
                    end if;
                end if;
                                
            when IP_TIME =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_time_t := std_logic_vector((unsigned(ip_time) sll 8) or resize(unsigned(in_dout),IP_TIME_BYTES*8));
                    ip_time_c <= ip_time_t;
                    num_bytes_c <= (num_bytes + 1) mod IP_TIME_BYTES;                        
                    if ( num_bytes = IP_TIME_BYTES-1 ) then
                        if ( ip_time_t = std_logic_vector(to_unsigned(0,IP_TIME_BYTES*8)) ) then
                            report "IP time at zero! Skipping...";
                            next_state <= INIT;
                        else
                            next_state <= IP_PROTOCOL;
                        end if;
                    end if;                
                end if;
            
            
            when IP_PROTOCOL => 
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_protocol_t := std_logic_vector((unsigned(ip_protocol) sll 8) or resize(unsigned(in_dout),IP_PROTOCOL_BYTES*8));
                    ip_protocol_c <= ip_protocol_t;
                    num_bytes_c <= (num_bytes + 1) mod IP_PROTOCOL_BYTES;                        
                    if ( num_bytes = IP_PROTOCOL_BYTES-1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(ip_protocol_t),32));
                        if ( ip_protocol_t = UDP_PROTOCOL_DEF ) then                                
                            next_state <= IP_CHECKSUM;                        
                        else
                            report "ERROR: Incorrect IP Protocol!";
                            next_state <= INIT;
                        end if;                            
                    end if;
                end if;

            when IP_CHECKSUM => 
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_checksum_c <= std_logic_vector((unsigned(ip_checksum) sll 8) or resize(unsigned(in_dout),IP_CHECKSUM_BYTES*8));
                    num_bytes_c <= (num_bytes + 1) mod IP_CHECKSUM_BYTES;                        
                    if ( num_bytes = IP_CHECKSUM_BYTES-1 ) then
                        next_state <= IP_SRC_ADDR_STATE;                        
                    end if;
                end if;

            when IP_SRC_ADDR_STATE => 
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_src_addr_t := std_logic_vector((unsigned(ip_src_addr) sll 8) or resize(unsigned(in_dout),IP_SRC_ADDR_BYTES*8));
                    ip_src_addr_c <= ip_src_addr_t;
                    num_bytes_c <= (num_bytes + 1) mod IP_SRC_ADDR_BYTES;                        
                    if ( num_bytes = IP_SRC_ADDR_BYTES-1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(ip_src_addr_t(31 downto 16)),32) + resize(unsigned(ip_src_addr_t(15 downto 0)),32));
                        next_state <= IP_DST_ADDR_STATE;
                    end if;
                end if;

            when IP_DST_ADDR_STATE => 
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    ip_dst_addr_t := std_logic_vector((unsigned(ip_dst_addr) sll 8) or resize(unsigned(in_dout),IP_DST_ADDR_BYTES*8));
                    ip_dst_addr_c <= ip_dst_addr_t;
                    num_bytes_c <= (num_bytes + 1) mod IP_DST_ADDR_BYTES;                        
                    if ( num_bytes = IP_DST_ADDR_BYTES-1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(ip_dst_addr_t(31 downto 16)),32) + resize(unsigned(ip_dst_addr_t(15 downto 0)),32));
                        if ( unsigned(ip_ihl) > to_unsigned(5,4) ) then                            
                            next_state <= IP_OPTIONS_STATE;
                        else
                            next_state <= UPD_SRC_PORT_STATE;
                        end if;
                    end if;
                end if;
           
            when IP_OPTIONS_STATE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    num_bytes_c <= (num_bytes + 1);                        
                    if ( num_bytes = (to_integer(unsigned(ip_ihl)) - 6) ) then
                        num_bytes_c <= 0;
                        next_state <= UPD_SRC_PORT_STATE;
                    end if;
                end if;

            when UPD_SRC_PORT_STATE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    udp_src_port_t := std_logic_vector((unsigned(udp_src_port) sll 8) or resize(unsigned(in_dout),UDP_SRC_PORT_BYTES*8));
                    udp_src_port_c <= udp_src_port_t;
                    num_bytes_c <= (num_bytes + 1) mod UDP_SRC_PORT_BYTES;                        
                    if ( num_bytes = UDP_SRC_PORT_BYTES-1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(udp_src_port_t),32));
                        next_state <= UDP_DST_PORT_STATE;
                    end if;
                end if;

            when UDP_DST_PORT_STATE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    udp_dst_port_t := std_logic_vector((unsigned(udp_dst_port) sll 8) or resize(unsigned(in_dout),UDP_DST_PORT_BYTES*8));
                    udp_dst_port_c <= udp_dst_port_t;
                    num_bytes_c <= (num_bytes + 1) mod UDP_DST_PORT_BYTES;                        
                    if ( num_bytes = UDP_DST_PORT_BYTES-1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(udp_dst_port_t),32));
                        next_state <= UDP_LENGTH_STATE;
                    end if;
                end if;

            when UDP_LENGTH_STATE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    udp_length_t := std_logic_vector((unsigned(udp_length) sll 8) or resize(unsigned(in_dout),UDP_LENGTH_BYTES*8));
                    udp_length_c <= udp_length_t;
                    num_bytes_c <= (num_bytes + 1) mod UDP_LENGTH_BYTES;                        
                    if ( num_bytes = UDP_LENGTH_BYTES-1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(udp_length_t),32));
                        next_state <= UDP_CHECKSUM_STATE;                        
                    end if;
                end if;

            when UDP_CHECKSUM_STATE =>
                if ( in_empty = '0' ) then
                    in_rd_en <= '1';
                    udp_checksum_t := std_logic_vector((unsigned(udp_checksum) sll 8) or resize(unsigned(in_dout),UDP_CHECKSUM_BYTES*8));
                    udp_checksum_c <= udp_checksum_t;
                    num_bytes_c <= (num_bytes + 1) mod UDP_CHECKSUM_BYTES;                        
                    if ( num_bytes = UDP_CHECKSUM_BYTES-1 ) then
                        udp_bytes_c <= to_integer(resize(unsigned(udp_length),32)) - UDP_CHECKSUM_BYTES - UDP_LENGTH_BYTES - UDP_DST_PORT_BYTES - UDP_SRC_PORT_BYTES;
                        next_state <= UDP_WRITE_DATA_STATE;                        
                    end if;
                end if;

            when UDP_WRITE_DATA_STATE =>
                if ( in_empty = '0' AND fifo_wr_full = '0' ) then
                    in_rd_en <= '1';
                    fifo_wr_en <= '1';
                    fifo_wr_din <= in_dout;
                    fifo_wr_sof <= if_cond(num_bytes = 0, '1', '0');
                    fifo_wr_eof <= if_cond((in_eof = '1') or (num_bytes = udp_bytes-1), '1', '0');
                    num_bytes_c <= (num_bytes + 1);
                    if ( (num_bytes mod 2) = 1 ) then
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize(unsigned(in_dout),32));
                    else 
                        checksum_c <= std_logic_vector(unsigned(checksum) + resize((unsigned(in_dout) & X"00"),32));
                    end if;
                    if ( (in_eof = '1') or (num_bytes = udp_bytes-1) ) then  
                        next_state <= UDP_VALIDATE_STATE;
                    end if;
                 end if;

            when UDP_VALIDATE_STATE =>
                if ( checksum(31 downto 16) /= X"0000" ) then
                    checksum_c <= std_logic_vector(unsigned(X"0000" & checksum(31 downto 16)) + unsigned(X"0000" & checksum(15 downto 0)));
                elsif ( udp_checksum = (not checksum(15 downto 0)) ) then
                    next_state <= UDP_READ_DATA_STATE;
                else 
                    fifo_clear_c <= '1';
                    next_state <= DONE_STATE;
                end if;  

            when UDP_READ_DATA_STATE =>
                if ( fifo_rd_empty = '1' ) then
                    next_state <= DONE_STATE;
                elsif ( out_full = '0' ) then
                    fifo_rd_en <= '1';
                    out_wr_en <= '1';
                    out_din <= fifo_rd_dout;
                    out_sof <= fifo_rd_sof;
                    out_eof <= fifo_rd_eof;
                end if;

            when DONE_STATE =>
                next_state <= INIT;

            when OTHERS => 
                fifo_wr_din <= (others => 'X');
                fifo_wr_en <= 'X';
                fifo_clear_c <= 'X';
                udp_bytes_c <= 0;
                eth_dst_addr_c <= (others => 'X');
                eth_src_addr_c <= (others => 'X');
                eth_protocol_c <= (others => 'X');
                ip_ver_c <= (others => 'X');
                ip_ihl_c <= (others => 'X');
                ip_type_c <= (others => 'X');
                ip_length_c <= (others => 'X');
                ip_id_c <= (others => 'X');
                ip_flag_c <= (others => 'X');
                ip_time_c <= (others => 'X');
                ip_protocol_c <= (others => 'X');
                ip_checksum_c <= (others => 'X');
                ip_dst_addr_c <= (others => 'X');
                ip_src_addr_c <= (others => 'X');
                udp_dst_port_c <= (others => 'X');
                udp_src_port_c <= (others => 'X');
                udp_length_c <= (others => 'X');
                udp_checksum_c <= (others => 'X');
                checksum_c <= (others => 'X');
                eth_protocol_t := (others => 'X');
                ip_ver_t := (others => 'X');
                ip_length_t := (others => 'X');
                ip_time_t := (others => 'X');
                ip_protocol_t := (others => 'X');
                ip_dst_addr_t := (others => 'X');
                ip_src_addr_t := (others => 'X');
                udp_dst_port_t := (others => 'X');
                udp_src_port_t := (others => 'X');
                udp_length_t := (others => 'X');
                udp_checksum_t := (others => 'X');
                in_rd_en <= 'X';          
                num_bytes_c <= 0;            
                next_state <= INIT;
            
        end case;
                            
    end process udp_ctrl_process;
    
end architecture behavior;
