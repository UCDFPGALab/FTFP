-- Steps needed to modify the code to function properly:
-- The input and outputs need to be defined, and the proper constants changed (located in constants.vhd)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--Xilinx components, like IBUF
library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.constants.all;

entity Main is
	port(
		SYSCLK_P : in std_logic;
		SYSCLK_N : in std_logic;
		USB_UART_RX : in std_logic;
		USB_UART_TX : out std_logic
	);
end Main;

architecture Behavioral of Main is

	--********************************************************************************************--
	--****************************************COMPONENTS******************************************--
	--********************************************************************************************--

	component Transmitter is
		generic (
			BAUD       : integer;
			stopBits   : integer range 0 to 2;
			dataBits   : integer range 7 to 8;
			parityBit  : boolean
		);
		port (
			clk      : in std_logic;
			reset    : in std_logic;
			start    : in std_logic;
			dataIn   : in unsigned(7 downto 0);
			txd      : out std_logic;
			done     : out std_logic;
			ready    : out std_logic
		);
	end component;
	
	component Receiver is
	generic (
		BAUD: integer
	);
	port (
		rxd   : in std_logic;
		reset : in std_logic;
		clk   : in std_logic;
		char  : out unsigned(7 downto 0);
		valid : out std_logic := '0'
	);
	end component;
	
	component NBitCircularBuffer is
	generic (
		sizeOfCell : integer;
		sizeOfBuffer   : integer
	);
	port ( 
		clk            : in std_logic;
		reset          : in std_logic;
		inputData      : in unsigned (sizeOfCell - 1 downto 0);
		inputReady     : in std_logic;
		valueRead      : in std_logic;
		entries        : out integer range 0 to sizeOfBuffer;
		outputData     : out unsigned (sizeOfCell - 1 downto 0)
	);
	end component;
	
	component ClockDivider is
	generic ( 
		divider    : integer;
		lengthOfHi : integer
	);
	port (
		clk    : in std_logic;
		reset  : in std_logic;
		enable : in std_logic;
		tick   : out std_logic
	);
	end component;
	
	component dataAssembler is
	generic (
		INPUTBITS   : integer;
		OUTPUTBITS  : integer;
		INPUTDELAY  : integer;
		OUTPUTDELAY : integer
	);
	port (
		clk       : in std_logic;
		reset     : in std_logic;
		dataIn    : in unsigned(inputBits-1 downto 0);
		dataValid : in std_logic;
		idleOut   : out std_logic;
		dataOut   : out unsigned(outputBits-1 downto 0);
		done      : out std_logic
	);
	end component;
	
	component dataDisassembler is
	generic (
		INPUTBITS   : integer;
		OUTPUTBITS  : integer;
		INPUTDELAY  : integer;
		OUTPUTDELAY : integer
	);
	port ( 
		clk       		: in std_logic;
		reset    		: in std_logic;
		dataIn    		: in unsigned(inputBits-1 downto 0);
		dataValid 		: in std_logic;
		dataRead  		: in std_logic;
		idleOut   		: out std_logic;
		dataOut   		: out unsigned(outputBits-1 downto 0);
		dataOutReady	: out std_logic;
		done      		: out std_logic
	);
	end component;
	
	component Pipeline is
	generic (
		SETUP	 	: integer;
		HOLD  	: integer;
		ROWS		: integer;
		COLUMNS 	: integer;
		INTSIZE 	: integer
	);
	port (
		clk			: in std_logic;
		reset 	   : in std_logic;
		dataIn		: in unsigned(SIZEOFCELL-1 downto 0);
		dataInValid	: in std_logic;
		dataOut 		: out unsigned(INTSIZE*ROWS*COLUMNS-1 downto 0);
		valid   		: out std_logic
	);
	end component;
	
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
	signal inputBufDataIn, inputBufDataOut : unsigned(SIZEOFCELL-1 downto 0) := (others => '0');
	signal outputBufDataIn, outputBufDataOut : unsigned(SIZEOFCELL/2-1 downto 0) := (others => '0');
	signal inputBufEntries : integer range 0 to SIZEOFBUFFER := 0;
	signal outputBufEntries : integer range 0 to SIZEOFBUFFER := 0;
	
	--Assembler/Disassembler signals
	signal dataAssReset, dataDissReset, dataAssInValid, dataAssIdle, dataDissIdle, dataAssDone, dataDissValid, dataDissRead, dataDissDone, dataDissDataOutReady : std_logic := '0';
	signal dataAssIn, dataDissOut : unsigned (BROKENBITS - 1 downto 0) := (others => '0');
	signal dataAssOut : unsigned (LUMPBITS - 1 downto 0) := (others => '0');
	signal dataDissIn : unsigned (LUMPBITS/2 - 1 downto 0) := (others => '0');
	
	--Algorithm signals
	signal algreset, algDataInValid, algValid : std_logic := '0';
	signal algDataIn : unsigned (SIZEOFCELL - 1 downto 0) := (others => '0');
	signal algDataOut : unsigned (SIZEOFCELL/2 - 1 downto 0) := (others => '0');

begin

	--Assertions
	assert (SETUP + HOLD + 2) < (DIVIDER * (1 + STOPBITS + DATABITS))
		report "Prebuffer takes too long to setup and hold, will overflow"
		severity ERROR;

	--********************************************************************************************--
	--****************************************PRIMITIVES******************************************--
	--********************************************************************************************--	

	IBUFGDS_inst : IBUFGDS
	generic map (
		IOSTANDARD => "DEFAULT"
	)
	port map (
		O => BUFGsig, -- Clock buffer output
		I => SYSCLK_P, -- Diff_p clock buffer input
		IB => SYSCLK_N -- Diff_n clock buffer input
	);
-- End of IBUFGDS_inst instantiation

	BUFG_inst : BUFG
	port map (
		O => CLK, -- 1-bit Clock buffer output
		I => BUFGsig -- 1-bit Clock buffer input
	);
	
	
	--********************************************************************************************--
	--****************************************PORT MAPS*******************************************--
	--********************************************************************************************--	
	
	Trans: Transmitter
	generic map (
		BAUD       => DIVIDER, --BAUD = clock rate (200MHz) / Baud rate of serial connection
		stopBits   => STOPBITS,
		dataBits   => DATABITS,
		parityBit  => PARITY --does even parity
	)
	port map (
		clk      => CLK,
		reset    => transReset,
		start    => transStart,
		dataIn   => transChar,
		txd      => USB_UART_TX,
		done     => transDone,
		ready    => transReady
	);
	
	Recieve: Receiver
	generic map (
		BAUD => DIVIDER --constant BAUD = clock rate (200MHz) / Baud rate of serial connection
	)
	port map ( 
		rxd   => USB_UART_RX, -- reciever line
		reset => recReset,
		clk   => CLK,
		char  => recChar,
		valid => recValid
	);
	
	inputBUF: NBitCircularBuffer
	generic map (
		sizeOfCell => SIZEOFCELL, -- size of each cell in the buffer
		sizeOfBuffer   => SIZEOFBUFFER -- number of cells in buffer
	)
	port map	(
		clk            => CLK,
		reset          => inputBufReset,
		inputData      => inputBufDataIn,
		inputReady     => inputBufReady, --should only be high for one clock cycle, otherwise store data twice
		valueRead      => inputBufRead, --should be asserted when you've read the current output value
		entries        => inputBufEntries,
		outputData     => inputBufDataOut
	);
		
	outputBUF: NBitCircularBuffer
	generic map (
		sizeOfCell => SIZEOFCELL/2, -- size of each cell in the buffer
		sizeOfBuffer   => SIZEOFBUFFER -- number of cells in buffer
	)
	port map (
		clk            => CLK,
		reset          => outputBufReset,
		inputData      => outputBufDataIn,
		inputReady     => outputBufReady, --should only be high for one clock cycle, otherwise store data twice
		valueRead      => outputBufRead, --should be asserted when you've read the current output value
		entries        => outputBufEntries,
		outputData     => outputBufDataOut
	);
		
	dataAss1: dataAssembler
	generic map	(
		INPUTBITS   => BROKENBITS,
		OUTPUTBITS  => LUMPBITS,  --4x4 1 byte grid
		INPUTDELAY  => DELAY1,
		OUTPUTDELAY => DELAY2
	)
	port map	(
		clk       => clk,
		reset     => dataAssReset,
		dataIn    => dataAssIn,
		dataValid => dataAssInValid,
		idleOut   => dataAssIdle,
		dataOut   => dataAssOut,
		done      => dataAssDone
	);
	
	dataDiss1: dataDisassembler
	generic map (
		INPUTBITS   => LUMPBITS/2,
		OUTPUTBITS  => BROKENBITS,
		INPUTDELAY  => DELAY1,
		OUTPUTDELAY => DELAY2
	)
	port map (
		clk     	  	 => clk,
		reset   		 => dataDissReset,
		dataIn   	 => dataDissIn,
		dataValid	 => dataDissValid,
		dataRead  	 => dataDissRead,
		dataOut  	 => dataDissOut,
		dataOutReady => dataDissDataOutReady,
		idleOut      => dataDissIdle,
	   done      	 => dataDissDone
	);
		
	Alg: Pipeline
	generic map (
		SETUP => 1, --time after the "start" pulse that the pipeline waits to start operating
		HOLD  => 1, --time after the pipeline is done that it waits to send the "done" pulse
		ROWS => 4, -- size in ints
		COLUMNS => 4,
		INTSIZE => INTSIZE -- size of the int in bits, 4 for the 3 digit HEX example
	)
	port map (
		clk     		=> clk,
	   reset    	=> algReset,
	   dataIn   	=> algDataIn,
		dataInValid => algDataInValid,
		dataOut  	=> algDataOut,
		valid    	=> algValid
	);
	
	--********************************************************************************************--
	--****************************************CODE************************************************--
	--********************************************************************************************--
	
	--Muxes for resets, although apparently asynch resets are bad design practice sometimes
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
	
	with globalReset select
	algReset <= transReset when '0',
					'1' when others;
					
	--FLOW DIAGRAM
	--
   --			     +--------+        +---------+         +------------+
   --	From comp->|RECIEVER+------->+ASSEMBLER+-------->+INPUT BUFFER+--+
   -- 			  +--------+        +---------+         +------------+  |
   --          	  	                                                  |
   --  +---------------------------------------------------------------+
   --  |
   --  |  +--------+     +-------------+    +------------+      +-----------+
   --  +->+PIPELINE+---->+OUTPUT BUFFER+--->+DISASSEMBLER+------+TRANSMITTER|---> TO COMPUTER
   --     +--------+     +-------------+    +------------+      +-----------+
	
	--All resets 0 to get rid of warning messages for now, write init procedure later
	globalReset <= '0';
	
	--reciever to assembler connection
	dataAssIn <= recChar;
	dataAssInValid <= recValid;
	
	--Straight through connection, no prebuffer
	inputBufDataIn <= dataAssOut;
	inputBufReady <= dataAssDone;
	
	--Input buffer to pipeline connection
	--Modified to push into the algorithm module right away
	algDataIn <= inputBufDataOut;
	
		BuffAlg: process(clk)
		variable state : integer range 0 to 3 := 0;
		begin
			if rising_edge(clk) then
				inputBufRead <= '0';
				algDataInValid <= '0';
				if inputBufEntries = SIZEOFBUFFER and state = 0 then
					inputBufRead <= '1';
					algDataInValid <= '1';
					state := 1;
				elsif state = 1 then
					algDataInValid <= '1';
					inputBufRead <= '1';
					if inputBufEntries = 1 then
						state := 0;
						algDataInValid <= '0';
						inputBufRead <= '0';
					end if;
				end if;
			end if;
		end process;
	
	--Pipeline to output buffer connection connection
	outputBufDataIn <= algDataOut;
	outputBufReady <= algValid;
	
	--Output buffer to disassembler connection
	
	dataDissIn <= outputBufDataOut;
	
	BuffDiss: process(clk)
	variable state : integer range 0 to 3 := 0;
	begin
		if rising_edge(clk) then
			outputBufRead <= '0';
			dataDissValid <= '0';
			if outputBufEntries = SIZEOFBUFFER and state = 0 then --buffer is full, start outputting all this stuff onto the computer
				outputBufRead <= '1';
				dataDissValid <= '1';
				state := 1;
			elsif state = 1 then
				state := 2;
			elsif state = 2 then
				if outputBufEntries /= 0 and dataDissIdle = '1' then
					state := 3;
				elsif outputBufEntries = 0 then
					state := 0;
				end if;
			elsif state = 3 then
				outputBufRead <= '1';
				dataDissValid <= '1';
				state := 1;
			end if;
		end if;
	end process;
	
	-- Disassembler to transmitter connection
	
	transChar <= dataDissOut;
	
	DissTrans: process(clk)
	variable state : integer range 0 to 2 := 0;
	begin
		if rising_edge(clk) then
			transStart <= '0';
			dataDissRead <= '0';
			if dataDissDataOutReady = '1' and state = 0 then
				transStart <= '1';
				dataDissRead <= '1';
				state := 1;
			elsif state = 1 then
				state := 2;
			elsif state = 2 then
				if transDone = '1' then
					state := 0;
				end if;
			end if;
		end if;
	end process;
	
end Behavioral;