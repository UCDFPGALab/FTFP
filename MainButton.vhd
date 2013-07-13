library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Xilinx components, like IBUF
library UNISIM;
use UNISIM.VComponents.all;

entity Main is
	port(
		SYSCLK_P : in std_logic;
		SYSCLK_N : in std_logic;
		USB_UART_RX : in std_logic;
		GPIO_BUTTON0 : in std_logic;
		USB_UART_TX : out std_logic
		);
end Main;

architecture Behavioral of Main is

	--********************************************************************************************--
	--****************************************COMPONENTS******************************************--
	--********************************************************************************************--

	component Transmitter is
		generic (BAUD       : integer := 434; --BAUD = clock rate (50MHz) / Baud rate of serial connection
					stopBits   : integer range 0 to 2 := 1;
					dataBits   : integer range 7 to 8 := 8;
					parityBit  : boolean := false); --does even parity
		port    (clk      : in std_logic;
					reset    : in std_logic;
					start    : in std_logic;
					dataIn   : in unsigned(7 downto 0);
					txd      : out std_logic; --output transmit line
					done     : out std_logic);
	end component;
	
	component Receiver is
	generic(BAUD: integer := 434); --constant BAUD = clock rate (50MHz) / Baud rate of serial connection
	port( rxd   : in std_logic;  -- reciever line
			reset : in std_logic;
			clk   : in std_logic;
			char  : out unsigned(7 downto 0);
			valid : out std_logic := '0');
	end component;
	
	component NBitCircularBuffer is
	generic (sizeOfCell : integer range 1 to 256 := 8; -- size of each cell in the buffer
				sizeOfBuffer   : integer range 1 to 256 := 32); -- number of cells in buffer
	port    (clk            : in std_logic;
				reset          : in std_logic;
				inputData      : in unsigned (sizeOfCell - 1 downto 0);
				inputReady     : in std_logic; --should only be high for one clock cycle, otherwise store data twice
				valueRead      : in std_logic; --should be asserted when you've read the current output value
				entries        : out integer range 0 to sizeOfBuffer;
				outputData     : out unsigned (sizeOfCell - 1 downto 0));
	end component;
	
	--********************************************************************************************--
	--****************************************CONSTANT********************************************--
	--********************************************************************************************--
	
	--RS-232 Constants
	constant CLOCKDIVIDER : integer := 20833;
	constant STOPBITS : integer := 1;
	constant DATABITS : integer := 8;
	constant PARITY : boolean := false;
	
	--Buffer constants
	constant SIZEOFCELL : integer := 8; -- size of each cell in the buffer (in bits)
	constant SIZEOFBUFFER : integer := 40; -- number of cells in buffer
	
	--********************************************************************************************--
	--****************************************SIGNALS*********************************************--
	--********************************************************************************************--

	--Global signals
	signal globalReset : std_logic := '0';

	--Primitives signals
	signal BUFGsig : std_logic := '0';
	signal CLK     : std_logic := '0';
	
	--RS-232 Signals
	signal transReset, transStart, transDone, recValid, recReset : std_logic := '0';
	signal transChar, recChar : unsigned(7 downto 0) := (others => '0');
	
	--Buffer signals
	signal inputBufReset, inputBufRead, inputBufReady, outputBufReset, outputBufRead, outputBufReady : std_logic := '0';
	signal inputBufDataIn, inputBufDataOut, outputBufDataIn, outputBufDataOut : unsigned(SIZEOFCELL-1 downto 0);
	signal inputBufEntries, outputBufEntries : integer range 0 to SIZEOFBUFFER := 0;

begin

	--********************************************************************************************--
	--****************************************PRIMITIVES******************************************--
	--********************************************************************************************--	

	IBUFGDS_inst : IBUFGDS
	generic map 
	(
		IOSTANDARD => "DEFAULT"
	)
	port map 
	(
		O => BUFGsig, -- Clock buffer output
		I => SYSCLK_P, -- Diff_p clock buffer input
		IB => SYSCLK_N -- Diff_n clock buffer input
	);
-- End of IBUFGDS_inst instantiation

	BUFG_inst : BUFG
	port map 
	(
		O => CLK, -- 1-bit Clock buffer output
		I => BUFGsig -- 1-bit Clock buffer input
	);
	
	
	--********************************************************************************************--
	--****************************************PORT MAPS*******************************************--
	--********************************************************************************************--	
	
	Trans: Transmitter
	generic map 
	(
		BAUD       => CLOCKDIVIDER, --BAUD = clock rate (200MHz) / Baud rate of serial connection
		stopBits   => STOPBITS,
		dataBits   => DATABITS,
		parityBit  => PARITY --does even parity
	)
	port map
	(
		clk      => CLK,
		reset    => transReset,
		start    => transStart,
		dataIn   => transChar,
		txd      => USB_UART_TX,
		done     => transDone
	);
	
	Recieve: Receiver
	generic map
	(
		BAUD => CLOCKDIVIDER --constant BAUD = clock rate (200MHz) / Baud rate of serial connection
	)
	port map
	( 
		rxd   => USB_UART_RX, -- reciever line
		reset => recReset,
		clk   => CLK,
		char  => recChar,
		valid => recValid
	);
	
	inputBUF: NBitCircularBuffer
	generic map
		(
			sizeOfCell => SIZEOFCELL, -- size of each cell in the buffer
			sizeOfBuffer   => SIZEOFBUFFER -- number of cells in buffer
		)
	port map
		(
			clk            => CLK,
			reset          => inputBufReset,
			inputData      => inputBufDataIn,
			inputReady     => inputBufReady, --should only be high for one clock cycle, otherwise store data twice
			valueRead      => inputBufRead, --should be asserted when you've read the current output value
			entries        => inputBufEntries,
			outputData     => inputBufDataOut
		);
		
	outputBUF: NBitCircularBuffer
	generic map
		(
			sizeOfCell => SIZEOFCELL, -- size of each cell in the buffer
			sizeOfBuffer   => SIZEOFBUFFER -- number of cells in buffer
		)
	port map
		(
			clk            => CLK,
			reset          => outputBufReset,
			inputData      => outputBufDataIn,
			inputReady     => outputBufReady, --should only be high for one clock cycle, otherwise store data twice
			valueRead      => outputBufRead, --should be asserted when you've read the current output value
			entries        => outputBufEntries,
			outputData     => outputBufDataOut
		);
	
	--********************************************************************************************--
	--****************************************CODE************************************************--
	--********************************************************************************************--
	
	--Muxes
	with globalReset select
	transReset <= transReset when '0',
						'1' when others;
						
	with globalReset select
	recReset <= recReset when '0',
						'1' when others;
						
	with globalReset select
	inputBufReset <= inputBufReset when '0',
						'1' when others;
						
	with globalReset select
	outputBufReset <= outputBufReset when '0',
						'1' when others;
						
--Loopback setup
--	transChar <= recChar;
--	transStart <= recValid;
						
--Buffer test code block

	inputBufDataIn <= recChar;
	inputBufReady <= recValid;
	transChar <= inputBufDataOut;
					  
	ReadMonitor: process(clk)
	variable state : integer range 0 to 3;
	begin
		if rising_edge(clk) then
			if state = 0 and inputBufEntries /= 0 and GPIO_BUTTON0 = '1' then
				transStart <= '1';
				inputBufRead <= '1';
				state := 1;
			elsif state = 1 then
				inputBufRead <= '0';
				transStart <= '0';
				if transDone = '1' then
					state := 0;
				end if;
			end if;
		end if;
	end process;


end Behavioral;

