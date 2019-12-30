library IEEE;
use IEEE.std_logic_1164.ALL;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	LEDs : out std_logic_vector(7 downto 0);
	Switches : in std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
begin

	-- Directly map the switches to the LED strip. Turning
	-- a switch on turns on the corresponding LED in the strip.
	LEDs <= Switches;

end Behavioral;

