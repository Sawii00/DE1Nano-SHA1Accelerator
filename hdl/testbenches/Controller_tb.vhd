library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Controller_tb is
end entity Controller_tb;

architecture test of Controller_tb is

constant CLK_PERIOD : time := 20 ns;

signal clk 					 : std_logic;
signal nReset 				 : std_logic;
 
 --Slave
signal read_add_reg 		 : std_logic_vector(31 downto 0);
signal write_add_reg 	 : std_logic_vector(31 downto 0);
signal num_block 			 : std_logic_vector(31 downto 0);
signal start_reg 			 : std_logic_vector(31 downto 0);
signal complexity_reg 	 : std_logic_vector(31 downto 0);
signal set_done			 : std_logic;
 
 --DMA
signal start_read			 : std_logic;
signal done_read			 : std_logic;
signal read_address		 : std_logic_vector(31 downto 0);
signal start_write		 : std_logic;
signal done_write			 : std_logic;
signal write_address		 : std_logic_vector(31 downto 0);
 
 --DMA and Hasher
signal nonce				 : std_logic_vector(31 downto 0);
 
 --Hasher
signal start_hash			 : std_logic;
signal done_hash			 : std_logic;
signal en_nonce			 : std_logic;
signal hash					 : std_logic_vector(159 downto 0);
 
signal done 				 : std_logic;

--debug
signal st					 : std_logic_vector(2 downto 0);

begin

	UUT: entity work.Controller
	port map(
	 clk => clk, 					 
    nReset => nReset,				 
	 
	 --Slave
	 read_add_reg => read_add_reg,		 
	 write_add_reg => write_add_reg, 	 
	 num_block => num_block,			 
	 start_reg => start_reg,			 
	 complexity_reg => complexity_reg,	 
	 set_done => set_done,			 

	 --DMA
	 start_read	=> start_read,		 
	 done_read => done_read,			 
	 read_address => read_address,		 
	 start_write => start_write,		 
	 done_write	=> done_write,		 
	 write_address	=> write_address,	 
	 
	 --DMA and Hasher
	 nonce => nonce,				 
	 
	 --Hasher
	 start_hash	=> start_hash,		 
	 done_hash => done_hash,		 
	 en_nonce => en_nonce,			 
	 hash	 => hash,
	 st => st,
	 
	 done => done 				 
		);

-- Generate CLK signal
clk_generation : process
begin
	
	CLK <= '1';
	wait for CLK_PERIOD / 2;
	CLK <= '0';
	wait for CLK_PERIOD / 2;

end process clk_generation;


simulation : process

procedure async_reset is
begin
	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	nReset <= '0';
	wait for 3 * CLK_PERIOD / 4;
	nReset <= '1';
end procedure async_reset;

begin

	nReset <= '1';
	async_reset;
	wait for 3*clk_period;
	
	write_add_reg <= x"01010101";
	read_add_reg <= x"01010101";
	num_block <= x"00000001";
	complexity_reg <= x"00000009";
	wait for clk_period;
	
	--read
	start_reg <= x"00000001";
	wait for 8*clk_period;
	done_read <= '1';
	wait for clk_period;
	done_read <= '0';
	
	--hash
	wait for 10*clk_period;
	wait for clk_period/4;
	done_hash <= '1';
	hash <= x"0fffffffffffffffffffffffffffffffffffffff";
	wait for clk_period;
	done_hash <= '0';
	
	--hash2
	wait for 10*clk_period;
	done_hash <= '1';
	hash <= x"00ffffffffffffffffffffffffffffffffffffff";
	wait for clk_period;
	done_hash <= '0';
	
	--hash3
	wait for 10*clk_period;
	done_hash <= '1';
	hash <= x"000fffffffffffffffffffffffffffffffffffff";
	wait for clk_period;
	done_hash <= '0';

	--write
	wait for 5*clk_period;
	done_write <= '1';
	wait for clk_period;
	done_write <= '0';
	
	wait for 2*clk_period;
	start_reg <= (others => '0');
	
	
	wait;
end process simulation;


end test;