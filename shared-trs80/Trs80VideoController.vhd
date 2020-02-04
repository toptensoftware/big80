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
    p_left_margin_pixels : integer;
    p_top_margin_pixels : integer
);
port 
( 
    -- Control
    i_clock : in std_logic;                 -- Pixel Clock
    i_clken : in std_logic;                 -- Clock Enable
    i_reset : in std_logic;                 -- Reset (synchronous, active high)
    
    -- Video Timing
    i_horz_pos : in integer range -2048 to 2047;
    i_vert_pos : in integer range -2048 to 2047;

    -- 64/32 column mode
    i_wide_mode : in std_logic;

    -- Video RAM Access
    o_video_ram_addr : out std_logic_vector(9 downto 0);
    i_video_ram_data : in std_logic_vector(7 downto 0);

    -- Character ROM Access
    o_char_rom_addr : out std_logic_vector(10 downto 0);
    i_char_rom_data : in std_logic_vector(5 downto 0);

    -- Output
    o_pixel : out std_logic;
    o_line_rep : out integer range 0 to 2
);
end Trs80VideoController;

architecture Behavioral of Trs80VideoController is
    signal s_char_rep : integer range 0 to 1;       -- pixel double horizontally
    signal s_char_pix : integer range 0 to 5;       -- pixel within character cell
    signal s_char_num : integer range 0 to 127;     -- character number horizontally
    signal s_char_num_bits : std_logic_vector(5 downto 0);
    signal s_line_rep : integer range 0 to 2;       -- pixel triple vertically
    signal s_line_pix : integer range 0 to 11;      -- pixel row within character cell
    signal s_line_num : integer range 0 to 127;     -- line number
    signal s_pixel_bits : std_logic_vector(5 downto 0);
    signal s_graphic_bits : std_logic_vector(1 downto 0);
    signal s_use_graphic_bits : std_logic;
    signal s_line_pix_std_logic : std_logic_vector(3 downto 0);
begin

    o_line_rep <= s_line_rep;

    s_char_num_bits <= std_logic_vector(to_unsigned(s_char_num, 6));

    -- Pixel cycle -2
    -- Calculate the video ram address
    o_video_ram_addr <= 
        std_logic_vector(to_unsigned(s_line_num, 4)) & 
        s_char_num_bits(5 downto 1) & (s_char_num_bits(0) and not i_wide_mode);

    -- Pixel cycle -1
    -- Calculate character rom address
    s_line_pix_std_logic <= std_logic_vector(to_unsigned(s_line_pix, 4));
    o_char_rom_addr <= i_video_ram_data(6 downto 0) & s_line_pix_std_logic;

    -- Select pixels from character ROM or graphics generator?
    s_pixel_bits <= i_char_rom_data 
                    when s_use_graphic_bits = '0' else
                    s_graphic_bits(0) & s_graphic_bits(0) & s_graphic_bits(0) & 
                    s_graphic_bits(1) & s_graphic_bits(1) & s_graphic_bits(1);

    -- Generate graphic bits
    graphics_generator : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_use_graphic_bits <= '0';
                s_graphic_bits <= "00";
            elsif i_clken = '1' then

                -- Remember if this character is graphic's character or not
                -- for the next cycle
                s_use_graphic_bits <= i_video_ram_data(7);

                -- Generate graphics characters
                case s_line_pix_std_logic(3 downto 2) is
                    when "00" => s_graphic_bits <= i_video_ram_data(1 downto 0);
                    when "01" => s_graphic_bits <= i_video_ram_data(3 downto 2);
                    when "10" => s_graphic_bits <= i_video_ram_data(5 downto 4);
                    when others => s_graphic_bits <= "00";
                end case;
            end if;
        end if;
    end process;

    -- Pixel Cycle 0
    -- Select the correct pixel (remember s_char_pix is two pixels ahead)
    pixel_gen : process(i_horz_pos, i_vert_pos, s_char_pix, s_pixel_bits, i_wide_mode, s_char_num_bits)
    begin
        if i_horz_pos < p_left_margin_pixels or  i_vert_pos < p_top_margin_pixels or
                    i_horz_pos >= p_left_margin_pixels + 768 or i_vert_pos >= p_top_margin_pixels + 576 then
            o_pixel <= '0';
        elsif i_wide_mode = '0' then
            case s_char_pix is
                when 1 => o_pixel <= s_pixel_bits(5);
                when 2 => o_pixel <= s_pixel_bits(4);
                when 3 => o_pixel <= s_pixel_bits(3);
                when 4 => o_pixel <= s_pixel_bits(2);
                when 5 => o_pixel <= s_pixel_bits(1);
                when others => o_pixel <= s_pixel_bits(0);
            end case;
        elsif s_char_num_bits(0) = '0' then
            case s_char_pix is
                when 0 => o_pixel <= s_pixel_bits(0); 
                when 1|2 => o_pixel <= s_pixel_bits(5);
                when 3|4 => o_pixel <= s_pixel_bits(4);
                when others => o_pixel <= s_pixel_bits(3);
            end case;
        else
            case s_char_pix is
                when 0 => o_pixel <= s_pixel_bits(3);
                when 1|2 => o_pixel <= s_pixel_bits(2);
                when 3|4 => o_pixel <= s_pixel_bits(1);
                when others => o_pixel <= s_pixel_bits(0);
            end case;
        end if;
    end process;


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
    char_counter : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_char_rep <= 0;
                s_char_pix <= 0;
                s_char_num <= 0;
            elsif i_clken = '1' then
                if i_horz_pos = (p_left_margin_pixels - 3) then
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
    line_counter: process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_line_rep <= 0;
                s_line_pix <= 0;
                s_line_num <= 0;
            elsif i_clken = '1' then
                if i_horz_pos = (p_left_margin_pixels-3) then
                    if i_vert_pos = p_top_margin_pixels then
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

