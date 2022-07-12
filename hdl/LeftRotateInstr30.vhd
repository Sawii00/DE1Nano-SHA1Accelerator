LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity LeftRotateInstr30 is
	PORT (
        dataA : in std_logic_vector(31 downto 0);
        result: out std_logic_vector(31 downto 0)
	);
end LeftRotateInstr30;

ARCHITECTURE custom_instr OF LeftRotateInstr30 IS
begin

		result(31 downto 30) <= dataA(1 downto 0);
		result(29 downto 0) <= dataA(31 downto 2);
	
end custom_instr;