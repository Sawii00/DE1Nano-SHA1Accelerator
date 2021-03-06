LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.common_utils_pkg.ALL;
ENTITY SHA1Accelerator_pipelined IS
    PORT (

        -- INPUTS 
        input : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        start_hash : IN STD_LOGIC;
		  index : in std_logic_vector(2 downto 0);
		  en_block : in std_logic;

        clk : IN STD_LOGIC;
        nReset : IN STD_LOGIC;

        -- OUTPUTS
        done_hash : OUT STD_LOGIC;
		  en_nonce : in std_logic;
		  nonce : in std_logic_vector(31 downto 0);
		  first_nonce : out std_logic_vector(31 downto 0);
        hash : OUT STD_LOGIC_VECTOR(159 DOWNTO 0)
		  
    );

END SHA1Accelerator_pipelined;

ARCHITECTURE arch_imp OF SHA1Accelerator_pipelined IS

    TYPE State IS (IDLE, setup_padding_block, wait_state, populate_words, compute_hash);
    SIGNAL a, b, c, d, e : STD_LOGIC_VECTOR(31 DOWNTO 0);
	 signal input_block : std_logic_vector(511 downto 0);

    SIGNAL curr_state : State;

    -- Make sure they are multiple of 4 
    CONSTANT num_op_cycle_word_population : INTEGER := 4;

BEGIN				

	 
	 block_process : process(clk, nReset)
	 begin
		if nReset = '0' then
			input_block <= (others => '0');
		elsif rising_edge(clk) then
			if en_block = '1' then
				case index is
					when "000" => input_block(63 downto 0) 	<= input;
					when "001" => input_block(127 downto 64)  <= input;
					when "010" => input_block(191 downto 128) <= input;
					when "011" => input_block(255 downto 192) <= input;
					when "100" => input_block(319 downto 256) <= input;
					when "101" => input_block(383 downto 320) <= input;
					when "110" => input_block(447 downto 384) <= input;
					when "111" => input_block(511 downto 448) <= input;
					when others => null;
				end case;
			end if;
			if en_nonce = '1' then
				input_block(31 downto 0) <= nonce;
			end if;
		end if;
	end process;
	
	first_nonce <= input_block(31 downto 0);
				

    fsm : PROCESS (clk, nReset)
        VARIABLE words : WORD_ARR;
        VARIABLE temp : unsigned(31 DOWNTO 0);
        VARIABLE f : unsigned(31 DOWNTO 0);
        VARIABLE k : unsigned(31 DOWNTO 0);
        VARIABLE w : unsigned(31 DOWNTO 0);
        VARIABLE count : INTEGER;
        VARIABLE a_var : unsigned(31 DOWNTO 0);
        VARIABLE b_var : unsigned(31 DOWNTO 0);
        VARIABLE c_var : unsigned(31 DOWNTO 0);
        VARIABLE d_var : unsigned(31 DOWNTO 0);
        VARIABLE e_var : unsigned(31 DOWNTO 0);
        VARIABLE curr_block : STD_LOGIC_VECTOR(511 DOWNTO 0);

        VARIABLE handled_block : STD_LOGIC;
    BEGIN
        IF nReset = '0' THEN
            a <= x"67452301";
            b <= x"EFCDAB89";
            c <= x"98BADCFE";
            d <= x"10325476";
            e <= x"C3D2E1F0";
            curr_state <= Idle;
            handled_block := '0';
        ELSIF rising_edge(clk) THEN
            CASE curr_state IS
                WHEN Idle =>
                    a <= x"67452301";
                    b <= x"EFCDAB89";
                    c <= x"98BADCFE";
                    d <= x"10325476";
                    e <= x"C3D2E1F0";
                    curr_block := input_block;
                    handled_block := '0';
                    count := 0;

                    IF start_hash = '1' THEN
                        curr_state <= populate_words;
                    END IF;
                WHEN populate_words =>
                    a_var := unsigned(a);
                    b_var := unsigned(b);
                    c_var := unsigned(c);
                    d_var := unsigned(d);
                    e_var := unsigned(e);
                    IF count < 16/num_op_cycle_word_population THEN
                        FOR i IN 0 TO num_op_cycle_word_population - 1 LOOP
                            temp := unsigned(curr_block(511 - 32 * (i + count * num_op_cycle_word_population) DOWNTO 511 - 32 * (i + count * num_op_cycle_word_population + 1) + 1));
                            words(i + count * num_op_cycle_word_population) := temp;
                        END LOOP;
                    ELSE
                        FOR i IN 0 TO num_op_cycle_word_population - 1 LOOP
                            temp := words(i + count * num_op_cycle_word_population - 3) XOR words(i + count * num_op_cycle_word_population - 8) XOR words(i + count * num_op_cycle_word_population - 14) XOR words(i + count * num_op_cycle_word_population - 16);
                            -- words(i) = left_rotate(temp, 1)
                            words(i + count * num_op_cycle_word_population)(31 DOWNTO 1) := temp(30 DOWNTO 0);
                            words(i + count * num_op_cycle_word_population)(0) := temp(31);
                        END LOOP;
                    END IF;
                    count := count + 1;
                    IF count >= 80 / num_op_cycle_word_population THEN
                        curr_state <= compute_hash;
                        count := 0;
                    END IF;
                WHEN compute_hash =>
                    k := x"00000000";
                    IF count < 20 THEN
                            w := words(count);
                            k := x"5a827999";
                            f := (b_var AND c_var) OR ((NOT b_var) AND d_var);
                    ELSIF count < 40 THEN
                            w := words(count);
                            k := x"6ed9eba1";
                            f := b_var XOR c_var XOR d_var;
                    ELSIF count < 60 THEN
                            w := words(count);
                            k := x"8f1bbcdc";
                            f := (b_var AND c_var) OR (b_var AND d_var) OR (c_var AND d_var);
                    ELSE
                            w := words(count);
                            k := x"ca62c1d6";
                            f := b_var XOR c_var XOR d_var;  
                    END IF;
						  
						  -- temp = left_rotate(a, 5)
                    temp(31 DOWNTO 5) := a_var(26 DOWNTO 0);
                    temp(4 DOWNTO 0) := a_var(31 DOWNTO 27);
                    temp := (temp + f) + (e_var + w) + k;
                    e_var := d_var;
                    d_var := c_var;
                    -- c = left_rotate(b, 30);
                    c_var(31 DOWNTO 30) := b_var(1 DOWNTO 0);
                    c_var(29 DOWNTO 0) := b_var(31 DOWNTO 2);
                    b_var := a_var;
                    a_var := temp;

                    count := count + 1;

                    IF count >= 80 THEN
                        count := 0;
                        a <= STD_LOGIC_VECTOR(unsigned(a) + a_var);
                        b <= STD_LOGIC_VECTOR(unsigned(b) + b_var);
                        c <= STD_LOGIC_VECTOR(unsigned(c) + c_var);
                        d <= STD_LOGIC_VECTOR(unsigned(d) + d_var);
                        e <= STD_LOGIC_VECTOR(unsigned(e) + e_var);
                        IF handled_block = '0' THEN
                            curr_state <= setup_padding_block;
                        ELSE
                            curr_state <= wait_state;
                        END IF;
                    END IF;
                WHEN setup_padding_block =>
                    curr_block(511 DOWNTO 504) := x"80";
                    curr_block(503 DOWNTO 64) := (OTHERS => '0');
                    -- 512 in big endian within 8 bytes
                    curr_block(63 DOWNTO 0) := x"00_00_00_00_00_00_02_00";
                    handled_block := '1';
                    curr_state <= populate_words;
                    count := 0;
                WHEN wait_state =>
                    hash <= a & b & c & d & e;
                    done_hash <= '1';
                    IF start_hash = '0' THEN
                        curr_state <= Idle;
                        done_hash <= '0';
                    END IF;
                WHEN OTHERS => NULL;
            END CASE;
        END IF;
    END PROCESS fsm;
END arch_imp;