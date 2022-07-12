LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use work.common_utils_pkg.all;

ENTITY tb_sha IS
END tb_sha;

ARCHITECTURE arch_imp OF tb_sha IS
    signal clk: std_logic;
    signal nReset : std_logic;
    signal input : std_logic_vector(63 downto 0);
    signal hash : std_logic_vector(159 downto 0);
	 signal index : std_logic_vector(2 downto 0);
	 signal en_block : std_logic;
    signal start_hash : std_logic;
    signal done_hash : std_logic;
	 signal st : std_logic_vector(2 downto 0);
	 signal bloc : std_logic_vector(511 downto 0);
	 
    constant CLK_PERIOD : time:= 20 ns;

BEGIN

    hasher: entity work.SHA1Accelerator_pipelined
        port map(
				input => input,
            clk => clk,
            nReset => nReset,
            hash => hash,
            start_hash => start_hash,
            done_hash => done_hash,
				en_block => en_block,
				index => index
        );

    ckl_generation: process
    begin
        CLK <= '1';
        wait for CLK_PERIOD / 2;
        CLK <= '0';
        wait for CLK_PERIOD / 2;
    end process;

   tb: process
   begin
        wait for 5 * CLK_PERIOD/4;
        nReset <= '0';
        wait for 5 * CLK_PERIOD;
        nReset <= '1';
		  wait for 5 * CLK_PERIOD;


		  en_block <= '1';
		  index <= "111";
        input <= x"01010101_01010101";
        wait for CLK_PERIOD;
		  index <= "110";
        wait for CLK_PERIOD;
		  index <= "101";
        wait for CLK_PERIOD;
		  index <= "100";
        wait for CLK_PERIOD;
		  index <= "011";
        wait for CLK_PERIOD;
		  index <= "010";
        wait for CLK_PERIOD;
		  index <= "001";
        wait for CLK_PERIOD;
		  index <= "000";
        wait for CLK_PERIOD;
		  en_block <= '0';

		  start_hash <= '1';
        wait until done_hash = '1';
		  wait for CLK_PERIOD/4;
        start_hash <= '0';
	wait;

   end process tb;



END arch_imp;