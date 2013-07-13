library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hexMux is
	port( char  : in unsigned(7 downto 0);
			err : out std_logic;
			number : out unsigned(3 downto 0));
end hexMux;

architecture Behavioral of hexMux is

begin

with char select
number <= to_unsigned(0, 4) when to_unsigned(48, 8),
			 to_unsigned(1, 4) when to_unsigned(49, 8),
			 to_unsigned(2, 4) when to_unsigned(50, 8),
			 to_unsigned(3, 4) when to_unsigned(51, 8),
			 to_unsigned(4, 4) when to_unsigned(52, 8),
			 to_unsigned(5, 4) when to_unsigned(53, 8),
			 to_unsigned(6, 4) when to_unsigned(54, 8),
			 to_unsigned(7, 4) when to_unsigned(55, 8),
			 to_unsigned(8, 4) when to_unsigned(56, 8),
			 to_unsigned(9, 4) when to_unsigned(57, 8),
			 to_unsigned(10, 4) when to_unsigned(65, 8),
			 to_unsigned(11, 4) when to_unsigned(66, 8),
			 to_unsigned(12, 4) when to_unsigned(67, 8),
			 to_unsigned(13, 4) when to_unsigned(68, 8),
			 to_unsigned(14, 4) when to_unsigned(69, 8),
			 to_unsigned(15, 4) when to_unsigned(70, 8),
			 "0000" when others;
			 
with char select
err <= '0' when to_unsigned(48, 8),
		 '0' when to_unsigned(49, 8),
		 '0' when to_unsigned(50, 8),
		 '0' when to_unsigned(51, 8),
		 '0' when to_unsigned(52, 8),
		 '0' when to_unsigned(53, 8),
		 '0' when to_unsigned(54, 8),
		 '0' when to_unsigned(55, 8),
		 '0' when to_unsigned(56, 8),
		 '0' when to_unsigned(57, 8),
		 '0' when to_unsigned(65, 8),
		 '0' when to_unsigned(66, 8),
		 '0' when to_unsigned(67, 8),
		 '0' when to_unsigned(68, 8),
		 '0' when to_unsigned(69, 8),
		 '0' when to_unsigned(70, 8),
		 '1' when others;
		 

end Behavioral;