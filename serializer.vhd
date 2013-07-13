library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serializer is
	generic
	(
		INPUTSIZE  : integer := 16; --input into the module, in bits
		OUTPUTSIZE : integer := 4 --output from the module, in bits
	);
	port
	(
		clk : in std_logic;
		reset : in std_logic;
		dataIn : in unsigned(INPUTSIZE - 1 downto 0);
		dataInValid : in std_logic;
		dataOut : out unsigned(OUTPUTSIZE - 1 downto 0);
		dataOutValid : out std_logic
	);
end serializer;

architecture Behavioral of serializer is

begin
	--Assertions
	assert INPUTSIZE mod OUTPUTSIZE = 0 and OUTPUTSIZE mod INPUTSIZE = 0
		report "INPUTSIZE and OUTPUTSIZE of serializer do not divide nicely, what do?"
		severity ERROR;
		
	process(clk, reset)
		variable data : unsigned(INPUTSIZE - 1 downto 0) := (others => '0');
		variable latched : boolean := false;
		variable i : integer range -1 to INPUTSIZE - 1 := 0;
	begin
		if reset = '1' then
			data := (others => '0');
			i := 0;
			latched := false;
		elsif rising_edge(clk) then
			if latched = false and dataInValid = '1' then
				latched := true;
				data := dataIn;
				i := -1;
			elsif latched then
				i := i + 1;
				dataOut <= data(INPUTSIZE - 1 - i*OUTPUTSIZE downto INPUTSIZE - (i+1)*OUTPUTSIZE);
				dataOutValid <= '1';
				if i = OUTPUTSIZE then
					latched := false;
					i := -1;
				end if;
			end if;
		end if;
	end process;

end Behavioral;