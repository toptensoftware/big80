library IEEE;
use IEEE.std_logic_1164.ALL;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	SevenSegment : out std_logic_vector(7 downto 0);
	SevenSegmentEnable : out std_logic_vector(2 downto 0);
	Switches : in std_logic_vector(7 downto 0);
	Buttons: in std_logic_vector(2 downto 0)
);
end top;

architecture Behavioral of top is
begin

	-- The switches control which leds in all the seven segment
	-- displays to light up.  Note that the  7-segment display is 
	-- "active low" such that the elements light up on low voltage 
	-- level.  The 'not' inverts the switch values so when they're 
	-- down they're on.
	SevenSegment <= not Switches;

	-- The top three push buttons control which of the seven segement
	-- display digits are active.  The buttons are re-ordered so they're
	-- physically in the same order as the 7-segment digit.
	SevenSegmentEnable <= Buttons(1) & Buttons(2) & Buttons(0);

end Behavioral;

