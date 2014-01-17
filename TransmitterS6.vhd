-- This code uses the standard RS-232 transmission standard:--
-- Idle line is high, the start bit is 0, followed by 8 bits--
-- of data. After this there can be an optional parity bit  --
-- for error checking and correction, followed by a high    --
-- stop bit.                                                --

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Transmitter is
	generic (
		BAUD			: integer := 434; --BAUD = clock rate (50MHz) / Baud rate of serial connection
		stopBits		: integer range 0 to 2 := 1;
		dataBits		: integer range 7 to 8 := 8;
		parityBit	: boolean := false --does even parity
	);
	port (
		clk		: in std_logic;
		reset		: in std_logic;
		start		: in std_logic;
		dataIn	: in unsigned(7 downto 0);
		txd		: out std_logic; --output transmit line
		done		: out std_logic;
		ready		: out std_logic
	);
end Transmitter;

architecture Behavioral of Transmitter is
	--------------------------------------
	-- 				Components				--
	--------------------------------------
	
	component ClockDivider is
	generic (
		divider		: integer := 2;
		lengthOfHi	: integer := 1 --in clock cycles, has to be less than divider, more than 1
	);
	port (
		clk		: in std_logic;
		reset		: in std_logic;
		enable	: in std_logic;
		tick		: out std_logic
	);
	end component;
	
	--------------------------------------
	-- 				Signals					--
	--------------------------------------
	type state_type is (idleState, startState, dataState, parityState, stopState);
	signal currentState, nextState: state_type;
	
	signal data, nextData : unsigned (dataBits - 1 downto 0) := (others => '0');
	signal parityCalc     : unsigned (7 downto 0) := (others => '0');
	signal parityBitCalc  : std_logic := '0';
	
	signal bitCounter, nextBitCounter  : integer range 0 to dataBits - 1;
	
	signal tick, tickEnable, tickReset : std_logic;
	
begin
	--------------------------------------
	-- 			Port Maps					--
	--------------------------------------
	TickGenerator: ClockDivider
	generic map (
		divider 		=> BAUD,
		lengthOfHi 	=> 1 --in clock cycles, has to be less than divider, more than 1
	)
	port map (
		clk		=> clk,
		reset		=> tickReset,
		enable	=> tickEnable,
		tick		=> tick
	);
	
	-------------------------------------- 
	-- 				Code						--
	--------------------------------------
	parityCalc <= resize(data, 8);
	parityBitCalc <= parityCalc(0) xor 
						  parityCalc(1) xor 
						  parityCalc(2) xor 
						  parityCalc(3) xor 
						  parityCalc(4) xor 
						  parityCalc(5) xor 
						  parityCalc(6) xor 
						  parityCalc(7);
	
	clocked: process(clk, reset)
	begin
		if reset = '1' then
			currentState <= idleState;
			data <= (others => '0');
			bitCounter <= 0;
		elsif rising_edge(clk) then
			currentState <= nextState;
			data <= nextData;
			bitCounter <= nextBitCounter;
		end if;
	end process;
	
	asynch: process(currentState, data, bitCounter, start, dataIn, tick, parityBitCalc)
	begin
		tickReset <= '0';
		tickEnable <= '1';
		txd <= '1';
		done <= '0';
		ready <= '0';
		nextState <= currentState;
		nextData <= data;
		nextBitCounter <= bitCounter;
		
		case currentState is
		
			when idleState =>
				tickReset <= '1';
				tickEnable <= '0';
				ready <= '1';
				if start = '1' then
					nextState <= startState;
					nextData <= dataIn;
					ready <= '0';
				end if;
			
			when startState =>
				txd <= '0';
				if tick = '1' then
					nextState <= dataState;
				end if;
			
			when dataState =>
				txd <= data(bitCounter);
				if tick = '1' then
					if bitCounter = dataBits - 1 then -- all 7 or 8 bits transmitted
						nextBitCounter <= 0;
						if parityBit then
							nextState <= parityState;
						else
							nextState <= stopState;
						end if;
					else
						nextBitCounter <= bitCounter + 1;
					end if;
				end if;
					
			when parityState =>
				txd <= parityBitCalc;
				if tick = '1' then
					nextState <= stopState;
				end if;
			
			when stopState =>
				txd <= '1';
				if tick = '1' then
					if bitCounter = stopBits - 1 then
						nextState <= idleState;
						done <= '1';
						nextBitCounter <= 0;
					else
						nextBitCounter <= bitCounter + 1;
					end if;
				end if;	
		end case;
	end process;
	
end Behavioral;