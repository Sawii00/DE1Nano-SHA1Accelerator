LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity BigEndianInstr is
	PORT (
        dataA : in std_logic_vector(31 downto 0);
        result: out std_logic_vector(31 downto 0)
	);
end BigEndianInstr; 

ARCHITECTURE custom_instr OF BigEndianInstr IS
begin

    result(31 downto 24) <= dataA(7 downto 0);
    result(23 downto 16) <= dataA(15 downto 8);
    result(15 downto 8) <= dataA(23 downto 16);
    result(7 downto 0) <= dataA(31 downto 24);

end custom_instr;