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
	signal s_pixel : std_logic;
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

	s_pixel <= 
		--'0' when s_blank = '1' else
		'1' when s_hpos = 0 else
		'1' when s_vpos = 0 else
		'1' when s_hpos = 799 else
		'1' when s_vpos = 599 else
		'0';

	o_red <= "000";
	o_green <= s_pixel & s_pixel & s_pixel;
	o_blue <= "00";

end Behavioral;

