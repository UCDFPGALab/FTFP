--*********************RECIEVER*****************************--
-- This code uses the standard RS-232 transmission standard:--
-- Idle line is high, the start bit is 0, followed by 8 bits--
-- of data. After this there can be an optional parity bit  --
-- for error checking and correction, followed by a high    --
-- stop bit.                                                --

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Receiver is
	generic (
		BAUD: integer := 434 --constant BAUD = clock rate (50MHz) / Baud rate of serial connection
	);
	port (
		rxd   : in std_logic;  -- reciever line
		reset : in std_logic;
		clk   : in std_logic;
		char  : out unsigned(7 downto 0);
		valid : out std_logic := '0'
	);
end Receiver;

architecture Behavioral of Receiver is

	--------------------------------------
	-- 				Signals					--
	--------------------------------------

	type state_type is (idle, data, stop);
	signal currentState, nextState: state_type := idle;

	signal currentCount, nextCount : integer range 0 to BAUD*2;
	--We cannot use a slower "clock" for this, since it can start whenever, unless that slower
	--clock has an enable and disable. I chose to implement this with a counter in this module instead
	signal bitCount    , nextBit   : integer range 0 to 7;
	signal nextStore, currentStore : unsigned ( 7 downto 0 );

begin
	-------------------------------------- 
	-- 				Code						--
	--------------------------------------
			
	char <= currentStore;
	
	--Clocked process--
	clocked: process(clk, reset)
	begin
		if reset = '1' then
			currentStore <= (others => '0');
			currentCount <= 0;
			bitCount <= 0;
			currentState <= idle;
		elsif rising_edge(clk) then
			currentState <= nextState;
			currentStore <= nextStore;
			currentCount <= nextCount;
			bitCount <= nextBit;
		end if;
	end process;
	
	--Asynchronous logic--
	asynch: process (currentState, bitCount, currentStore, rxd, currentStore, currentCount)
	begin
		nextBit <= bitCount;
		nextState <= currentState;
		nextStore <= currentStore;
		nextCount <= currentCount;
		valid <= '0'; 
		--tells us when the output of the module is valid so that we do not read it when it is changing
		
		case currentState is
			when idle =>
				nextBit <= 0;
				if RXD = '0' then --start bit encountered
					nextCount <= currentCount + 1;
					if currentCount = BAUD/2 then
						nextCount <= 0;
						nextState <= data;
					end if;
				end if;
			
			when data => --reads 8 bits. Communication can be sped up by reading only 7.
				nextCount <= currentCount + 1;
				if currentCount = BAUD then
					nextCount <= 0;
					nextStore(bitCount) <= rxd;
					nextBit <= bitCount + 1;
					if bitCount = 7 then
						nextState <= stop;
						nextBit <= 0;
					end if;
				end if;
					
			when stop => -- does not actually expect a stop bit, but waits nevertheless.
				nextCount <= currentCount + 1;
				valid <= '0';
				if currentCount = BAUD-1 then
					valid <= '1';  --the output of this module is now valid
				elsif currentCount = BAUD then
					valid <= '0';
					nextCount <= 0;
					nextState <= idle;
				end if;
				
		end case;
	end process;
end Behavioral;