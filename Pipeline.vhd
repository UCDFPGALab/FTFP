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

	function concat( arr : memory_array;
						  output : integer ) return unsigned is
		variable con : unsigned (output - 1 downto 0) := (others => '0') ;
	begin
	end concat;

begin

	algorithm: process(clk, reset)
	variable row: integer range 0 to ROWS-1 := 0;
	variable column : integer range 0 to COLUMNS-1 := 0;
	variable right, left, up, down : boolean := false;
	
	variable result : unsigned(INTSIZE-1 downto 0) := (others => '0');
	
	variable memory : memory_array := (others=>(others=>(others=>'0')));
	
	variable started : boolean := false;
	
	begin
		valid <= '0';
		
		case row is
			when 0 => 
				up := false;
				down := true;
			when ROWS - 1 => 
				down := false;
				up := true;
			when others =>
				down := true;
				up := true;
			end case;
			
		case column is
			when 0 =>
				left := false;
				right := true;
			when COLUMNS - 1 =>
				left := true;
				right := false;
			when others =>
				left := true;
				right := true;
		end case;
				
		if reset = '1' then
			--reset conditions
			result := (others => '0');
			started := false;
			memory := (others=>(others=>(others=>'0')));
			row := 0;
			column := 0;
		elsif rising_edge(clk) then
			if started = false and dataInValid = '1' then --initial latching of data
				result := (others => '0');
				started := true;
				row := 0;
				column := 0;
				--need to shove the input massif into a nice "array"
				for i in 0 to ROWS - 1 loop
					for j in 0 to COLUMNS - 1 loop
						memory(i,j) := dataIn(INTSIZE*(COLUMNS*ROWS - j - i*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - j - i*COLUMNS) - 8);
					end loop;
				end loop;
			elsif started then
		
			--do the algorithm: Sum up all the surrounding elements with the current element and add them in
				result := memory(row, column);
				
				if up and left then
					result := result + memory(row - 1, column - 1);
				end if;
				
				if up then
					result := result + memory(row - 1, column);
				end if;
				
				if up and right then
					result := result + memory(row - 1, column + 1);
				end if;
				
				if left then
					result := result + memory(row, column - 1);
				end if;
				
				if right then 
					result := result + memory(row, column + 1);
				end if;
				
				if down and left then
					result := result + memory(row + 1, column - 1);
				end if;
				
				if down then
					result := result + memory(row + 1, column);
				end if;
				
				if down and right then
					result := result + memory(row + 1, column + 1);
				end if;
				
				--load the result back in the data array
				
				memory(row, column) := result;
				
				if row = ROWS - 1 and column = COLUMNS - 1 then
					for i in 0 to ROWS - 1 loop
						for j in 0 to COLUMNS - 1 loop
							dataOut <= memory(i,j);
						end loop;
					end loop;
					started := false;
					valid <= '1';
				end if;
				
				row := row + 1;
				column := column + 1;
				
			end if;
			
		end if;
	end process;


end Behavioral;

