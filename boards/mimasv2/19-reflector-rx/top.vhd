library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	i_uart_rx : in std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_signals : std_logic_vector(19 downto 0);
begin

	-- Reset signal
	s_reset <= not i_button_b;

	o_leds <= s_signals(7 downto 0);

	-- Reflector component automatically tracks
	-- changes to its input signals and sends them
	-- via uart to the PC as quickly as possible
    reflector : entity work.ReflectorRx
    generic map
    (
        p_clock_hz => 100_000_000,
        p_baud => 115_200,
        p_bit_width => 20
    )
    port map
    ( 
        i_clock => i_clock_100mhz,
        i_reset => s_reset,
        i_uart_rx => i_uart_rx,
        o_signals => s_signals
    );

	seven_seg : entity work.SevenSegmentHexDisplayWithClockDivider
	generic map
	(
		p_clock_hz => 100_000_000
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		i_data => s_signals(19 downto 8),
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);
	o_seven_segment(0) <= '1';


end Behavioral;

