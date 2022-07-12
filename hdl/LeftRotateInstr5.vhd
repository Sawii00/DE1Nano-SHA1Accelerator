LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity LeftRotateInstr5 is
	PORT (
        dataA : in std_logic_vector(31 downto 0);
        result: out std_logic_vector(31 downto 0)
	);
end LeftRotateInstr5;

ARCHITECTURE custom_instr OF LeftRotateInstr5 IS
begin

		result(31 downto 5) <= dataA(26 downto 0);
		result(4 downto 0) <= dataA(31 downto 27);
	
end custom_instr;