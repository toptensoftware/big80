library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	o_leds : out std_logic_vector(7 downto 0);
	i_clock_100mhz : in std_logic

);
end top;

architecture Behavioral of top is

	-- Register to hold the current pattern displayed on the LED strip
	signal s_leds : std_logic_vector(7 downto 0) := "00000001";

	-- Counter to divide the 100Mhz clock. Each time this wraps around
	-- the LED pattern is rotated by one position.
	-- This is a 23-bit counter so it will wrap every 2^23 (ie: 8388608)
	-- clock ticks, or approximately every 83 milliseconds.
	signal s_divide : unsigned(22 downto 0) := (others => '0');

begin

	-- Connect the LED register to the o_leds
	o_leds <= s_leds;

	-- Process to handle clock ticks
	process (i_clock_100mhz)
	begin

		-- Is this clock on a rising edge
		if rising_edge(i_clock_100mhz) then

			-- Increment the divide counter
			s_divide <= s_divide + 1;

			-- If the divide counter wrapped then rotate the LED pattern
			if s_divide = 0 then
				s_leds <= s_leds(6 downto 0) & s_leds(7);
			end if;

		end if;
	end process;

end Behavioral;

