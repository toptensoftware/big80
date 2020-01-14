library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	i_button_up : in std_logic;
	i_button_down : in std_logic;
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_counter : unsigned(11 downto 0);
	signal s_clken_sevenseg : std_logic;
	signal s_prev_inc : std_logic;
	signal s_prev_dec : std_logic;
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

	-- Process to increment counter
	process (i_clock_100mhz, s_reset)
	begin
		if rising_edge(i_clock_100mhz) then
			if s_reset = '1' then
				s_counter <= (others => '0');
			else
				s_prev_dec <= i_button_down;
				s_prev_inc <= i_button_up;

				if i_button_down = '0' and s_prev_dec = '1' then
					s_counter <= s_counter - 1;
				end if;

				if i_button_up = '0' and s_prev_inc = '1' then
					s_counter <= s_counter + 1;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

