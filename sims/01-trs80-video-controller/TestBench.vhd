library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '1';
    signal s_clken : std_logic;
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


	e_clken_divider : entity work.ClockDivider
	generic map
	(
		p_period => 2
	)
	port map
	(
		i_clock => s_clock,
		i_clken => '1',
		i_reset => s_reset,
		o_clken => s_clken
	);

    vgaTiming : entity work.VGATiming
    generic map
    (
        p_horz_res => 6 * 2 * 64,
        p_vert_res => 12 * 3 * 16,
        p_pixel_latency => 0,
        p_horz_front_porch => 2,
        p_horz_sync_width => 2,
        p_horz_back_porch => 2,
        p_vert_front_porch => 2,
        p_vert_sync_width => 2,
        p_vert_back_porch => 2
    )
	port map
	(
        i_clock => s_Clock,
        i_clken => s_clken,
        i_reset => s_Reset,
        o_horz_sync => open,
        o_vert_sync => open,
        o_horz_pos => s_horz_pos,
        o_vert_pos => s_vert_pos,
        o_blank => open
    );
    
	vram : entity work.VRam
	port map
	(
		i_clock => s_clock,
        i_clken => s_clken,
		i_addr => s_video_ram_addr,
		o_dout => s_video_ram_data
	);


	charrom : entity work.Trs80CharRom
	port map
	(
		i_clock => s_clock,
		i_addr => s_char_rom_addr,
		o_dout => s_char_rom_data
	);


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
        i_clken => s_clken,
        i_reset => s_Reset,
        i_horz_pos => s_horz_pos,
        i_vert_pos => s_vert_pos,
        i_wide_mode => '0',
        o_vram_addr => s_video_ram_addr,
        i_vram_data => s_video_ram_data,
        o_char_rom_addr => s_char_rom_addr,
        i_char_rom_data => s_char_rom_data,
        o_pixel => s_pixel
    );
end;