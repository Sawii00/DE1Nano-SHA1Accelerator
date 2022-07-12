library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slave is

	port (
		clk    : in std_logic;
		nreset : in std_logic;
		
		set_done : in std_logic_vector(1 downto 0);
		
		-- internal interface (i.e. avalon slave).
		as_address   : in std_logic_vector(2 downto 0);
		as_write     : in std_logic;
		as_read      : in std_logic;
		as_writedata : in std_logic_vector(31 downto 0);
		as_readdata  : out std_logic_vector(31 downto 0);
		
		read_add_reg_out : out std_logic_vector(31 downto 0);
		write_add_reg_out : out std_logic_vector(31 downto 0);
		num_block_out : out std_logic_vector(31 downto 0);
		start_reg_out : out std_logic_vector(31 downto 0);
		complexity_reg_out : out std_logic_vector(31 downto 0);
		nonce_increment_reg_out : out std_logic_vector(31 downto 0)

	);
end slave;

architecture register_file_arch of slave is
	-- register content stored as array of 16-bit words
	signal read_add_reg 			: std_logic_vector(31 downto 0);
   signal write_add_reg 		: std_logic_vector(31 downto 0);
	signal num_block 				: std_logic_vector(31 downto 0);
	signal start_reg 				: std_logic_vector(31 downto 0);
	signal complexity_reg 		: std_logic_vector(31 downto 0);
	signal done_reg 				: std_logic_vector(31 downto 0);
	signal nonce_increment_reg : std_logic_vector(31 downto 0);

begin

	read_add_reg_out <= read_add_reg;
	write_add_reg_out <= write_add_reg;
	num_block_out <= num_block;
	start_reg_out <= start_reg;
	complexity_reg_out <= complexity_reg;
	nonce_increment_reg_out <= nonce_increment_reg;

	-- avalon slave write to registers.
	process (clk, nreset)
	begin
		if nreset = '0' then
			read_add_reg <= (others => '0');
			write_add_reg <= (others => '0');
			num_block <= (others => '0');
			start_reg <= (others => '0');
			complexity_reg <= (others => '0');
		elsif rising_edge(clk) then
			if set_done = "01" then
				done_reg <= x"00000001";
			elsif set_done = "11" then
				done_reg <= x"00000002";
			else
				done_reg <= (others => '0');
			end if;
			if as_write = '1' then
				case as_address is
					when "000" => read_add_reg <= as_writedata;
					when "001" => write_add_reg <= as_writedata;
					when "010" => num_block <= as_writedata;
					when "011" => start_reg <= as_writedata;
					when "100" => complexity_reg <= as_writedata;
					when "101" => nonce_increment_reg <= as_writedata;
					when others => null;
				end case;
			end if;
		end if;
	end process;

	-- avalon slave read from registers.
	process (clk)
		begin
			if rising_edge(clk) then
				as_readdata <= (others => '0');
				if as_read = '1' then
					case as_address is
						when "000" => as_readdata <= read_add_reg;
						when "001" => as_readdata <= write_add_reg;
						when "010" => as_readdata <= num_block;
						when "011" => as_readdata <= start_reg;
						when "100" => as_readdata <= complexity_reg;
						when "101" => as_readdata <= nonce_increment_reg;
						when "110" => as_readdata <= done_reg;
						when others => null;
					end case;
				end if;
			end if;
		end process;
end;