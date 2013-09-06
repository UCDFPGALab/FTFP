LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY PipelineTest IS
END PipelineTest;
 
ARCHITECTURE behavior OF PipelineTest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Pipeline
	 	generic (SETUP : integer := 1; --time after the "start" pulse that the pipeline waits to start operating
				HOLD  : integer := 1; --time after the pipeline is done that it waits to send the "done" pulse
				ROWS : integer := 4; -- size in ints
				COLUMNS : integer := 4;
				INTSIZE : integer := 8 -- size of the int in bits, 4 for the 3 digit HEX example
				);
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         dataIn : IN  unsigned(127 downto 0);
         dataInValid : IN  std_logic;
         dataOut : OUT  unsigned(127 downto 0);
         valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal dataIn : unsigned(127 downto 0) := (others => '0');
   signal dataInValid : std_logic := '0';

 	--Outputs
   signal dataOut : unsigned(127 downto 0);
   signal valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Pipeline 
		generic map(SETUP => 1, --time after the "start" pulse that the pipeline waits to start operating
				HOLD  => 1, --time after the pipeline is done that it waits to send the "done" pulse
				ROWS => 4, -- size in ints
				COLUMNS => 4,
				INTSIZE => 8 -- size of the int in bits, 4 for the 3 digit HEX example
				)
	PORT MAP (
          clk => clk,
          reset => reset,
          dataIn => dataIn,
          dataInValid => dataInValid,
          dataOut => dataOut,
          valid => valid
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		
		dataIn <= "00000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100";
		dataInValid <= '1';
		
		wait for clk_period;
		
		dataInValid <= '0';

      -- insert stimulus here 

      wait;
   end process;

END;
