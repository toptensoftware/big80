library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	LEDs : out std_logic_vector(7 downto 0);
	CLK_100MHz : in std_logic

);
end top;

architecture Behavioral of top is

	-- Register to hold the current pattern displayed on the LED strip
	signal s_LEDs : std_logic_vector(7 downto 0) := "00000001";

	-- Counter to divide the 100Mhz clock. Each time this wraps around
	-- the LED pattern is rotated by one position.
	-- This is a 23-bit counter so it will wrap every 2^23 (ie: 8388608)
	-- clock ticks, or approximately every 83 milliseconds.
	signal s_divide : unsigned(22 downto 0) := (others => '0');

begin

	-- Connect the LED register to the LEDs
	LEDS <= s_LEDs;

	-- Process to handle clock ticks
	process (CLK_100MHz)
	begin

		-- Is this clock on a rising edge
		if rising_edge(CLK_100MHz) then

			-- Increment the divide counter
			s_divide <= s_divide + 1;

			-- If the divide counter wrapped then rotate the LED pattern
			if s_divide = 0 then
				s_LEDs <= s_LEDs(6 downto 0) & s_LEDs(7);
			end if;

		end if;
	end process;

end Behavioral;

