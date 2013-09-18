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
		      dataIn   : in unsigned(INTSIZE*ROWS*COLUMNS*2-1 downto 0);
				dataInValid : in std_logic;
				dataOut  : out unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0);
				valid    : out std_logic);
end Pipeline;

architecture Behavioral of Pipeline is
	
	subtype tmp is unsigned(INTSIZE-1 downto 0);
	type arr1 is array(0 to ROWS-1, 0 to COLUMNS-1) of tmp;
	type arr2 is array(0 to 10) of arr1;
	
	
	signal memory : arr2 := (others => (others => (others => (others => '0'))));
	signal counter : integer range 0 to 127 := 0;

begin


--********* CODE BLOCK FOR SEPARATING THE MASSIF INTO A NICE MATRIX ********	
	--generates the proper matrix to work on, easier to reference later
	--for ease of programming, I'm assuming that ETA and RETA and so on are part of this grid
	--genRows: for i in 0 to ROWS-1 generate
	--	genColumns: for j in 0 to COLUMNS-1 generate
	--		mem(i)(j) <= dataIn(INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE downto INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE - 7);
	--	end generate genColumns;
	--end generate genRows;
--********* CODE BLOCK FOR SEPARATING THE MASSIF INTO A NICE MATRIX ********	

--********* CODE BLOCK FOR ADDING CELLS OF 2 MATRICES ********	
--	genAdd: for i in 0 to ROWS*COLUMNS - 1 generate
--		dataOut(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE downto INTSIZE*ROWS*COLUMNS - (i+1)*INTSIZE) <= 
--			dataIn(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE downto INTSIZE*ROWS*COLUMNS - (i+1)*INTSIZE) + 
--			dataIn(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE +  INTSIZE*ROWS*COLUMNS
--				downto INTSIZE*ROWS*COLUMNS - (i+1)*INTSIZE + INTSIZE*ROWS*COLUMNS);
--	end generate genAdd;
--********* CODE BLOCK FOR ADDING CELLS OF 2 MATRICES ********

			gen1: for i in 0 to ROWS-1 generate
				gen2: for j in 0 to COLUMNS-1 generate
					dataOut(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE*COLUMNS - j*INTSIZE downto INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE*COLUMNS - j*INTSIZE - 7) <=
						dataIn(INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE
							downto INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE - 7);
				end generate gen2;
			end generate gen1;
			
			valid <= dataInValid;




--	pipeliner: process(clk, reset)
--	-- setting an update signal here between the different stages of the synchronous calculations
--	-- will cause it to create flip flops, pipelining it
--	begin
--		if reset = '1' then
--			-- reset all the flip flops
--		elsif rising_edge(clk) then
--			-- assumes all the proper asynch signals have been updated at this point
--			-- push them to the next flip flop on clock edge
--			-- for i in 0 to 3 loop
--			--		case i is  
--			--			when 0 => temp1 <= a*data;
--			--			when 1 => temp2 <= temp1*b;
--			
--			--*** THE DATA VALID IS NOT EVEN NECESSARY, AND SIMPLY HERE FOR INTERNAL BOOKKEEPING (determines when the output signal will become valid *****
--			
--			--$$First flip flop: initial load into nice matrix
--			if dataInValid = '1' then
--				counter <= 1;
--			
--				for i in 0 to ROWS-1 loop
--					for j in 0 to COLUMNS-1 loop
--						
--						memory(0)(i,j) <= dataIn(INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE 
--							downto INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE - 7);
--						
--						memory(1)(i,j) <= dataIn(INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE + INTSIZE*ROWS*COLUMNS 
--							downto INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE - 7 + INTSIZE*ROWS*COLUMNS);
--						
--					end loop;
--				end loop;
--			end if;
--			--##First flip flop
--			
--			--$$Second flip flop: add the two cells together, sample algorithm
--			for i in 0 to ROWS-1 loop
--				for j in 0 to COLUMNS-1 loop
--					memory(2)(i,j) <= memory(0)(i,j) + memory(1)(i,j);
--				end loop;
--			end loop;
--			--##Second flip flop
--			
--			--$$Third flip flop, exit algorithm
--			for i in 0 to ROWS-1 loop
--				for j in 0 to COLUMNS-1 loop
--					dataOut(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE downto INTSIZE*ROWS*COLUMNS - (i+1)*INTSIZE) <=
--						dataIn(INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE 
--							downto INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE - 7);
--						--memory(0)(i,j);
--				end loop;
--			end loop;
--			--##Third flip flop
--			
--		end if;
--	end process;
	
	--	-- inspired by alonho/game_of_life_vhdl
--	outer: for row in 0 to ROWS - 1 generate
--      inner: for column in 0 to COLUMNS - 1 generate
--            upper_left: if (row = 0 and column = 0) generate
--
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--	
--            end generate upper_left;
--            upper: if (column > 0 and column < COLUMNS - 1 and row = 0) generate 
--
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--              
--            end generate upper;
--            upper_right: if (column = COLUMNS - 1 and row = 0) generate 
--
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8); --bottom
--              
--            end generate upper_right;
--            left: if (column = 0 and row > 0 and row < ROWS - 1) generate 
--				
--				currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--             
--            end generate left;
--            middle: if (column > 0 and column < COLUMNS - 1 and row > 0 and row < ROWS - 1) generate 
--			
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8) -- right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8) --bottom
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row+1)*COLUMNS) - 8); -- bottom right
--              
--            end generate middle;
--            right: if (column = COLUMNS - 1 and row > 0 and row < ROWS - 1) generate 
--				
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row+1)*COLUMNS) - 8) -- bottom left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row+1)*COLUMNS) - 8); --bottom
--         
--            end generate right;
--            lower_left: if (column = 0 and row = ROWS - 1) generate 
--					
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8); -- right
--              
--            end generate lower_left;
--            lower: if (column > 0 and column < COLUMNS - 1 and row = ROWS - 1) generate 
--					
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row-1)*COLUMNS) - 8) -- top right
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8) -- left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column+1) - (row)*COLUMNS) - 8); -- right
--              
--            end generate lower;
--            lower_right: if (column = COLUMNS - 1 and row = ROWS - 1) generate 
--								
--					currentDataOut(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8)
--						<= currentDataIn(INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - column - row*COLUMNS) - 8) --itself
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row-1)*COLUMNS) - 8) --top left
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column) - (row-1)*COLUMNS) - 8) -- top
--						+ currentDataIn(INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 1 downto INTSIZE*(COLUMNS*ROWS - (column-1) - (row)*COLUMNS) - 8); -- left
--              
--            end generate lower_right;
--        end generate inner;
--    end generate outer;

	
end Behavioral;