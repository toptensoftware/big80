library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	o_uart_tx : out std_logic;
	o_uart2_tx : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_tx : std_logic;
begin

	-- Reset signal
	s_reset <= not i_button_b;

	o_uart_tx <= s_tx;
	o_uart2_tx <= s_tx;

	test : entity work.UartTxTest
	generic map
	(
		p_clock_hz => 100_000_000,
		p_bytes_per_chunk => 512,
		p_chunks_per_second => 1
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		o_uart_tx => s_tx
	);

end Behavioral;

