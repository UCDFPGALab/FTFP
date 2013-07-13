LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY dataAssemblerTest IS
END dataAssemblerTest;
 
ARCHITECTURE behavior OF dataAssemblerTest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dataAssembler
	 	generic (INPUTBITS   : integer := 8;
				OUTPUTBITS  : integer := 128;  --4x4 1 byte grid
				INPUTDELAY  : integer := 15;
				OUTPUTDELAY : integer := 2);
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         dataIn : IN  unsigned(7 downto 0);
         dataValid : IN  std_logic;
         dataOut : OUT  unsigned(127 downto 0);
         done : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal dataIn : unsigned(7 downto 0) := (others => '0');
   signal dataValid : std_logic := '0';

 	--Outputs
   signal dataOut : unsigned(127 downto 0);
   signal done : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dataAssembler 
	GENERIC MAP(
	
				INPUTBITS   => 8,
				OUTPUTBITS  => 128,  --4x4 1 byte grid
				INPUTDELAY  => 15,
				OUTPUTDELAY => 2
				)
	PORT MAP (
          clk => clk,
          reset => reset,
          dataIn => dataIn,
          dataValid => dataValid,
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
		dataIn <= "10101010";
		
		
		for I in 0 to 300 loop
			dataValid <= '1';
			wait for clk_period;
			dataValid <= '0';
			wait for clk_period;
		end loop;

      wait;
   end process;

END;
