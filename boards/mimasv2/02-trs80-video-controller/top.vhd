library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	o_horz_sync : out std_logic;
	o_vert_sync : out std_logic;
	o_red : out std_logic_vector(2 downto 0);
	o_green : out std_logic_vector(2 downto 0);
	o_blue : out std_logic_vector(2 downto 1)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_blank : std_logic;
	signal s_hpos : integer range -2048 to 2047;
	signal s_vpos : integer range -2048 to 2047;
	signal s_clock_80mhz : std_logic;
	signal s_clken_40mhz : std_logic;
    signal s_video_ram_addr : std_logic_vector(9 downto 0);
    signal s_video_ram_data : std_logic_vector(7 downto 0);
    signal s_char_rom_addr : std_logic_vector(10 downto 0);
    signal s_char_rom_data : std_logic_vector(5 downto 0);
	signal s_pixel : std_logic;
	signal s_line_rep : integer range 0 to 2;
begin

	-- Reset signal
	s_reset <= not i_button_b;

	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => i_clock_100mhz,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_clock_80mhz
	);

	process (s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				s_clken_40mhz <= '0';
			else
				s_clken_40mhz <= not s_clken_40mhz;
			end if;
		end if;
	end process;

	vga_timing : entity work.VGATiming800x600
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_40mhz,
		i_reset => s_reset,
		o_vert_sync => o_vert_sync,
		o_horz_sync => o_horz_sync,
		o_horz_pos => s_hpos,
		o_vert_pos => s_vpos,
		o_blank => s_blank
	);

	video_controller : entity work.Trs80VideoController
	generic map
	(
		p_left_margin_pixels => 16,
		p_top_margin_pixels => 12
	)
	port map
	(
		i_clock => s_clock_80mhz,
		i_clken => s_clken_40mhz,
		i_reset => s_reset,
		i_horz_pos => s_hpos,
		i_vert_pos => s_vpos,
		i_wide_mode => '1',
		o_vram_addr => s_video_ram_addr,
		i_vram_data => s_video_ram_data,
		o_char_rom_addr => s_char_rom_addr,
		i_char_rom_data => s_char_rom_data,
		o_pixel => s_pixel,
		o_line_rep => s_line_rep
	);

	charrom : entity work.Trs80CharRom
	port map
	(
		i_clock => s_clock_80mhz,
		i_addr => s_char_rom_addr,
		o_dout => s_char_rom_data
	);

	-- Fake Video RAM
	video_ram_proc : process(s_clock_80mhz)
	begin
		if rising_edge(s_clock_80mhz) then
			if s_reset = '1' then
				s_video_ram_data <= x"FF";
			elsif s_clken_40mhz = '1' then
				if s_video_ram_addr(1 downto 0) = "00" then
					s_video_ram_data <= s_video_ram_addr(9 downto 2);
				else
					s_video_ram_data <= x"20";
				end if;
			end if;
		end if;
	end process;
	
	o_red <= "000";
	o_green <= (s_pixel & s_pixel & s_pixel);
	o_blue <= "00";

end Behavioral;

