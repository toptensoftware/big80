library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	UART_TX : out std_logic;
	UART2_TX : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_tx : std_logic;
begin

	-- Reset signal
	s_reset <= not Button_B;

	UART_TX <= s_tx;
	UART2_TX <= s_tx;

	test : entity work.UartTxTest
	generic map
	(
		p_ClockFrequency => 100_000_000,
		p_BytesPerChunk => 512,
		p_ChunksPerSecond => 1
	)
	port map
	( 
		i_Clock => CLK_100MHz,
		i_Reset => s_reset,
		o_UartTx => s_tx
	);

end Behavioral;

