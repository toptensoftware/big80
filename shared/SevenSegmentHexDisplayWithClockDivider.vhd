--------------------------------------------------------------------------
--
-- SevenSegmentHexDisplayWithClockDivider
-- 
-- Drives a 3-digit 7-segment display
-- 
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.numeric_std.all;


entity SevenSegmentHexDisplayWithClockDivider is
generic
(
    p_ClockFrequency : integer
);
port 
( 
    -- Control
    i_Clock : in std_logic;                                     -- Clock
    i_Reset : in std_logic;                                     -- Reset (syncrhonous, actvive high)
       
    -- Input
    i_Value : in std_logic_vector(11 downto 0);                 -- 12 bit value to be displayed
    
    -- Output
    o_SevenSegment : out std_logic_vector(6 downto 0);          -- Segements (active low)
    o_SevenSegmentEnable : out std_logic_vector(2 downto 0)     -- Digit enable (active low)
);
end SevenSegmentHexDisplayWithClockDivider;

architecture Behavioral of SevenSegmentHexDisplayWithClockDivider is
    signal s_clock_en : std_logic;
begin

    clock_divider : entity work.ClockDivider
    generic map
    (
        p_DivideCycles => p_ClockFrequency / 180
    )
    port map
    (
        i_Clock => i_Clock,
        i_ClockEnable => '1',
        i_Reset => i_Reset,
        
        -- Output
        o_ClockEnable => s_clock_en
    );

    display : entity work.SevenSegmentHexDisplay
    port map
    (
        i_Clock => i_Clock,
        i_ClockEnable => s_clock_en,
        i_Reset => i_Reset,
        i_Value => i_Value,
        o_SevenSegment => o_SevenSegment,
        o_SevenSegmentEnable => o_SevenSegmentEnable
    );

end Behavioral;

