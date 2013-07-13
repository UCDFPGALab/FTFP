--Meant to sit on top of the circular buffer, and introduce the necessary delay to make the buffer operate properly without errors when the buffer size gets big.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity preBuffer is
	generic (SIZE  : integer := 128;
				SETUP : integer := 1;
				HOLD  : integer := 1); -- in clock cycles
	port    (clk      : in std_logic;
		      reset    : in std_logic;
		      dataIn   : in unsigned(SIZE - 1 downto 0);
				dataInValid : in std_logic;
				dataOut  : out unsigned(SIZE - 1 downto 0);
				valid    : out std_logic);
end preBuffer;

architecture Behavioral of preBuffer is

	type state_type is (idle, setupstate, push);
	signal currentState, nextState : state_type := idle;

	signal currentData, nextData : unsigned (SIZE - 1 downto 0) := (others => '0');
	signal currentCounter, nextCounter : integer range 0 to (SETUP+HOLD) := 0;
	signal nextValid, currentValid : std_logic := '0';
begin


	dataOut <= currentData when SETUP /= 0 else
				  dataIn;
	valid <= currentValid when SETUP /= 0 else
				dataInValid;

	synch: process (clk, reset)
	begin
		if reset = '1' then
			currentData <= (others => '0');
			currentCounter <= 0;
			currentValid <= '0';
			currentState <= idle;
		elsif rising_edge(clk) then
			currentData <= nextData;
			currentCounter <= nextCounter;
			currentValid <= nextValid;
			currentState <= nextState;
		end if;
	end process;

	asynch: process(dataIn, currentData, currentCounter, currentState, currentValid, dataInValid)
	begin
	
		nextData <= currentData;
		nextCounter <= currentCounter;
		nextState <= currentState;
		nextValid <= currentValid;
		
		case currentState is
			when idle =>
				if dataInValid = '1' then
					nextData <= dataIn;
					nextCounter <= 0;
					nextState <= setupstate;
				end if;
				
			when setupstate =>
				nextCounter <= currentCounter + 1;
				if currentCounter = SETUP - 1 then
					nextCounter <= 0;
					nextValid <= '1';
					nextState <= push;
				end if;
				
			when push =>
				nextCounter <= currentCounter + 1;
				nextValid <= '0';
				if currentCounter = HOLD - 1 then
					nextCounter <= 0;
					nextState <= idle;
				end if;
		end case;
			
	
	end process;

end Behavioral;