library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TopLevel_tb is
end entity TopLevel_tb;

architecture test of TopLevel_tb is

constant CLK_PERIOD : time := 20 ns;
CONSTANT BurstBits : INTEGER := 3;


signal clk 					 : std_logic;
signal nReset				 : std_logic;

signal AM_readData 		 :  std_logic_vector(63 downto 0);
signal AM_read 			 :  std_logic;
signal AM_address 		 :  std_logic_vector(31 downto 0);
signal am_readdatavalid  :  std_logic;
signal AM_WaitRequest 	 :  std_logic;
signal AM_BurstCount 		 :  std_logic_vector(3 downto 0);
signal am_writeData 	 	 :  std_logic_vector(63 downto 0);
signal am_write 			 :  std_logic;

signal as_address   		:  std_logic_vector(2 downto 0);
signal as_write     		:  std_logic;
signal as_read      		:  std_logic;
signal as_writedata 		:  std_logic_vector(31 downto 0);
signal as_readdata  		:  std_logic_vector(31 downto 0);
signal done				: std_logic;
begin

	UUT: entity work.TopLevel
	port map(
		  clk => clk,
        nReset => nReset,

        am_address => am_address,
		  am_writeData => am_writeData,	 
		  am_write => am_write,
		  am_waitRequest => am_waitRequest,
		  am_burstCount => am_burstCount,
		  am_read => am_read,
		  am_readdata => am_readdata,
		  am_readdatavalid => am_readdatavalid,
		  
		  as_address => as_address,
		  as_write => as_write,    
		  as_read => as_read,     
		  as_writedata => as_writedata,
		  as_readdata  => as_readdata,
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

procedure one_burst is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	AM_readdatavalid <= '1';
	AM_readdata <= (others => '0');
	wait for CLK_PERIOD;
	AM_readdata <= (others => '1');
	wait for CLK_PERIOD;
	AM_readdata <= (others => '0');
	wait for CLK_PERIOD;
	AM_readdata <= (others => '1');
	
	wait for CLK_PERIOD;
	AM_readdatavalid <= '0';
	
	wait for 4 * CLK_PERIOD;
	
	AM_readdatavalid <= '1';
	AM_readdata <= (others => '0');
	wait for CLK_PERIOD;
	AM_readdata <= (others => '1');
	wait for CLK_PERIOD;
	AM_readdata <= (others => '0');
	wait for CLK_PERIOD;
	AM_readdata <= (others => '1');
	wait for CLK_PERIOD;
	AM_readdatavalid <= '0';
	
end procedure one_burst;


procedure one_burst2 is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	AM_readdatavalid <= '1';
	AM_readdata <= x"ffff0000ffff0000";
	wait for CLK_PERIOD;
	AM_readdata <= x"0000ffff0000ffff";
	wait for CLK_PERIOD;
	AM_readdata <= x"ffff0000ffff0000";
	wait for CLK_PERIOD;
	AM_readdata <= x"0000ffff0000ffff";
	
	wait for CLK_PERIOD;
	AM_readdatavalid <= '0';
	
	wait for 4 * CLK_PERIOD;
	
	AM_readdatavalid <= '1';
	AM_readdata <= x"ffff0000ffff0000";
	wait for CLK_PERIOD;
	AM_readdata <= x"0000ffff0000ffff";
	wait for CLK_PERIOD;
	AM_readdata <= x"ffff0000ffff0000";
	wait for CLK_PERIOD;
	AM_readdata <= x"0000ffff0000ffff";
	wait for CLK_PERIOD;
	AM_readdatavalid <= '0';
	
end procedure one_burst2;


procedure write_read_add is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	as_address <= "000";
	as_write <= '1';
	as_writedata <= x"10101010";
	wait for CLK_PERIOD;
	as_write <= '0';
	
	
end procedure write_read_add;

procedure write_write_add is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	as_address <= "001";
	as_write <= '1';
	as_writedata <= x"10101010";
	wait for CLK_PERIOD;
	as_write <= '0';
	
	
end procedure write_write_add;


procedure write_complexity is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	as_address <= "100";
	as_write <= '1';
	as_writedata <= x"00000004";
	wait for CLK_PERIOD;
	as_write <= '0';
	
	
end procedure write_complexity;


procedure write_num_block is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	as_address <= "010";
	as_write <= '1';
	as_writedata <= x"00000002";
	wait for CLK_PERIOD;
	as_write <= '0';
	
	
end procedure write_num_block;

procedure write_start is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	as_address <= "011";
	as_write <= '1';
	as_writedata <= x"00000001";
	wait for CLK_PERIOD;
	as_write <= '0';
	
	
end procedure write_start;


procedure write_nonce_incr is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	as_address <= "101";
	as_write <= '1';
	as_writedata <= x"00000002";
	wait for CLK_PERIOD;
	as_write <= '0';
	
	
end procedure write_nonce_incr;

procedure reset_start is
begin

	wait until rising_edge(CLK);
	wait for CLK_PERIOD / 4;
	as_address <= "011";
	as_write <= '1';
	as_writedata <= x"00000000";
	wait for CLK_PERIOD;
	as_write <= '0';
	
	
end procedure reset_start;



begin

	
	nReset <= '1';
	async_reset;
	wait for 3*clk_period;
	
	am_waitRequest <= '0';
	
	write_read_add;
	
	write_write_add;
	
	write_complexity;
	
	write_num_block;
	
	write_nonce_incr;
	
	write_start;
	
	wait until am_read = '1';
	one_burst;
	
	wait until am_read = '1';
	one_burst2;
	
	wait until done = '1';
	
	reset_start;
	

	
	
	wait;
end process simulation;


end test;