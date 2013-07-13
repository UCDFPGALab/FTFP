--NBit circular buffer (FIFO) with variable size cells that can do writes and reads at
--the same time. This is possible because it does not ever read the memory location
--currently being written (clock cycle delay between a read and a write to the same cell).
--Which is probably leading up to some setup time or hold violations...

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NBitCircularBuffer is
	generic (sizeOfCell : integer := 8; -- size of each cell in the buffer
				sizeOfBuffer   : integer := 32); -- number of cells in buffer
	port    (clk            : in std_logic;
				reset          : in std_logic;
				inputData      : in unsigned (sizeOfCell - 1 downto 0);
				inputReady     : in std_logic; --should only be high for one clock cycle, otherwise store data twice
				valueRead      : in std_logic; --should be asserted when you've read the current output value
				entries        : out integer range 0 to sizeOfBuffer;
				outputData     : out unsigned (sizeOfCell - 1 downto 0));
end NBitCircularBuffer;

architecture Behavioral of NBitCircularBuffer is	

	--------------------------------------
	-- 				Signals					--
	--------------------------------------
	type memory_type is array (0 to sizeOfBuffer - 1) of unsigned (sizeOfCell - 1 downto 0);
	signal memory     : memory_type :=(others => (others => '0')); --memory for buffer, all set to 0 originally
	
	signal currentReadPointer, nextReadPointer, currentWritePointer, nextWritePointer : integer range 0 to (sizeOfBuffer - 1) := 0;
	signal currentEntries, nextEntries     : integer range 0 to sizeOfBuffer := 0;
	
	signal change : integer range -1 to 1 := 0;
	
begin

	-------------------------------------- 
	-- 				Code						--
	--------------------------------------
	
	entries <= currentEntries;
	outputData <= memory(currentReadPointer);
	
	change <= 1 when inputReady = '1' and valueRead = '0' and currentEntries /= sizeOfBuffer else
				 -1 when inputReady = '0' and valueRead = '1' and currentEntries /= 0 else
				 0;
				 
	nextEntries <= currentEntries + change;
	
	synch: process(clk, reset)
	begin
		if reset = '1' then
			memory <= (others => (others => '0'));
			currentEntries <= 0;
			currentWritePointer <= 0;
			currentReadPointer <= 0;
		elsif rising_edge(clk) then
			currentEntries <= nextEntries;
			currentReadPointer <= nextReadPointer;
			currentWritePointer <= nextWritePointer;
			if inputReady = '1' and currentEntries /= sizeOfBuffer then
				memory(currentWritePointer) <= inputData;
			end if;
		end if;
	end process;
	
	asynchRead: process(currentEntries, valueRead, currentReadPointer)
	begin
		nextReadPointer <= currentReadPointer;
		
		if currentEntries /= 0 and valueRead = '1' then
			nextReadPointer <= currentReadPointer + 1;
			if currentReadPointer = sizeOfBuffer - 1 then
				nextReadPointer <= 0;
			end if;
		end if;
	end process;
	
	asynchWrite: process(currentWritePointer, currentEntries, inputReady)
	begin
		nextWritePointer <= currentWritePointer;
		
		if currentEntries /= sizeOfBuffer and inputReady = '1' then
			nextWritePointer <= currentWritePointer + 1;
			if currentWritePointer = sizeOfBuffer - 1 then
				nextWritePointer <= 0;
			end if;
		end if;
	end process;
	
end Behavioral;