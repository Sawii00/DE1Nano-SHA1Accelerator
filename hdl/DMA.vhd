library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMA is
    generic (
        BurstSize_read : integer := 8;
		  BurstSize_write : integer := 3;
        BurstBits 	: integer := 3
    );
    port(
	 
    clk 					 : in std_logic;
    nReset 				 : in std_logic;
	 	
	 --read		
	 read_address 		 : in std_logic_vector(31 downto 0);
	 start_read 		 : in std_logic;
	 done_read			 : out std_logic;
	 index				 : out std_logic_vector(BurstBits - 1 downto 0);
	 en_block 			 : out std_logic;
	 output				 : out std_logic_vector(63 downto 0);
	 
	 --write
	 write_address 	 : in std_logic_vector(31 downto 0);
	 start_write 		 : in std_logic;
	 done_write			 : out std_logic;
	 hash					 : in std_logic_vector(159 downto 0);
	 nonce				 : in std_logic_vector(31 downto 0);
 
	--Avalon
    am_address 		 : out std_logic_vector(31 downto 0);
	 am_waitRequest 	 : in std_logic;
    am_burstCount 	 : out std_logic_vector(BurstBits downto 0);
	 am_read           : out std_logic;
	 am_readdata       : in std_logic_vector(63 DOWNTO 0);
	 am_readdatavalid  : in std_logic;
    am_writeData 	 	 : out std_logic_vector(63 downto 0);
    am_write 			 : out std_logic



);
end DMA;

architecture arch of DMA is

   type MasterState is (Idle, ReadReq, Read, Write, WaitStateRead, WaitStateWrite);
	signal state, next_state       : MasterState;
	signal count_read, count_write : unsigned(2 downto 0);
		
	constant zero : unsigned(BurstBits - 1 downto 0) := (others => '0');



begin


	state_reg: process(clk, nReset)
	begin
		if nReset = '0' then
			state <= Idle;
		elsif rising_edge(clk) then
			state <= next_state;
		end if;
	end process;


	FSM: process(state, start_read, read_address, am_waitRequest, am_readdatavalid, count_read, start_write, write_address, count_write, nonce, hash)
	begin
	
		next_state 		<= state;
		am_read 			<= '0';
		am_write 		<= '0';
		am_writeData 	<= (others => '0');
		am_address 		<= (others => '0');
	   am_burstCount 	<= (others => '0');
		done_read 		<= '0';
		done_write 		<= '0';
		
		case (state) is
		
			when Idle =>
				if start_read = '1' then
					next_state <= ReadReq;
				elsif start_write = '1' then
					next_state <= Write;
				end if;
				
			when ReadReq =>
				am_burstcount <= std_logic_vector(to_unsigned(BurstSize_read, am_burstCount'length));
				am_read 		<= '1';
				am_address 	<= read_address;
				if am_waitRequest = '0' then
					next_state 	<= Read;
				end if;
				
			when Read =>
				if count_read = zero and am_readdatavalid = '1' then
					next_state <= WaitStateRead;
				end if;
				
			when WaitStateRead =>
				done_read <= '1';
				if start_read = '0' then
					next_state <= Idle;
				end if;
				
			when Write =>
				am_write <= '1';
				am_address <= write_address;
				am_burstCount <= std_logic_vector(to_unsigned(BurstSize_write, am_burstCount'length));
				case (count_write) is
					when "010" => am_writeData <= hash(159 downto 96);
					when "001" => am_writeData <= hash(95 downto 32);
					when "000" => am_writeData <= hash(31 downto 0) & nonce;
					
					when others => null;
				end case;
				if count_write = zero and am_waitRequest = '0' then
					next_state 	<= WaitStateWrite;
				end if;
				
			when WaitStateWrite =>
				done_write <= '1';
				if start_write = '0' then
					next_state 	<= Idle;
				end if;
				
			when others => NULL;
			
			end case;
	end process;

	
	count_read_reg: process(clk, nReset)
	begin
	
		if nReset = '0' then
			count_read <= "111";

		elsif rising_edge(clk) then
			case (state) is
			when Idle =>
				count_read <= "111";
			when ReadReq =>
				if am_readdatavalid = '1' then
					count_read <= count_read - 1;
				end if;
			when Read =>
				if am_readdatavalid = '1' then
					count_read <= count_read - 1;
				end if;
			when others => NULL;
			end case;
		end if;
	end process;
	
	count_write_reg: process(clk, nReset)
	begin
	
		if nReset = '0' then
			count_write <= "010";

		elsif rising_edge(clk) then
			case (state) is
			when Idle =>
				count_write <= "010";
			when Write =>
				if am_waitRequest = '0' then
					count_write <= count_write - 1;
				end if;
			when others => NULL;
			end case;
		end if;
	end process;
	
	en_block <= am_readdatavalid;
	output <= am_readdata;
	index <= std_logic_vector(count_read);
	
	
end arch ;