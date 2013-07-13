library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dataDisassembler is
	generic (INPUTBITS   : integer := 128;
				OUTPUTBITS  : integer := 8;  --4x4 1 byte grid
				INPUTDELAY  : integer := 15;
				OUTPUTDELAY : integer := 2);
	port    (clk       : in std_logic;
		      reset     : in std_logic;
		      dataIn    : in unsigned(inputBits-1 downto 0);
				dataValid : in std_logic;
				dataRead  : in std_logic;
				ready     : out std_logic;
				dataOut   : out unsigned(outputBits-1 downto 0);
		      done      : out std_logic);
end dataDisassembler;

architecture Behavioral of dataDisassembler is

	type state_type is (idle, pushing);
	signal currentState, nextState : state_type := idle;
	
	signal currentPointer, nextPointer : integer range 0 to INPUTBITS/OUTPUTBITS := 0;
	signal nextDataIn, currentDataIn : unsigned (INPUTBITS-1 downto 0) := (others => '0');
	signal nextDataOut, currentDataOut : unsigned (OUTPUTBITS - 1 downto 0) := (others => '0');
	
	signal nextDone, currentDone : std_logic := '0';

begin

	assert (OUTPUTBITS < INPUTBITS) 
		report "INPUTBITS is not greater than OUTPUTBITS, use disassembler instead" 
		severity error;
		
	assert ((INPUTBITS mod OUTPUTBITS) = 0) 
		report "INPUTBITS is not nicely divided by OUTPUTBITS, change that" 
		severity error;
	
	dataOut <= currentDataOut;
	done <= currentDone;

	synch: process(clk, reset)
	begin
		if reset = '1' then
			currentState <= idle;
			currentPointer <= 0;
			currentDataIn <= (others => '0');
			currentDataOut <= (others => '0');
			currentDone <= '0';
		elsif rising_edge(clk) then
			currentState <= nextState;
			currentPointer <= nextPointer;
			currentDataIn <= nextDataIn;
			currentDataOut <= nextDataOut;
			currentDone <= nextDone;
		end if;
	end process;
	
	asynch: process(currentState, dataValid, dataRead, currentPointer, currentDataIn, currentDataOut, currentDone, dataIn)
	begin
		nextState <= currentState;
		nextPointer <= currentPointer;
		nextDataIn <= currentDataIn;
		nextDataOut <= currentDataOut;
		nextDone <= currentDone;
		ready <= '0';
	
		case currentState is
			when idle =>
				ready <= '0';
				nextDone <= '0';
				if dataValid = '1' then
					nextDataIn <= dataIn;
					nextState <= pushing;
					nextDataOut <= dataIn(INPUTBITS - currentPointer*OUTPUTBITS - 1 downto INPUTBITS - (currentPointer+1)*OUTPUTBITS);
					ready <= '0';
				end if;
			
			when pushing =>
				ready <= '1';
				nextDataOut <= currentDataIn(INPUTBITS - currentPointer*OUTPUTBITS - 1 downto INPUTBITS - (currentPointer+1)*OUTPUTBITS);
				
				if dataRead = '1' then
					nextPointer <= currentPointer + 1;
					
					if ((currentPointer + 1)*OUTPUTBITS = INPUTBITS) then
						nextPointer <= 0;
						nextState <= idle;
						nextDone <= '1';
					end if;
				end if;
				
			
		end case;
	
	end process;
end Behavioral;