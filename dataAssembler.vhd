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
				ready     : out std_logic;
				dataOut   : out unsigned(outputBits-1 downto 0);
		      done      : out std_logic);
end dataAssembler;

architecture Behavioral of dataAssembler is

	type state_type is (idle, getting, sending);
	signal currentState, nextState : state_type := idle;
	
	signal currentPointer, nextPointer : integer range 0 to OUTPUTBITS := 0;
	signal currentDataOut : unsigned (OUTPUTBITS-1 downto 0) := (others => '0');
	
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
		elsif rising_edge(clk) then
			currentState <= nextState;
			currentPointer <= nextPointer;
			currentDone <= nextDone;
			if currentPointer /= nextPointer then
				currentDataOut(OUTPUTBITS-1-currentPointer downto OUTPUTBITS-currentPointer-INPUTBITS ) <= dataIn;
			end if;
		end if;
	end process;
	
	asynch: process(currentState, dataValid)
	begin
	
		nextState <= currentState;
		nextPointer <= currentPointer;
		nextDone <= currentDone;
		ready <= '1';
	
		case currentState is
			when idle =>
				nextDone <= '0';
				if dataValid = '1' then
					nextPointer <= currentPointer + INPUTBITS;
					nextState <= getting;
					ready <= '0';
				end if;
			
			when getting =>
				ready <= '0';
				if dataValid = '1' then
					nextPointer <= currentPointer + INPUTBITS;
				end if;
				
				if (currentPointer + INPUTBITS = OUTPUTBITS) then
					nextPointer <= 0;
					nextDone <= '1';
					nextState <= idle;
				end if;
				
			
		end case;
	
	end process;
end Behavioral;