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
					done     : out std_logic;
					ready    : out std_logic);
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
	generic (sizeOfCell : integer := 8; -- size of each cell in the buffer
				sizeOfBuffer   : integer := 32); -- number of cells in buffer
	port    (clk            : in std_logic;
				reset          : in std_logic;
				inputData      : in unsigned (sizeOfCell - 1 downto 0);
				inputReady     : in std_logic; --should only be high for one clock cycle, otherwise store data twice
				valueRead      : in std_logic; --should be asserted when you've read the current output value
				entries        : out integer range 0 to sizeOfBuffer;
				outputData     : out unsigned (sizeOfCell - 1 downto 0));
	end component;
	
	component ClockDivider is
	generic(divider    : integer := 2;
			  lengthOfHi : integer := 1); --in clock cycles, has to be less than divider, more than 1
	port( clk    : in std_logic;
			reset  : in std_logic;
			enable : in std_logic;
			tick   : out std_logic);
	end component;
	
	component preBuffer is
	generic (SETUP : integer := 1;
				HOLD  : integer := 1); -- in clock cycles
	port    (clk      : in std_logic;
		      reset    : in std_logic;
		      dataIn   : in unsigned(7 downto 0);
				dataInValid : in std_logic;
				dataOut  : out unsigned(7 downto 0);
				valid    : out std_logic);
	end component;
	
	component dataAssembler is
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
	end component;
	
	component dataDisassembler is
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
	end component;
	
	--********************************************************************************************--
	--****************************************CONSTANT********************************************--
	--********************************************************************************************--
	
	
	--RS-232 Constants
	constant DIVIDER : integer := 1736;
	constant STOPBITS : integer := 1;
	constant DATABITS : integer := 8;
	constant PARITY : boolean := false; --not implemented yet, keep false
	
	--Buffer constants
	constant SIZEOFCELLBUFFIN : integer := 128; -- size of each cell in the buffer (in bits)
	constant SIZEOFBUFFERBUFFIN : integer := 1; -- number of cells in buffer
	constant SIZEOFCELLBUFFOUT : integer := 8;
	constant SIZEOFBUFFERBUFFOUT : integer := 50;
	
	--PreBuffer constants
	--Stable configs: SIZEOFCELL/SIZEOFBUFFER/SETUP/HOLD (8/300/15/5)
	constant SETUP : integer := 15; --how many clock cycles to keep the data valid before sending the "store" signal
	constant HOLD : integer := 5; --how many clock cycles to keep the data valid after sending the "store" signal
	
	--Disassembler/assembler constants
	constant BROKENBITS   : integer := SIZEOFCELLBUFFOUT;
	constant	LUMPBITS  : integer := SIZEOFCELLBUFFIN;
	constant DELAY1  : integer := 15;
	constant DELAY2 : integer := 2;
	
	--********************************************************************************************--
	--****************************************SIGNALS*********************************************--
	--********************************************************************************************--

	--Global signals
	signal globalReset : std_logic := '0';

	--Primitives signals
	signal BUFGsig : std_logic := '0';
	signal CLK     : std_logic := '0';
	
	--RS-232 signals
	signal transReset, transStart, transDone, transReady, recValid, recReset : std_logic := '0';
	signal transChar, recChar : unsigned(7 downto 0) := (others => '0');
	
	--timeout signals
	signal ttReset, ttEnable, tt : std_logic := '0';
	
	--Buffer signals
	signal inputBufReset, inputBufRead, inputBufReady, outputBufReset, outputBufRead, outputBufReady : std_logic := '0';
	signal inputBufDataIn, inputBufDataOut, outputBufDataIn, outputBufDataOut : unsigned(SIZEOFCELL-1 downto 0);
	signal inputBufEntries, outputBufEntries : integer range 0 to SIZEOFBUFFER := 0;
	
	--Pre buffer signals
	signal preBufInValid, preBufValid, preBufReset : std_logic := '0';
	signal preBufDataIn, preBufDataOut : unsigned(7 downto 0) := (others => '0');
	
	--Assembler/Disassembler signals
	signal dataAssReset, dataDissReset, dataAssInValid, dataAssReady, dataAssDone, dataDissValid, dataDissRead, dataDissReady, dataDissDone : std_logic := '0';
	signal dataAssIn, dataDissOut : unsigned (BROKENBITS - 1 downto 0) := (others => '0');
	signal dataAssOut, dataDissIn : unsigned (LUMPBITS - 1 downto 0) := (others => '0');

begin

	--Assertions
	assert (SETUP + HOLD + 2) < (DIVIDER * (1 + STOPBITS + DATABITS))
		report "Prebuffer takes too long to setup and hold, will overflow"
		severity ERROR;

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
		BAUD       => DIVIDER, --BAUD = clock rate (200MHz) / Baud rate of serial connection
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
		done     => transDone,
		ready    => transReady
	);
	
	Recieve: Receiver
	generic map
	(
		BAUD => DIVIDER --constant BAUD = clock rate (200MHz) / Baud rate of serial connection
	)
	port map
	( 
		rxd   => USB_UART_RX, -- reciever line
		reset => recReset,
		clk   => CLK,
		char  => recChar,
		valid => recValid
	);
	
	preBuffer1: preBuffer
	generic map 
		(
			SETUP => 15,
			HOLD  => 5 -- in clock cycles
		 )
	port map
		(
			clk      => clk,
		   reset    => preBufReset,
		   dataIn   => preBufDataIn,
			dataInValid => preBufInValid,
			dataOut  => preBufDataOut,
			valid    => preBufValid
		 );
	
	inputBUF: NBitCircularBuffer
	generic map
		(
			sizeOfCell => SIZEOFCELLBUFFIN, -- size of each cell in the buffer
			sizeOfBuffer   => SIZEOFBUFFERBUFFIN -- number of cells in buffer
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
			sizeOfCell => SIZEOFCELLBUFFOUT, -- size of each cell in the buffer
			sizeOfBuffer   => SIZEOFBUFFERBUFFOUT -- number of cells in buffer
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
		
	timeoutTT: ClockDivider
	generic map
		(
			divider => 50000000,
			lengthOfHi => 1 --in clock cycles, has to be less than divider, more than 1
		)
	port map
		(
			clk    => clk,
			reset  => ttReset,
			enable => ttEnable,
			tick   => tt
		);
		
	dataAss1: dataAssembler
	generic map
		(
			INPUTBITS   => BROKENBITS,
			OUTPUTBITS  => LUMPBITS,  --4x4 1 byte grid
			INPUTDELAY  => DELAY1,
			OUTPUTDELAY => DELAY2
		)
	port map
		(
			clk       => clk,
		   reset     => dataAssReset,
		   dataIn    => dataAssIn,
			dataValid => dataAssInValid,
			ready     => dataAssReady,
			dataOut   => dataAssOut,
		   done      => dataAssDone
		);
	
	dataDiss1: dataDisassembler
	generic map 
		(
			INPUTBITS   => LUMPBITS,
			OUTPUTBITS  => BROKENBITS,
			INPUTDELAY  => DELAY1,
			OUTPUTDELAY => DELAY2
		)
	port map    
		(
			clk       => clk,
		   reset     => dataDissReset,
		   dataIn    => dataDissIn,
			dataValid => dataDissValid,
			dataRead  => dataDissRead,
			ready     => dataDissReady,
			dataOut   => dataDissOut,
		   done      => dataDissDone
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
	
	with globalReset select
	ttReset <= ttReset when '0',
						'1' when others;
	
	with globalReset select
	dataAssReset <= dataAssReset when '0',
						'1' when others;	
						
	with globalReset select
	dataDissReset <= dataDissReset when '0',
						'1' when others;	
						
						
--Loopback setup
--	transChar <= recChar;

--	transStart <= recValid;
						
--Buffer test code block

	preBufDataIn <= recChar;
	inputBufDataIn <= preBufDataOut;
	preBufInValid <= recValid;
	inputBufReady <= preBufValid;
	transChar <= inputBufDataOut;
	inputBufRead <= transDone;
					  
	ReadMonitor: process(clk)
	variable state : integer range 0 to 3;
	begin
		if rising_edge(clk) then
			if state = 0 and recChar = "00100100" and recValid = '1' and inputBufEntries /= 0 then
				transStart <= '1';
				state := 1;
			elsif state = 1 then
				transStart <= '0';
				if transDone = '1' then
					state := 2;
				end if;
			elsif state = 2 then
				if inputBufEntries /= 0 then
					transStart <= '1';
					state := 1;
				else
					state := 0;
				end if;
			end if;
		end if;
	end process;
	

end Behavioral;