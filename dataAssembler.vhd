library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dataAssembler is
	generic (INPUTBITS   : integer := 8;
				OUTPUTBITS  : integer := 128;  --4x4 1 byte grid
				INPUTDELAY  : integer := 15;
				OUTPUTDELAY : integer := 2);
	port    (clk       : in std_logic;
		      reset     : in std_logic;
		      dataIn    : in unsigned(inputBits-1 downto 0);
				dataValid : in std_logic;
				dataOut   : out unsigned(outputBits-1 downto 0);
				idleOut      : out std_logic;
		      done      : out std_logic);
end dataAssembler;

architecture Behavioral of dataAssembler is

	type state_type is (idle, getting, doneState);
	signal currentState, nextState : state_type := idle;
	
	signal currentPointer, nextPointer : integer range 0 to OUTPUTBITS/INPUTBITS - 1 := 0;
	signal currentDataOut, nextDataOut : unsigned (OUTPUTBITS-1 downto 0) := (others => '0');
	
	signal currentDone, nextDone : std_logic := '0';

begin

	assert (OUTPUTBITS > INPUTBITS) 
		report "OUTPUTBITS is not greater than INPUTBITS, use disassembler instead" 
		severity error;
		
	assert ((OUTPUTBITS mod INPUTBITS) = 0) 
		report "OUTPUTBITS is not nicely divided by INPUTBITS, change that" 
		severity error;

	dataOut <= currentDataOut;
	done <= currentDone;

	synch: process(clk, reset)
	begin
		if reset = '1' then
			currentState <= idle;
			currentPointer <= 0;
			currentDone <= '0';
			currentDataOut <= (others => '0');
		elsif rising_edge(clk) then
			currentState <= nextState;
			currentPointer <= nextPointer;
			currentDone <= nextDone;
			currentDataOut <= nextDataOut;
		end if;
	end process;
	
	asynch: process(currentState, dataValid, currentPointer, currentDone, currentDataOut, dataIn)
	begin
	
		nextState <= currentState;
		nextPointer <= currentPointer;
		nextDone <= currentDone;
		nextDataOut <= currentDataOut;
		idleOut <= '0';
	
		case currentState is
			when idle =>
				nextDone <= '0';
				idleOut <= '1';
				if dataValid = '1' then
					nextPointer <= currentPointer + 1;
					nextDataOut(OUTPUTBITS - 1 - currentPointer*INPUTBITS downto OUTPUTBITS - INPUTBITS - currentPointer*INPUTBITS) <= dataIn;
					nextState <= getting;
					idleOut <= '0';
				end if;
			
			when getting =>
				if dataValid = '1' then
					nextPointer <= currentPointer + 1;
					nextDataOut(OUTPUTBITS - 1 - currentPointer*INPUTBITS downto OUTPUTBITS - INPUTBITS - currentPointer*INPUTBITS) <= dataIn;
				end if;
				
				if ((currentPointer + 1)*INPUTBITS = OUTPUTBITS) and dataValid = '1' then
						nextPointer <= 0;
						nextState <= doneState;
				end if;
				
			when doneState =>
				nextDone <= '1';
				nextState <= idle;
				
			
		end case;
	
	end process;
end Behavioral;