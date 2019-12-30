--------------------------------------------------------------------------
--
-- VGATiming
--
-- Generates VGA timing signals for given resolution and sync pulse 
-- timings.
--
-- Note, when outside the display area (ie: with o_Block = '1') the
-- current horizontal and vertical positions will be negative values
--
-- ie: on the pixel clock before entering the horizontal display area
--     o_HPos will be -1.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity VGATiming is
generic
(
    -- Resolution
    p_HRes : integer;
    p_VRes : integer;

    -- Timing
    p_HFrontPorch : integer;
    p_HSyncWidth : integer;
    p_HBackPorch : integer;
    p_VFrontPorch : integer;
    p_VSyncWidth : integer;
    p_VBackPorch : integer;

    -- This will be added the o_HPos output.  Set this to the number
    -- of clock cycles your video controller needs to work out the
    -- color of the pixel.
    p_PixelLatency : integer := 0
);
port 
( 
    -- Control
    i_Clock : in std_logic;                     -- Clock
    i_ClockEnable : in std_logic;               -- Clock Enable
    i_Reset : in std_logic;                     -- Reset (synchronous, active high)
    
    -- Outputs
    o_HSync : out std_logic;                    -- Horizontal Sync Pulse
    o_VSync : out std_logic;                    -- Vertical Sync Pulse
    o_HPos : out integer range -2048 to 2047;   -- Current horizontal position
    o_VPos : out integer range -2048 to 2047;   -- Current vertical position
    o_Blank : out std_logic                     -- Currently in blanking area?
);
end VGATiming;

architecture Behavioral of VGATiming is
    constant p_HBlank : integer := (p_HFrontPorch + p_HSyncWidth + p_HBackPorch);
    constant p_HMax : integer := (p_HRes - 1);
    constant p_HSyncStart : integer := (p_HFrontPorch - p_HBlank);
    constant p_HSyncEnd : integer := (p_HFrontPorch + p_HSyncWidth - p_HBlank);

    constant p_VBlank : integer := (p_VFrontPorch + p_VSyncWidth + p_VBackPorch);
    constant p_VMax : integer := (p_VRes - 1);
    constant p_VSyncStart : integer := (p_VFrontPorch - p_VBlank);
    constant p_VSyncEnd : integer := (p_VFrontPorch + p_VSyncWidth - p_VBlank);

    signal s_HPos : integer range -2048 to 2047 := 0;
    signal s_VPos : integer range -2048 to 2047 := 0;
begin

    -- Output positions
    o_HPos <= s_HPos + p_PixelLatency;
    o_VPos <= s_VPos;
    o_HSync <= '1' when s_HPos >= p_HSyncStart and s_HPos < p_HSyncEnd else '0';
    o_VSync <= '1' when s_VPos >= p_VSyncStart and s_VPos < p_VSyncEnd else '0';

    -- In blanking area (ie: not in display area)
    o_Blank <= '0' when (s_HPos >= 0 and s_VPos >= 0) else '1';

    -- Horizontal counter
	process (i_Clock)
	begin
		if rising_edge(i_Clock) then
            if i_reset='1' then
                s_HPos <= -p_HBlank;
            elsif i_ClockEnable = '1' then 
                if s_HPos = p_HMax then
                    s_HPos <= -p_HBlank;
                else
                    s_HPos <= s_HPos + 1;
                end if;
            end if;
        end if;
	end process;

    -- Vertical counter
	process (i_Clock)
	begin
		if rising_edge(i_Clock) then
            if i_reset='1' then
                s_VPos <= -p_VBlank;
            elsif i_ClockEnable = '1' then
                if s_HPos = p_HMax then
                    if s_VPos = p_VMax then
                        s_VPos <= -p_VBlank;
                    else
                        s_VPos <= s_VPos + 1;
                    end if;
                end if;
            end if;
        end if;
	end process;

end Behavioral;

