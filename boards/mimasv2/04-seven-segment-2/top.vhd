library IEEE;
use IEEE.std_logic_1164.ALL;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	o_seven_segment : out std_logic_vector(7 downto 0);
	o_seven_segment_en : out std_logic_vector(2 downto 0);
	i_switches : in std_logic_vector(3 downto 0)
);
end top;

architecture Behavioral of top is
begin

	-- Map binary switch values to hex on the seven segment display
	o_seven_segment <= 
			"00000011" when i_switches = "0000" else		-- 0
			"10011111" when i_switches = "0001" else		-- 1
			"00100101" when i_switches = "0010" else		-- 2
			"00001101" when i_switches = "0011" else		-- 3
			"10011001" when i_switches = "0100" else		-- 4
			"01001001" when i_switches = "0101" else		-- 5
			"01000001" when i_switches = "0110" else		-- 6
			"00011111" when i_switches = "0111" else		-- 7
			"00000001" when i_switches = "1000" else		-- 8
			"00001001" when i_switches = "1001" else		-- 9
			"00010001" when i_switches = "1010" else		-- A
			"11000001" when i_switches = "1011" else		-- B
			"01100011" when i_switches = "1100" else		-- C
			"10000101" when i_switches = "1101" else		-- D
			"01100001" when i_switches = "1110" else		-- E
			"01110001" when i_switches = "1111" else		-- F
			"10111111";										


	-- Just the right most digit enabled
	o_seven_segment_en <= "110";

end Behavioral;

