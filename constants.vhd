library IEEE;
use IEEE.STD_LOGIC_1164.all;

package constants is

	--********************************************************************************************--
	--****************************************CONSTANT********************************************--
	--********************************************************************************************--
	
	--RS-232 Constants
	constant DIVIDER : integer := 1736;
	constant STOPBITS : integer := 1;
	constant DATABITS : integer := 8;
	constant PARITY : boolean := false; --not implemented yet, keep false
	
	--Buffer constants
	constant SIZEOFCELL : integer := 256; -- size of each cell in the buffer (in bits)
	constant SIZEOFBUFFER : integer := 3; -- number of cells in buffer
	
	--PreBuffer constants
	--Stable configs: SIZEOFCELL/SIZEOFBUFFER/SETUP/HOLD (8/300/15/5)
	constant SETUP : integer := 15; --how many clock cycles to keep the data valid before sending the "store" signal
	constant HOLD : integer := 5; --how many clock cycles to keep the data valid after sending the "store" signal
	
	--Disassembler/assembler constants
	constant BROKENBITS   : integer := 8;
	constant	LUMPBITS  : integer := SIZEOFCELL;
	constant DELAY1  : integer := 15;
	constant DELAY2 : integer := 2;
	
	--Algorithm constants
	constant INTSIZE : integer := 8; --size of each int in bytes

end constants;

package body constants is
 
end constants;
