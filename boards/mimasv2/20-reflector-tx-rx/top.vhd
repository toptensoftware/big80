library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	i_uart_rx : in std_logic;
	o_uart_tx : out std_logic;
	i_buttons : in std_logic_vector(3 downto 0);
	o_leds : out std_logic_vector(7 downto 0);
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_signals_rx : std_logic_vector(19 downto 0);
	signal s_seven_segment_value : std_logic_vector(11 downto 0);
	signal s_tx : std_logic;
	signal s_counter_pulse : std_logic;
	signal s_signals_tx : std_logic_vector(15 downto 0);
    signal s_counter : std_logic_vector(7 downto 0);
begin

	-- Reset signal
	s_reset <= not i_button_b;



	-- Signals sent to PC.  
	s_signals_tx <= (not i_buttons) & "0000" & s_counter;

	-- Reflector component automatically tracks
	-- changes to its input signals and sends them
	-- via uart to the PC as quickly as possible
    reflector_tx : entity work.ReflectorTx
    generic map
    (
        p_clken_hz => 100_000_000,
        p_baud => 115_200,
        p_bit_width => 16
    )
    port map
    ( 
        i_clock => i_clock_100mhz,
        i_clken => '1',
        i_reset => s_reset,
        o_uart_tx => o_uart_tx,
        i_signals => s_signals_tx
    );



	-- Signals received from PC.
	o_leds <= s_signals_rx(7 downto 0);
	s_seven_segment_value <= s_signals_rx(19 downto 8);

	-- ReflectorRx receives signals from PC
    reflector_rx : entity work.ReflectorRx
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
        o_signals => s_signals_rx
    );



	-- Counter shown in the lower 8-bits
    counter : process(i_clock_100mhz)
    begin
        if rising_edge(i_clock_100mhz) then
            if s_reset = '1' then
                s_counter(7 downto 0) <= (others => '0');
            elsif s_counter_pulse = '1' then
                s_counter(7 downto 0) <= std_logic_vector(unsigned(s_counter) + 1);
            end if;
        end if;
    end process;

	-- Divider to generate a pulse to drive the counter
	counter_pulse : entity work.ClockDivider
	generic map
	(
		p_period => 20_000_000
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_counter_pulse
	);    

	-- Seven segment display driver
	seven_seg : entity work.SevenSegmentHexDisplayWithClockDivider
	generic map
	(
		p_clock_hz => 100_000_000
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		i_data => s_seven_segment_value,
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);
	o_seven_segment(0) <= '1';

end Behavioral;

