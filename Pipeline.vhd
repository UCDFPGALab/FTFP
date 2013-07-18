library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pipeline is
	generic (SETUP : integer := 1; --time after the "start" pulse that the pipeline waits to start operating
				HOLD  : integer := 1; --time after the pipeline is done that it waits to send the "done" pulse
				ROWS : integer := 4; -- size in ints
				COLUMNS : integer := 4;
				INTSIZE : integer := 8 -- size of the int in bits, 4 for the 3 digit HEX example
				);
	port    (clk      : in std_logic;
		      reset    : in std_logic;
		      dataIn   : in unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0);
				dataInValid : in std_logic;
				dataOut  : out unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0);
				valid    : out std_logic);
end Pipeline;

architecture Behavioral of Pipeline is

	subtype tmp is unsigned(INTSIZE - 1 downto 0);
	type memory_array is array(integer range 0 to ROWS-1, integer range 0 to COLUMNS-1) of tmp;

begin

----loopback test
--	dataOut <= dataIn;
--	valid <= dataInValid;
--	
--	gen1: for row in 0 to ROWS - 1 generate
--		gen2: for column in 0 to COLUMNS - 1 generate
--			signal sum : unsigned (7 downto 0) := (others => '0');
--			begin
--				sum <= dataIn(7 downto 0);
----			row = 0;
----			row = ROWS - 1;
----			column = 0;
----			column = COLUMNS - 1;
--			
--				
--		end generate gen2;
--	end generate gen1;

	algorithm: process(clk, reset)
	variable right, left, up, down : boolean := false;
	
	variable result : unsigned(INTSIZE-1 downto 0) := (others => '0');
	
	variable memory : memory_array := (others=>(others=>(others=>'0')));
	
	variable started : boolean := false;
	
	variable memtemp : unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0) := (others => '0');
	
	begin				
		if reset = '1' then
			--reset conditions
			result := (others => '0');
			started := false;
			memory := (others=>(others=>(others=>'0')));
			valid <= '0';
			state := 0;
		elsif rising_edge(clk) then
			if started = false and dataInValid = '1' then --initial latching of data
				valid <= '0';
				result := (others => '0');
				started := true;
				state := 0;
				--need to shove the input massif into a nice "array"
				for i in 0 to ROWS - 1 loop
					for j in 0 to COLUMNS - 1 loop
						memory(i,j) := dataIn(INTSIZE*(COLUMNS*ROWS - j - i*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - j - i*COLUMNS) - 8);
					end loop;
				end loop;
			elsif started then
				valid <= '0';
		
				for row in 0 to ROWS - 1 loop
					for column in 0 to COLUMNS - 1 loop
				
						if row = 0 then
							up := false;
							down := true;
						elsif row = ROWS - 1 then
							down := false;
							up := true;
						else
							down := true;
							up := true;
						end if;
						
						if column = 0 then
							left := false;
							right := true;
						elsif column = COLUMNS - 1 then
							left := true;
							right := false;
						else
							left := true;
							right := true;
						end if;
				
			--do the algorithm: Sum up all the surrounding elements with the current element and add them in
						result := memory(row, column);
				
--						assert false report "Memory with row " & integer'image(row) & " and column " & integer'image(column) & " = " & integer'image(to_integer(memory(row,column)))
--							severity note;
				
						if up and left then
							result := result + memory(row - 1, column - 1);
--							assert false report "Up and left makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
						if up then
							result := result + memory(row - 1, column);
--							assert false report "Up makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
						if up and right then
							result := result + memory(row - 1, column + 1);
--							assert false report "Up and right makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
						if left then
							result := result + memory(row, column - 1);
--							assert false report "Left makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
						if right then 
							result := result + memory(row, column + 1);
--							assert false report "Right makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
						if down and left then
							result := result + memory(row + 1, column - 1);
--							assert false report "Down and left makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
						if down then
							result := result + memory(row + 1, column);
--							assert false report "Down makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
						if down and right then
							result := result + memory(row + 1, column + 1);
--							assert false report "Down and right makes result " & integer'image(to_integer(result)) severity note;
						end if;
				
				--load the result back in the memory array
					
						memtemp(INTSIZE*(COLUMNS*ROWS - row*COLUMNS - column) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) := result;
					
--						assert false report "Memory with row " & integer'image(row) & " and column " & integer'image(column) &
--							" written to memtemp " & integer'image(INTSIZE*(COLUMNS*ROWS - row - column*COLUMNS) - 1) & " down to " & 
--							integer'image(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) & " with value " & integer'image(to_integer(result))
--							severity note;
				
				--Now load the memory array back into the dataOut
					end loop;
				end loop;
			end if;
			
		end if;
	end process;


end Behavioral;

