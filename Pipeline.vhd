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

signal currentValid : std_logic := '0';

begin

----loopback test
	dataOut <= dataIn;

	valid <= dataInValid;
--
--	process(clk, reset)
--	variable state : integer range 0 to 3 := 0;
--	begin
--		if reset = '1' then
--			currentValid <= '0';
--			state := 0;
--		elsif falling_edge(clk) then
--			currentValid <= '0';
--			if state = 0 and dataInValid = '1' then
--				state := 1;
--			elsif state /= 3 then
--				state := state + 1;
--			elsif state = 3 then
--				state := 0;
--				currentValid <= '1';
--			end if;
--		end if;
--	end process;
--
--	-- inspired by alonho/game_of_life_vhdl
--	outer: for row in 0 to ROWS - 1 generate
--      inner: for column in 0 to COLUMNS - 1 generate
--            upper_left: if (row = 0 and column = 0) generate
--					
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--	
--            end generate upper_left;
--            upper: if (column > 0 and column < COLUMNS - 1 and row = 0) generate 
--				
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--              
--            end generate upper;
--            upper_right: if (column = COLUMNS - 1 and row = 0) generate 
--				
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8); --bottom
--              
--            end generate upper_right;
--            left: if (column = 0 and row > 0 and row < ROWS - 1) generate 
--									dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--             
--            end generate left;
--            middle: if (column > 0 and column < COLUMNS - 1 and row > 0 and row < ROWS - 1) generate 
--				
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--              
--            end generate middle;
--            right: if (column = COLUMNS - 1 and row > 0 and row < ROWS - 1) generate 
--				
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8); --bottom
--         
--            end generate right;
--            lower_left: if (column = 0 and row = ROWS - 1) generate 
--					
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8); -- right
--              
--            end generate lower_left;
--            lower: if (column > 0 and column < COLUMNS - 1 and row = ROWS - 1) generate 
--					
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8); -- right
--              
--            end generate lower;
--            lower_right: if (column = COLUMNS - 1 and row = ROWS - 1) generate 
--				
--					dataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= dataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ dataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8); -- left
--              
--            end generate lower_right;
--        end generate inner;
--    end generate outer;

--	algorithm: process(clk, reset)
--	variable right, left, up, down : boolean := false;
--	
--	variable result : unsigned(INTSIZE-1 downto 0) := (others => '0');
--	
--	variable memory : memory_array := (others=>(others=>(others=>'0')));
--	
--	variable started : boolean := false;
--	
--	variable memtemp : unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0) := (others => '0');
--	
--	variable row : integer range 0 to ROWS - 1 := 0;
--	variable column : integer range 0 to COLUMNS - 1 := 0;
--	
--	begin				
--		if reset = '1' then
--			--reset conditions
--			result := (others => '0');
--			started := false;
--			valid <= '0';
--			row := 0;
--			column := 0;
--		elsif rising_edge(clk) then
--			if started = false and dataInValid = '1' then --initial latching of data
--				valid <= '0';
--				row := 0;
--				column := 0;
--				result := (others => '0');
--				started := true;
--				--need to shove the input massif into a nice "array"
--				for i in 0 to ROWS - 1 loop
--					for j in 0 to COLUMNS - 1 loop
--						memory(i,j) := dataIn(INTSIZE*(COLUMNS*ROWS - j - i*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - j - i*COLUMNS) - 8);
--					end loop;
--				end loop;
--			elsif started then
--
--			end if;
--			
--		end if;
--	end process;


end Behavioral;

