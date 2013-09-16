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
	type mem is array(integer range 0 to ROWS-1, integer range 0 to COLUMNS-1) of tmp;
	
	signal memory : mem := (others => (others => (others => '0')));

begin


	--generates the proper matrix to work on, easier to reference later
	--for ease of programming, I'm assuming that ETA and RETA and so on are part of this grid
	--genRows: for i in 0 to ROWS-1 generate
	--	genColumns: for j in 0 to COLUMNS-1 generate
	--		mem(i)(j) <= dataIn(INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE downto INTSIZE*ROWS*COLUMNS-1 - i*COLUMNS*INTSIZE - j*INTSIZE - 7);
	--	end generate genColumns;
	--end generate genRows;
	
	genAdd: for i in 0 to ROWS*COLUMNS - 1 generate
		dataOut(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE downto INTSIZE*ROWS*COLUMNS - (i+1)*INTSIZE) <= 
			dataIn(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE downto INTSIZE*ROWS*COLUMNS - (i+1)*INTSIZE) + 
			dataIn(INTSIZE*ROWS*COLUMNS-1 - i*INTSIZE +  INTSIZE*ROWS*COLUMNS
				downto INTSIZE*ROWS*COLUMNS - (i+1)*INTSIZE + INTSIZE*ROWS*COLUMNS);
	end generate genAdd;


	pipeliner: process(clk, reset)
	-- setting an update signal here between the different stages of the synchronous calculations
	-- will cause it to create flip flops, pipelining it
	begin
		if reset = '1' then
			-- reset all the flip flops
		elsif rising_edge(clk) then
			-- assumes all the proper asynch signals have been updated at this point
			-- push them to the next flip flop on clock edge
			-- for i in 0 to 3 loop
			--		case i is  
			--			when 0 => temp1 <= a*data;
			--			when 1 => temp2 <= temp1*b;
			if dataInValid = '1' then
				valid <= '1';
			else
				valid <= '0';
			end if;
		end if;
	end process;
	
end Behavioral;