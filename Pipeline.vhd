library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pipeline is
	generic (SETUP : integer := 1; --time after the "start" pulse that the pipeline waits to start operating
				HOLD  : integer := 1; --time after the pipeline is done that it waits to send the "done" pulse
				ROWS : integer := 4; -- size in ints
				COLUMNS : integer := 4;
				INTSIZE : integer := 4 -- size of the int in bits, 4 for the 3 digit HEX example
				);
	port    (clk      : in std_logic;
		      reset    : in std_logic;
		      dataIn   : in unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0);
				dataInValid : in std_logic;
				dataOut  : out unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0);
				valid    : out std_logic);
end Pipeline;

architecture Behavioral of Pipeline is

begin

	algorithm: process(clk, reset)
	variable i : integer range 0 to DATASIZE := 0;
	variable row: integer range 0 to ROWS-1 := 0;
	variable column : integer range 0 to COLUMNS-1 := 0;
	variable right, left, up, down : boolean := false;
	
	variable result : unsigned(INTSIZE-1 downto 0) := (others => '0');
	
	variable data : unsigned(INTSIZE*ROWS*COLUMNS - 1 downto 0) := (others => '0');
	
	variable started : boolean := false;
	
	begin
		row := i/3;
		column := i mod 3;
		valid <= '0';
		
		case row is
			when 0 => 
				up := true;
				down := false;
			when ROWS - 1 => 
				down := true;
				up := false;
			when others =>
				down := true;
				up := true;
			end case;
			
		case column is
			when 0 =>
				left := true;
				right := false;
			when COLUMNS - 1 =>
				left := false;
				right := true;
			when others =>
				left := true;
				right := true;
		end case;
				
		if reset = '1' then
			--reset conditions
			i := 0;
			data := (others => '0');
			result := 0;
			started := false;
		elsif rising_edge(clk) then
			if started = false and dataInValid = '1' then --initial latching of data
				data := dataIn;
				starter := true;
			elsif started then
		
			--do the algorithm: Sum up all the surrounding elements with the current element and add them in
			--Shows what to add here to get the the specified element, all multiplied by INTSIZE
			--(COLUMNS+1) (COLUMNS) (COLUMNS - 1)
			--(1)			  (0)       (-1)
			--(-COLUMNS+1)(-COLUMNS)(-COLUMNS - 1)
			--Don't forget to multiply by INTSIZE to get the bits to shiftover, and don't forget to check bounds so that nonexistent elements are NOT checked.
				result := data(INTSIZE(i+1) - 1 downto INTSIZE*(i));
				if up and left then
					results := results + data(INTSIZE*(i + COLUMNS + 2) downto INTSIZE*(i + COLUMNS + 1));
				end if;
				
				if up then
					results := results + data(INTSIZE*(i + COLUMNS + 1) - 1 downto INTSIZE*(i + COLUMNS));
				end if;
				
				if up and right then
					results := results + data(INTSIZE*(i + COLUMNS) - 1 downto INTSIZE*(i + COLUMNS - 1));
				end if;
				
				if left then
					results := results + data(INTSIZE*(i + 2) - 1 downto INTSIZE*(i + 1));
				end if;
				
				if right then 
					results := results + data(INTSIZE*(i) - 1 downto INTSIZE*(i-1));
				end if;
				
				if down and left then
					results := results + data(INTSIZE*(i - COLUMNS + 2) - 1 downto INTSIZE*(i - COLUMNS + 1));
				end if;
				
				if down then
					results := results + data(INTSIZE(i - COLUMNS + 1) - 1 downto INTSIZE*(i - COLUMNS));
				end if;
				
				if down and right then
					results := results + data(INTSIZE*(i - COLUMNS) - 1 downto INTSIZE*(i - COLUMNS - 1));
				end if;
				
				data(INTSIZE(i+1) - 1 downto INTSIZE*(i)) := results;
				
				i := i + 1;
				
				if i = COLUMNS * ROWS - 1 then
					valid <= '1';
					dataOut <= data;
					starter := false;
					i := 0;
				end if;
			end if;
			
		end if;
	end process;


end Behavioral;

