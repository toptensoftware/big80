--------------------------------------------------------------------------
--
-- Trs80VideoController
--
-- Implements a TRS-80 Model 1 video controller.
--
--  * Produces correct aspect ration by pixel doubling horizontally and
--       tripling vertically.
--  * Video RAM is connected externally
--  * Character ROM is connected externally
--  * VGA timing signals should be provided from a VGATiming component
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity Trs80VideoController is
generic
(
    -- Position of TRS-80 display relative to top left of VGA display
    -- (used to center in larger VGA resolution display modes)
    p_LeftMarginPixels : integer;
    p_TopMarginPixels : integer
);
port 
( 
    -- Control
    i_Clock : in std_logic;                 -- Pixel Clock
    i_ClockEnable : in std_logic;           -- Clock Enable
    i_Reset : in std_logic;                 -- Reset (synchronous, active high)
    
    -- Video Timing
    i_HPos : in integer range -2048 to 2047;
    i_VPos : in integer range -2048 to 2047;

    -- Video RAM Access
    o_VideoRamAddr : out std_logic_vector(9 downto 0);
    i_VideoRamData : in std_logic_vector(7 downto 0);

    -- Character ROM Access
    o_CharRomAddr : out std_logic_vector(11 downto 0);
    i_CharRomData : in std_logic_vector(5 downto 0);

    -- Output
    o_Pixel : out std_logic
);
end Trs80VideoController;

architecture Behavioral of Trs80VideoController is
    signal s_char_rep : integer range 0 to 1;       -- pixel double horizontally
    signal s_char_pix : integer range 0 to 5;       -- pixel within character cell
    signal s_char_num : integer range 0 to 127;     -- character number horizontally
    signal s_line_rep : integer range 0 to 2;       -- pixel triple vertically
    signal s_line_pix : integer range 0 to 11;      -- pixel row within character cell
    signal s_line_num : integer range 0 to 127;     -- line number
begin

    -- Pixel cycle -2
    -- Calculate the video ram address
    o_VideoRamAddr <= 
        std_logic_vector(to_unsigned(s_line_num, 4)) & 
        std_logic_vector(to_unsigned(s_char_num, 6));

    -- Pixel cycle -1
    -- Calculate character rom address
    o_CharRomAddr <= 
        i_VideoRamData & 
        std_logic_vector(to_unsigned(s_line_pix, 4));

    -- Pixel Cycle 0
    -- Select the correct pixel (remember s_char_pix is two pixels ahead)
    o_Pixel <= 
--            '1' when i_HPos = 0 else
--            '1' when i_HPos = 799 else
--            '1' when i_VPos = 0 else
--            '1' when i_VPos = 599 else
            '0' when i_HPos < p_LeftMarginPixels else
            '0' when i_VPos < p_TopMarginPixels else
            '0' when i_HPos >= p_LeftMarginPixels + 768 else
            '0' when i_VPos >= p_TopMarginPixels + 576 else
            i_CharRomData(5) when s_char_pix = 1 else
            i_CharRomData(4) when s_char_pix = 2 else
            i_CharRomData(3) when s_char_pix = 3 else
            i_CharRomData(2) when s_char_pix = 4 else
            i_CharRomData(1) when s_char_pix = 5 else
            i_CharRomData(0) when s_char_pix = 0 else
            '0';


    -- Because the TRS80 character cell is 6 pixels wide and 12 pixels tall
    -- we can't use binary shift operators to easily convert from the pixel
    -- coordinates provided by the VGATiming to character and in-cell pixel
    -- numbers.  Instead we need to use divide  counters to constantly track 
    -- where we're up to
    --
    --  *_rep refers to the pixel repeat count for pixel doubling and row tripling
    --  *_pix refers to the TRS-80 pixel number within the character cell
    --  *_num refers to the TRS-80 character/line number


    -- Horizontal counters
    char_counter : process(i_Clock)
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
                s_char_rep <= 0;
                s_char_pix <= 0;
                s_char_num <= 0;
            elsif i_ClockEnable = '1' then
                if i_HPos = (p_LeftMarginPixels - 3) then
                    s_char_rep <= 0;
                    s_char_pix <= 0;
                    s_char_num <= 0;
                else
                    if s_char_rep = 1 then
                        s_char_rep <= 0;
                        if s_char_pix = 5 then
                            s_char_pix <= 0;
                            s_char_num <= s_char_num + 1;
                        else
                            s_char_pix <= s_char_pix + 1;
                        end if;
                    else
                        s_char_rep <= s_char_rep + 1;
                    end if;
                end if;    
            end if;
        end if;
    end process;

    -- vertical counters
    line_counter: process (i_Clock)
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
                s_line_rep <= 0;
                s_line_pix <= 0;
                s_line_num <= 0;
            elsif i_ClockEnable = '1' then
                if i_HPos = (p_LeftMarginPixels-3) then
                    if i_VPos = p_TopMarginPixels then
                        s_line_rep <= 0;
                        s_line_pix <= 0;
                        s_line_num <= 0;
                    else
                        if s_line_rep = 2 then
                            s_line_rep <= 0;
                            if s_line_pix = 11 then
                                s_line_pix <= 0;
                                s_line_num <= s_line_num + 1;
                            else
                                s_line_pix <= s_line_pix + 1;
                            end if;
                        else
                            s_line_rep <= s_line_rep + 1;
                        end if;
                        end if;    
                    end if;    
                end if;
        end if;
    end process;

end Behavioral;

