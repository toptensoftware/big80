--------------------------------------------------------------------------
--
-- VGATiming800x600
--
-- Wrapper around VGATiming with parameters set for 800x600 @ 60Hz
-- Clock/ClockEnable must provide a 40Mhz clock.
--
-- Timing figures from http://tinyvga.com/vga-timing/800x600@60Hz
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity VGATiming800x600 is
port 
( 
    -- Control
    i_clock : in std_logic;                         -- Clock 
    i_clken : in std_logic;                         -- Clock enable (must be 40MHz)
    i_reset : in std_logic;                         -- Reset (synchronous, active high)
    
    -- Outputs
    o_horz_sync : out std_logic;                    -- Horizontal Sync Pulse
    o_vert_sync : out std_logic;                    -- Vertical Sync Pulse
    o_horz_pos : out integer range -2048 to 2047;   -- Current horizontal position (X Coord)
    o_vert_pos : out integer range -2048 to 2047;   -- Current vertical position
    o_blank : out std_logic                         -- '1' if currently in blanking area
);
end VGATiming800x600;

architecture Behavioral of VGATiming800x600 is
begin

    vgaTiming : entity work.VGATiming
    generic map
    (
        p_horz_res => 800,
        p_vert_res => 600,
        p_horz_front_porch => 40,
        p_horz_sync_width => 128,
        p_horz_back_porch => 88,
        p_vert_front_porch => 1,
        p_vert_sync_width => 4,
        p_vert_back_porch => 23
    )
	port map
	(
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        o_horz_sync => o_horz_sync,
        o_vert_sync => o_vert_sync,
        o_horz_pos => o_horz_pos,
        o_vert_pos => o_vert_pos,
        o_blank => o_blank
	);

end Behavioral;

