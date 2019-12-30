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
    i_Clock : in std_logic;                 -- Clock 
    i_ClockEnable : in std_logic;           -- Clock enable (must be 40MHz)
    i_Reset : in std_logic;                 -- Reset (synchronous, active high)
    
    -- Outputs
    o_HSync : out std_logic;                -- Horizontal Sync Pulse
    o_VSync : out std_logic;                -- Vertical Sync Pulse
    o_HPos : out integer range -2048 to 2047;   -- Current horizontal position (X Coord)
    o_VPos : out integer range -2048 to 2047;    -- Current vertical position
    o_Blank : out std_logic                 -- Currently in blanking area?
);
end VGATiming800x600;

architecture Behavioral of VGATiming800x600 is
begin

    vgaTiming : entity work.VGATiming
    generic map
    (
        p_HRes => 800,
        p_VRes => 600,
        p_HFrontPorch => 40,
        p_HSyncWidth => 128,
        p_HBackPorch => 88,
        p_VFrontPorch => 1,
        p_VSyncWidth => 4,
        p_VBackPorch => 23
    )
	port map
	(
        i_Clock => i_Clock,
        i_ClockEnable => i_ClockEnable,
        i_Reset => i_Reset,
        o_HSync => o_HSync,
        o_VSync => o_VSync,
        o_HPos => o_HPos,
        o_VPos => o_VPos,
        o_Blank => o_Blank
	);

end Behavioral;

