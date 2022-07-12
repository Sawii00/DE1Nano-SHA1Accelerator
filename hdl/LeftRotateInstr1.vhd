LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity LeftRotateInstr1 is
	PORT (
        dataA : in std_logic_vector(31 downto 0);
        result: out std_logic_vector(31 downto 0)
	);
end LeftRotateInstr1;

ARCHITECTURE custom_instr OF LeftRotateInstr1 IS
begin

		result(31 downto 1) <= dataA(30 downto 0);
		result(0) <= dataA(31);
	
end custom_instr;