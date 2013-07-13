library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timeout is
	generic(lengthOfHi : integer := 1);
	port( clk    : in std_logic;
			reset  : in std_logic;
			enable : in std_logic;
			tt     : out std_logic);
end timeout;

architecture Behavioral of timeout is

begin


end Behavioral;

