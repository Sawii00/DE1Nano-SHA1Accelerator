LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY TopLevel IS
    PORT (

        clk : IN STD_LOGIC;
        nReset : IN STD_LOGIC;

        -- Avalon master
        am_address 		 : out std_logic_vector(31 downto 0);
		  am_writeData 	 : out std_logic_vector(63 downto 0);
		  am_write 			 : out std_logic;
		  am_waitRequest 	 : in std_logic;
		  am_burstCount 	 : out std_logic_vector(3 downto 0);
		  am_read          : out std_logic;
		  am_readdata      : in std_logic_vector(63 DOWNTO 0);
		  am_readdatavalid : in std_logic;
		  
		  -- Avalon slave
		  as_address   : in std_logic_vector(2 downto 0);
		  as_write     : in std_logic;
		  as_read      : in std_logic;
		  as_writedata : in std_logic_vector(31 downto 0);
		  as_readdata  : out std_logic_vector(31 downto 0);
		  
		  done			: out std_logic
		 
    );

END TopLevel;

ARCHITECTURE arch_imp OF TopLevel IS	 
	 signal index 				:  std_logic_vector(2 downto 0);
	 signal en_block 			:  std_logic;
        
	 -- OUTPUTS
    signal hash 				:  STD_LOGIC_VECTOR(159 DOWNTO 0);
	 signal output				: std_logic_vector(63 downto 0);
	 
	 
	 signal read_add_reg 	: std_logic_vector(31 downto 0);
    signal write_add_reg 	: std_logic_vector(31 downto 0);
	 signal num_block 		: std_logic_vector(31 downto 0);
	 signal start_reg 		: std_logic_vector(31 downto 0);
	 signal complexity_reg 	: std_logic_vector(31 downto 0);
	 signal nonce_incr_reg 	: std_logic_vector(31 downto 0);
	 signal en_nonce 			: std_logic;
	 signal nonce 				: std_logic_vector(31 downto 0);
	 signal first_nonce 		: std_logic_vector(31 downto 0);
	 signal read_address    : std_logic_vector(31 downto 0);
	 signal write_address	: std_logic_vector(31 downto 0);  
	 signal set_done 			: std_logic_vector(1 downto 0);
	 signal done_hash   		: std_logic;
	 signal start_read		: std_logic;
	 signal done_write		: std_logic;
	 signal done_read       : std_logic;
	 signal start_hash		: std_logic;
	 signal start_write 		: std_logic;
	 
	 
	 component SHA1Accelerator_pipelined
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

	end component;
	
	component DMA
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
	end component;
	
	component slave is

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
	end component;
	
	component Controller is
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
	end component;
		  

BEGIN


	SHA: SHA1Accelerator_pipelined
	port map(
	clk => clk,
	nReset => nReset,
	input => output,
	start_hash => start_hash,
	index => index,
	en_block => en_block,
	done_hash => done_hash,
	en_nonce => en_nonce,
	first_nonce => first_nonce,
	nonce => nonce,
	hash => hash
	);
	
	
	DMA_inst: DMA
	port map(
	clk => clk,
	nReset => nReset,
	read_address => read_address,
	start_read => start_read,
	done_read => done_read,
	index => index,
	en_block => en_block,
	output => output,
	write_address => write_address,
	start_write => start_write,		 
	done_write => done_write,
	hash => hash,
	nonce => nonce,
	am_address => am_address,
	am_writeData => am_writeData,
	am_write => am_write,
	am_read => am_read,
	am_readdata => am_readdata,
   am_readdatavalid => am_readdatavalid,
	am_waitRequest => am_waitRequest,
	am_burstCount => am_burstCount 
	);
	
	
	Slave_inst: Slave
	port map(
	clk => clk, 
	nreset => nReset,
	as_address => as_address,
	as_write => as_write, 
	as_read => as_read,
	set_done	=> set_done,
	as_writedata => as_writedata,
	as_readdata => as_readdata,
	read_add_reg_out => read_add_reg,
	write_add_reg_out => write_add_reg,
	nonce_increment_reg_out => nonce_incr_reg,
	num_block_out => num_block, 
	start_reg_out => start_reg,
	complexity_reg_out => complexity_reg
	);
	
	Controller_inst: Controller
	port map(
	 clk => clk,					 
    nReset => nReset,				 
	 read_add_reg => read_add_reg, 		 
	 write_add_reg => write_add_reg, 	 
	 num_block => num_block, 			 
	 start_reg => start_reg,			 
	 complexity_reg => complexity_reg,
	 nonce_incr_reg => nonce_incr_reg,
	 set_done => set_done,			 
	 start_read => start_read,			 
	 done_read => done_read,			 
	 read_address => read_address,		 
	 start_write => start_write,		 
	 done_write => done_write,			 
	 write_address	=> write_address,	 
	 nonce => nonce,				 
	 start_hash => start_hash,			 
	 done_hash => done_hash,			 
	 en_nonce => en_nonce,
	 first_nonce => first_nonce,
	 hash	=> hash,				 
	 done => done 				 
	);
		
END arch_imp;