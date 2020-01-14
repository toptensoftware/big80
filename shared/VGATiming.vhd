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
--     o_horz_pos will be -1.
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
    p_horz_res : integer;
    p_vert_res : integer;

    -- Timing
    p_horz_front_porch : integer;
    p_horz_sync_width : integer;
    p_horz_back_porch : integer;
    p_vert_front_porch : integer;
    p_vert_sync_width : integer;
    p_vert_back_porch : integer;

    -- This will be added the o_horz_pos output.  Set this to the number
    -- of clock cycles your video controller needs to work out the
    -- color of the pixel.
    p_pixel_latency : integer := 0
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_clken : in std_logic;               -- Clock Enable
    i_reset : in std_logic;                     -- Reset (synchronous, active high)
    
    -- Outputs
    o_horz_sync : out std_logic;                    -- Horizontal Sync Pulse
    o_vert_sync : out std_logic;                    -- Vertical Sync Pulse
    o_horz_pos : out integer range -2048 to 2047;   -- Current horizontal position
    o_vert_pos : out integer range -2048 to 2047;   -- Current vertical position
    o_blank : out std_logic                     -- Currently in blanking area?
);
end VGATiming;

architecture Behavioral of VGATiming is
    constant p_horz_blank : integer := (p_horz_front_porch + p_horz_sync_width + p_horz_back_porch);
    constant p_horz_max : integer := (p_horz_res - 1);
    constant p_horz_sync_start : integer := (p_horz_front_porch - p_horz_blank);
    constant p_horz_sync_end : integer := (p_horz_front_porch + p_horz_sync_width - p_horz_blank);

    constant p_vert_blank : integer := (p_vert_front_porch + p_vert_sync_width + p_vert_back_porch);
    constant p_vert_max : integer := (p_vert_res - 1);
    constant p_vert_sync_start : integer := (p_vert_front_porch - p_vert_blank);
    constant p_vert_sync_end : integer := (p_vert_front_porch + p_vert_sync_width - p_vert_blank);

    signal s_horz_pos : integer range -2048 to 2047 := 0;
    signal s_vert_pos : integer range -2048 to 2047 := 0;
begin

    -- Output positions
    o_horz_pos <= s_horz_pos + p_pixel_latency;
    o_vert_pos <= s_vert_pos;
    o_horz_sync <= '1' when s_horz_pos >= p_horz_sync_start and s_horz_pos < p_horz_sync_end else '0';
    o_vert_sync <= '1' when s_vert_pos >= p_vert_sync_start and s_vert_pos < p_vert_sync_end else '0';

    -- In blanking area (ie: not in display area)
    o_blank <= '0' when (s_horz_pos >= 0 and s_vert_pos >= 0) else '1';

    -- Horizontal counter
	process (i_clock)
	begin
		if rising_edge(i_clock) then
            if i_reset='1' then
                s_horz_pos <= -p_horz_blank;
            elsif i_clken = '1' then 
                if s_horz_pos = p_horz_max then
                    s_horz_pos <= -p_horz_blank;
                else
                    s_horz_pos <= s_horz_pos + 1;
                end if;
            end if;
        end if;
	end process;

    -- Vertical counter
	process (i_clock)
	begin
		if rising_edge(i_clock) then
            if i_reset='1' then
                s_vert_pos <= -p_vert_blank;
            elsif i_clken = '1' then
                if s_horz_pos = p_horz_max then
                    if s_vert_pos = p_vert_max then
                        s_vert_pos <= -p_vert_blank;
                    else
                        s_vert_pos <= s_vert_pos + 1;
                    end if;
                end if;
            end if;
        end if;
	end process;

end Behavioral;

