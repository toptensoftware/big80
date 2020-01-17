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
	i_buttons : in std_logic_vector(3 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_tx : std_logic;
	signal s_counter_pulse : std_logic;
	signal s_signals : std_logic_vector(15 downto 0);
    signal s_counter : std_logic_vector(7 downto 0);
begin

	-- Reset signal
	s_reset <= not i_button_b;

	-- Reflector component automatically tracks
	-- changes to its input signals and sends them
	-- via uart to the PC
    reflector : entity work.ReflectorTx
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
        i_signals => s_signals
    );

	-- Signals to be sent to PC.  
	--   Top 4 bits = button states
	--   Bottom 8 bits = 1 second counter
	s_signals <= (not i_buttons) & "0000" & s_counter;

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
		p_period => 100_000_000
	)
	port map
	( 
		i_clock => i_clock_100mhz,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_counter_pulse
	);    

end Behavioral;

