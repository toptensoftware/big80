library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '1';
    signal s_reset : std_logic := '0';
    signal s_horz_pos : integer range -2048 to 2047;
    signal s_vert_pos : integer range -2048 to 2047;
    signal s_video_ram_addr : std_logic_vector(9 downto 0);
    signal s_video_ram_data : std_logic_vector(7 downto 0);
    signal s_char_rom_addr :  std_logic_vector(10 downto 0);
    signal s_char_rom_data :  std_logic_vector(5 downto 0);
    signal s_pixel : std_logic;
begin

    reset_proc: process
    begin
        s_reset <= '1';
        wait for 2 us;
        s_reset <= '0';
        wait;
    end process;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 us;
    end process;


    vgaTiming : entity work.VGATiming
    generic map
    (
        p_horz_res => 6 * 2 * 4,            -- 4 characters wide
        p_vert_res => 12 * 3 * 2,           -- 2 lines high
        p_pixel_latency => 0,
        p_horz_front_porch => 5,
        p_horz_sync_width => 5,
        p_horz_back_porch => 5,
        p_vert_front_porch => 5,
        p_vert_sync_width => 5,
        p_vert_back_porch => 5
    )
	port map
	(
        i_clock => s_Clock,
        i_clken => '1',
        i_reset => s_Reset,
        o_horz_sync => open,
        o_vert_sync => open,
        o_horz_pos => s_horz_pos,
        o_vert_pos => s_vert_pos,
        o_blank => open
    );
    
    -- Fake Video RAM
    video_ram_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_video_ram_data <= x"FF";
            else
                s_video_ram_data <= "000000" & s_video_ram_addr(1 downto 0);
            end if;
        end if;
    end process;

    -- Fake Character ROM
    char_rom_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_char_rom_data <= "111111";
            else
                case s_char_rom_addr(5 downto 4) is
                    when "00" => s_char_rom_data <= "101010";
                    when "01" => s_char_rom_data <= "000000";
                    when "10" => s_char_rom_data <= "010101";
                    when "11" => s_char_rom_data <= "000000";
                    when others => s_char_rom_data <= "111111";
                end case;
            end if;
        end if;
    end process;

    -- Video Controller (UUT)
    videoController : entity work.Trs80VideoController
    generic map
    (
        p_left_margin_pixels => 0,
        p_top_margin_pixels => 0
    )
    port map
    (
        i_clock => s_Clock,
        i_clken => '1',
        i_reset => s_Reset,
        i_horz_pos => s_horz_pos,
        i_vert_pos => s_vert_pos,
        i_wide_mode => '0',
        o_video_ram_addr => s_video_ram_addr,
        i_video_ram_data => s_video_ram_data,
        o_char_rom_addr => s_char_rom_addr,
        i_char_rom_data => s_char_rom_data,
        o_pixel => s_pixel
    );
end;