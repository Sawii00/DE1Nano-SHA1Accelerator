library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Controller is
    port(
	 
    clk 					 : in std_logic;
    nReset 				 : in std_logic;
	 
	 --Slave
	 read_add_reg 		 : in std_logic_vector(31 downto 0);
	 write_add_reg 	 : in std_logic_vector(31 downto 0);
	 num_block 			 : in std_logic_vector(31 downto 0);
	 start_reg 			 : in std_logic_vector(31 downto 0);
	 complexity_reg 	 : in std_logic_vector(31 downto 0);
	 nonce_incr_reg 	 : in std_logic_vector(31 downto 0);
	 set_done			 : out std_logic_vector(1 downto 0);

	 --DMA
	 start_read			 : out std_logic;
	 done_read			 : in std_logic;
	 read_address		 : out std_logic_vector(31 downto 0);
	 start_write		 : out std_logic;
	 done_write			 : in std_logic;
	 write_address		 : out std_logic_vector(31 downto 0);
	 
	 --DMA and Hasher
	 nonce				 : out std_logic_vector(31 downto 0);
	 
	 --Hasher
	 start_hash			 : out std_logic;
	 done_hash			 : in std_logic;
	 en_nonce			 : out std_logic;
	 hash					 : in std_logic_vector(159 downto 0);
	 first_nonce		 : in std_logic_vector(31 downto 0);
	 	 
	 done 				 : out std_logic

);
end Controller;

architecture arch of Controller is

   type MasterState is (Idle, Read, Write, HashState, Check, NonceState, WaitState);
	signal state       : MasterState;
	signal count_nonce				 : unsigned(31 downto 0);
	constant zero			 : unsigned(159 downto 0) := (others => '0');
	constant one			 : unsigned(31 downto 0) := (others => '1');


begin	


	FSM: process(clk, nReset)
	variable complexity : integer;
	variable count_block : unsigned(7 downto 0);
	variable visited : std_logic;
	variable count_iter : unsigned(31 downto 0);
	begin
		if nReset = '0' then
			state <= Idle;
		elsif rising_edge(clk) then
		
			en_nonce 		<= '0';
			start_hash 	   <= '0';
			start_write 	<= '0';
			start_read 		<= '0';
			set_done 		<= "00";
			done 				<= '0';
			
			case (state) is
			
				when Idle =>
					count_block := (others => '0');
					nonce <= (others => '0');
					if start_reg(0) = '1' then
						state <= Read;
						complexity := to_integer(unsigned(complexity_reg));
					end if;
					
				when Read =>
					count_iter := (others => '0');
					count_nonce <= (others => '0');
					visited := '0';
					start_read <= '1';
					read_address <= std_logic_vector(unsigned(read_add_reg) + count_block * 64);
					if done_read = '1' then
						start_read <= '0';
						state <= HashState;
					end if;
					
				when HashState =>
					start_hash <= '1';
					count_iter := count_iter + 1;
					if done_hash = '1' then
						start_hash <= '0';
						state <= Check;
					end if;
					
				when Check =>
					if visited = '0' then
						nonce <= first_nonce;
					end if;
					if shift_right(unsigned(hash), 160 - complexity) = zero then
						state <= Write;
					else
						if count_iter = one then
							state <= WaitState;
						else
							state <= NonceState;
						end if;
					end if;
					
				when Write =>
					start_write <= '1';
					write_address <= std_logic_vector(unsigned(write_add_reg) + (count_block * 24));
					if done_write = '1' then
						start_write <= '0';
						count_block := count_block + 1;
						if count_block = unsigned(num_block) then
							state <= WaitState;
						else
							state <= Read;
						end if;
					end if;
					
				when NonceState =>
					visited := '1';
					en_nonce	<= '1';
					nonce <= std_logic_vector(count_nonce);
					count_nonce <= count_nonce + unsigned(nonce_incr_reg);
					state <= HashState;
					
				when WaitState =>
					done <= '1';
					if count_iter = one then
						set_done <= "11";
					else
						set_done <= "01";
					end if;
					if start_reg(0) = '0' then
						state <= Idle;
						done <= '0';
						set_done <= "00";
					end if;
				when others => NULL;
			end case;
	end if;
	end process;
			
	
	
end arch ;