LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY MainTest IS
END MainTest;
 
ARCHITECTURE behavior OF MainTest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Main
    PORT(
         SYSCLK_P : IN  std_logic;
         SYSCLK_N : IN  std_logic;
         USB_UART_RX : IN  std_logic;
         USB_UART_TX : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal SYSCLK_P : std_logic := '0';
   signal SYSCLK_N : std_logic := '0';
   signal USB_UART_RX : std_logic := '0';
   signal GPIO_BUTTON0 : std_logic := '0';

 	--Outputs
   signal USB_UART_TX : std_logic;
   -- No clocks detected in port list. Replace clk below with 
   -- appropriate port name 
	
	signal transmit : unsigned (135 downto 0) := "0101010101000010010000110100000101000010010000110100000101000010010000110100000101000010010000110100000101000010010000110100000100100100";
	signal sent : std_logic := '0';
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Main PORT MAP (
          SYSCLK_P => SYSCLK_P,
          SYSCLK_N => SYSCLK_N,
          USB_UART_RX => USB_UART_RX,
          USB_UART_TX => USB_UART_TX
        );

   -- Clock process definitions
   clk_process :process
   begin
		SYSCLK_P <= '0';
		SYSCLK_N <= '1';
		wait for clk_period/2;
		SYSCLK_P <= '1';
		SYSCLK_N <= '0';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		USB_UART_RX <= '1';
		
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 
		
		for i in 0 to 16 loop
			sent <= '0';
			wait for clk_period*868*2;
			USB_UART_RX <= '0'; -- start bit
			for f in 0 to 7 loop
				wait for clk_period*868*2;
				USB_UART_RX <= transmit(135-(8*i)-f);
			end loop;
			sent <= '1';
			wait for clk_period*868*2;
			USB_UART_RX <= '1'; -- stop bit
		end loop;
		

      wait;
   end process;

END;
