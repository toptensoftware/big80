library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	i_button_right : in std_logic;
	o_uart_tx : out std_logic;
	o_leds : out std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
begin

	-- Reset signal
	s_reset <= not i_button_b;

	uat : entity work.Trs80CassetteStreamerTest
	generic map
	(
		p_clock_hz => 100_000_000,
		p_buffer_size => 6
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		i_record_button => i_button_right,
		o_uart_tx => o_uart_tx,
		o_debug => o_leds
	);
		

end Behavioral;

