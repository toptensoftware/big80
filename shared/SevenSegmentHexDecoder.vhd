--------------------------------------------------------------------------
--
-- SevenSegmentHexDecoder
--
-- Maps a 4-bit binary number to the required seven segment
-- display elements to display the value as a hex digit.
--
-- The display elements are indexed as follows:
--
--        (6)
--       #####
--      #     #
-- (1)  #     #  (5)
--      #     #
-- (0)   #####
--      #     #
-- (2)  #     #  (4)
--      #     #
--       #####
--        (3)
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;


entity SevenSegmentHexDecoder is
port 
( 
    -- Input
    i_Nibble : in std_logic_vector(3 downto 0);			-- the 4 bit value to be decoded
    
    -- Output
	o_SevenSegment : out std_logic_vector(6 downto 0)	-- Output - the segments to light to 
														-- show the input value in hex.
														-- nb: active-low
);
end SevenSegmentHexDecoder;

architecture Behavioral of SevenSegmentHexDecoder is
begin

	-- Map binary switch values to hex on the seven segment display
	o_SevenSegment <= 
			"0000001" when i_Nibble = "0000" else		-- 0
			"1001111" when i_Nibble = "0001" else		-- 1
			"0010010" when i_Nibble = "0010" else		-- 2
			"0000110" when i_Nibble = "0011" else		-- 3
			"1001100" when i_Nibble = "0100" else		-- 4
			"0100100" when i_Nibble = "0101" else		-- 5
			"0100000" when i_Nibble = "0110" else		-- 6
			"0001111" when i_Nibble = "0111" else		-- 7
			"0000000" when i_Nibble = "1000" else		-- 8
			"0000100" when i_Nibble = "1001" else		-- 9
			"0001000" when i_Nibble = "1010" else		-- A
			"1100000" when i_Nibble = "1011" else		-- B
			"0110001" when i_Nibble = "1100" else		-- C
			"1000010" when i_Nibble = "1101" else		-- D
			"0110000" when i_Nibble = "1110" else		-- E
			"0111000" when i_Nibble = "1111" else		-- F
			"1011111";										

end Behavioral;

