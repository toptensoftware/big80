library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);
	io_ps2_clock : inout std_logic;
	io_ps2_data : inout std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_counter : unsigned(11 downto 0);
	signal s_clken_sevenseg : std_logic;
	signal s_scan_code : std_logic_vector(6 downto 0);
	signal s_extended_key : std_logic;
	signal s_key_release : std_logic;
	signal s_key_available : std_logic;
begin

	-- Reset signal
	s_reset <= not i_button_b;

	-- Clock divider
	clk_div_seven_seg : entity work.ClockDividerPow2
	GENERIC MAP
	(
		p_divider_width_1 => 19
	)
	PORT MAP
	(
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		o_clken_1 => s_clken_sevenseg
	);

	-- Use an instance of the SevenSegmentHexDisplay component
	display : entity work.SevenSegmentHexDisplay
	PORT MAP 
	(
		i_clock => i_clock_100mhz,
		i_clken => s_clken_sevenseg,
		i_reset => s_reset,
		i_data => std_logic_vector(s_counter),
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);

	-- The display component doesn't handle the 'dot', turn it off
	o_seven_segment(0) <= '1';

	keyboardController : entity work.PS2KeyboardController
	GENERIC MAP
	(
		p_clock_hz => 100_000_000 
	)
	PORT MAP
	(
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		io_ps2_clock => io_ps2_clock,
		io_ps2_data => io_ps2_data,
		o_key_scancode => s_scan_code,
		o_key_extended => s_extended_key,
		o_key_released => s_key_release,
		o_key_available => s_key_available
	);


	process (i_clock_100mhz, s_reset)
	begin
		if rising_edge(i_clock_100mhz) then
			if s_reset = '1' then
				s_counter <= (others => '0');
			else
				if s_key_available = '1' then
					if s_key_release = '0' then
						s_counter(6 downto 0) <= unsigned(s_scan_code);

						if s_extended_key = '1' then
							s_counter(11 downto 7) <= "00010";
						else
							s_counter(11 downto 7) <= "00000";
						end if;
					else
						s_counter <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

