library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	SevenSegment : out std_logic_vector(7 downto 0);
	SevenSegmentEnable : out std_logic_vector(2 downto 0);
	PS2_Clock : inout std_logic;
	PS2_Data : inout std_logic;
	LEDs : out std_logic_vector(7 downto 0);
	ReflectClock : out std_logic;
	ReflectData : out std_logic
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
	s_reset <= not Button_B;
	LEDs <= "00000000";

	-- When logic analyzer connected to the ps2 clock and data lines
	-- receiving data from the keyboard works, but transmitting fails.
	-- For debugging, reflect these two signals out to the Mimas V2's
	-- P9 connector and attach the logic analyzer there.
	ReflectClock <= PS2_Clock;
	ReflectData <= PS2_Data;

	-- Use an instance of the SevenSegmentHexDisplay component
	display : entity work.SevenSegmentHexDisplayWithClockDivider
	GENERIC MAP
	(
		p_ClockFrequency => 100_000_000
	)
	PORT MAP 
	(
		i_Clock => CLK_100MHz,
		i_Reset => s_reset,
		i_Value => s_seven_seg_value,
		o_SevenSegment => SevenSegment(7 downto 1),
		o_SevenSegmentEnable => SevenSegmentEnable
	);

	-- The display component doesn't handle the 'dot', turn it off
	SevenSegment(0) <= '1';

	keyLeds : entity work.PS2KeyboardControllerEx
	generic map
	(
		p_ClockFrequency => 100_000_000
	)
	port map
	(
		i_Clock => CLK_100Mhz,
		i_Reset => s_reset,
		io_PS2Clock => PS2_Clock,
		io_PS2Data => PS2_Data,
		i_LEDs => s_ps2_leds,
		o_ScanCode => s_scan_code,
		o_ExtendedKey => s_extended_key,
		o_KeyRelease => s_key_release,
		o_DataAvailable => s_key_available
	);


	process (CLK_100Mhz)
	begin
		if rising_edge(CLK_100MHz) then
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

	process (CLK_100Mhz)	
	begin
		if rising_edge(CLK_100Mhz) then
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

--	process (CLK_100Mhz)	
--	begin
--		if rising_edge(CLK_100Mhz) then
--			if s_reset = '1' then
--				s_ps2_leds <= "100";
--			elsif s_delay_counter = c_delay_ticks - 1 then
--				s_ps2_leds <= s_ps2_leds(0) & s_ps2_leds(2 downto 1);
--			end if;
--		end if;
--	end process;
--
--
--	timer : process(CLK_100Mhz)
--	begin
--		if rising_edge(CLK_100Mhz) then
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

