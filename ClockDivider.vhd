--Takes in a clock signal and variables for how to modify that clock
--signal, and generates slower ticks of variable width


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ClockDivider is
	generic(divider    : integer := 2;
			  lengthOfHi : integer := 1); --in clock cycles, has to be less than divider, more than 1
	port( clk    : in std_logic;
			reset  : in std_logic;
			enable : in std_logic;
			tick   : out std_logic);
end ClockDivider;

architecture Behavioral of ClockDivider is

	--------------------------------------
	-- 				Signals					--
	--------------------------------------
	signal counter : integer range 0 to divider - 1 := 0;
	
begin

	assert lengthOfHi < divider and lengthOfHi > 0
		report "Length of clock signal must be greater than 1 and less than the total clock divider"
		severity ERROR;

	-------------------------------------- 
	-- 				Code						--
	--------------------------------------
	
	main: process(clk, reset, enable)
	begin
		if reset = '1' then
			counter <= 0;
			tick <= '0';
		elsif rising_edge(clk) and enable = '1' then
			tick <= '0';
			counter <= counter + 1;
			if counter = divider - 1 then
				counter <= 0;
				tick <= '1';
			elsif counter >= divider - lengthOfHi then
				tick <= '1';
			end if;
		end if;
	end process;
end Behavioral;

