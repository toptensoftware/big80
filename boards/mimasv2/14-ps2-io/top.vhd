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
	io_ps2_data : inout std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	o_reflect_clock : out std_logic;
	o_reflect_data : out std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_seven_seg_value : std_logic_vector(11 downto 0);
	signal s_clken_sevenseg : std_logic;
	signal s_scan_code : std_logic_vector(6 downto 0);
	signal s_extended_key : std_logic;
	signal s_key_release : std_logic;
	signal s_key_available : std_logic;
	constant c_delay_ticks : integer := 100_000_000;
	signal s_delay_counter : integer range 0 to c_delay_ticks - 1;	-- 1ms
	signal s_ps2_leds : std_logic_vector(2 downto 0);
begin

	-- Reset signal
	s_reset <= not i_button_b;
	o_leds <= "00000000";

	-- When logic analyzer connected to the ps2 clock and data lines
	-- receiving data from the keyboard works, but transmitting fails.
	-- For debugging, reflect these two signals out to the Mimas V2's
	-- P9 connector and attach the logic analyzer there.
	o_reflect_clock <= io_ps2_clock;
	o_reflect_data <= io_ps2_data;

	-- Use an instance of the SevenSegmentHexDisplay component
	display : entity work.SevenSegmentHexDisplayWithClockDivider
	GENERIC MAP
	(
		p_clock_hz => 100_000_000
	)
	PORT MAP 
	(
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		i_data => s_seven_seg_value,
		o_segments => o_seven_segment(7 downto 1),
		o_segments_en => o_seven_segment_en
	);

	-- The display component doesn't handle the 'dot', turn it off
	o_seven_segment(0) <= '1';

	keyLeds : entity work.PS2KeyboardControllerEx
	generic map
	(
		p_clock_hz => 100_000_000
	)
	port map
	(
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		io_ps2_clock => io_ps2_clock,
		io_ps2_data => io_ps2_data,
		i_leds => s_ps2_leds,
		o_key_scancode => s_scan_code,
		o_key_extended => s_extended_key,
		o_key_released => s_key_release,
		o_key_available => s_key_available
	);


	process (i_clock_100mhz)
	begin
		if rising_edge(i_clock_100mhz) then
			if s_reset = '1' then
				s_seven_seg_value <= (others => '0');
			else
				if s_key_available = '1' then
					if s_key_release = '0' then
						s_seven_seg_value(6 downto 0) <= s_scan_code;

						if s_extended_key = '1' then
							s_seven_seg_value(11 downto 7) <= "00010";
						else
							s_seven_seg_value(11 downto 7) <= "00000";
						end if;
					else
						s_seven_seg_value <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;

	process (i_clock_100mhz)	
	begin
		if rising_edge(i_clock_100mhz) then
			if s_reset = '1' then
				s_ps2_leds <= "000";
			elsif s_key_available = '1' and s_key_release = '0' then
				case s_extended_key & s_scan_code is

					when x"7E" => 
						-- scroll lock
						s_ps2_leds(0) <= not s_ps2_leds(0);
					
					when x"77" => 
						-- numlock
						s_ps2_leds(1) <= not s_ps2_leds(1);
						
					when x"58" => 
						-- caps lock
						s_ps2_leds(2) <= not s_ps2_leds(2);

					when others => 
						null;

				end case;
			end if;
		end if;
	end process;

--	process (i_clock_100mhz)	
--	begin
--		if rising_edge(i_clock_100mhz) then
--			if s_reset = '1' then
--				s_ps2_leds <= "100";
--			elsif s_delay_counter = c_delay_ticks - 1 then
--				s_ps2_leds <= s_ps2_leds(0) & s_ps2_leds(2 downto 1);
--			end if;
--		end if;
--	end process;
--
--
--	timer : process(i_clock_100mhz)
--	begin
--		if rising_edge(i_clock_100mhz) then
--			if s_reset = '1' then
--				s_delay_counter <= 0;
--			else
--				if s_delay_counter = c_delay_ticks - 1 then
--					s_delay_counter <= 0;
--				else
--					s_delay_counter <= s_delay_counter + 1;
--				end if;
--			end if;
--		end if;
--	end process;

end Behavioral;

