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
    p_clock_hz : integer
);
port 
( 
    -- Control
    i_clock : in std_logic;                             -- Clock
    i_reset : in std_logic;                             -- Reset (syncrhonous, actvive high)
       
    -- Input
    i_data : in std_logic_vector(11 downto 0);          -- 12 bit value to be displayed
    
    -- Output
    o_segments : out std_logic_vector(6 downto 0);       -- Segements (active low)
    o_segments_en : out std_logic_vector(2 downto 0)     -- Digit enable (active low)
);
end SevenSegmentHexDisplayWithClockDivider;

architecture Behavioral of SevenSegmentHexDisplayWithClockDivider is
    signal s_clock_en : std_logic;
begin

    clock_divider : entity work.ClockDivider
    generic map
    (
        p_period => p_clock_hz / 180
    )
    port map
    (
        i_clock => i_clock,
        i_clken => '1',
        i_reset => i_reset,
        
        -- Output
        o_clken => s_clock_en
    );

    display : entity work.SevenSegmentHexDisplay
    port map
    (
        i_clock => i_clock,
        i_clken => s_clock_en,
        i_reset => i_reset,
        i_data => i_data,
        o_segments => o_segments,
        o_segments_en => o_segments_en
    );

end Behavioral;

