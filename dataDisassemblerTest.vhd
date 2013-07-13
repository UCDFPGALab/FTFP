LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY dataDisassemblerTest IS
END dataDisassemblerTest;
 
ARCHITECTURE behavior OF dataDisassemblerTest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dataDisassembler
	 	generic (INPUTBITS   : integer := 16;
				OUTPUTBITS  : integer := 8;  --4x4 1 byte grid
				INPUTDELAY  : integer := 15;
				OUTPUTDELAY : integer := 2);
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         dataIn : IN  unsigned(15 downto 0);
         dataValid : IN  std_logic;
         dataRead : IN  std_logic;
         ready : OUT  std_logic;
         dataOut : OUT  unsigned(7 downto 0);
         done : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal dataIn : unsigned(15 downto 0) := (others => '0');
   signal dataValid : std_logic := '0';
   signal dataRead : std_logic := '0';

 	--Outputs
   signal ready : std_logic;
   signal dataOut : unsigned(7 downto 0);
   signal done : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dataDisassembler 
	Generic map(
	
		 	INPUTBITS   => 16,
				OUTPUTBITS  => 8,  --4x4 1 byte grid
				INPUTDELAY  => 15,
				OUTPUTDELAY => 2)
	PORT MAP (
          clk => clk,
          reset => reset,
          dataIn => dataIn,
          dataValid => dataValid,
          dataRead => dataRead,
          ready => ready,
          dataOut => dataOut,
          done => done
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

      -- insert stimulus here 
		
		reset <= '0';
		
      dataIn <= "1100101011110011";
      dataValid <= '1';

		wait for clk_period;
		
		dataValid <= '0';
		dataRead <= '1';
		
		wait for clk_period;
		
		dataRead <= '0';
		
		wait for clk_period;
		
		dataRead <= '1';

      wait;
   end process;

END;
