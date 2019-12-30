library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	HSync : out std_logic;
	VSync : out std_logic;
	Red : out std_logic_vector(2 downto 0);
	Green : out std_logic_vector(2 downto 0);
	Blue : out std_logic_vector(2 downto 1)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_blank : std_logic;
	signal s_hpos : integer range -2048 to 2047;
	signal s_vpos : integer range -2048 to 2047;
	signal s_CLK_80MHz : std_logic;
	signal s_CLK_40Mhz_en : std_logic;
	signal s_pixel : std_logic;
begin

	-- Reset signal
	s_reset <= not Button_B;

	dcm : entity work.ClockDCM
	port map
	(
		CLK_IN_100MHz => CLK_100MHz,
		CLK_OUT_100MHz => open,
		CLK_OUT_80MHz => s_CLK_80Mhz
	);

	process (s_CLK_80Mhz)
	begin
		if rising_edge(s_CLK_80Mhz) then
			if s_reset = '1' then
				s_CLK_40Mhz_en <= '0';
			else
				s_CLK_40Mhz_en <= not s_CLK_40Mhz_en;
			end if;
		end if;
	end process;

	vga_timing : entity work.VGATiming800x600
	port map
	(
		i_Clock => s_CLK_80MHz,
		i_ClockEnable => s_CLK_40Mhz_en,
		i_Reset => s_reset,
		o_VSync => VSync,
		o_HSync => HSync,
		o_HPos => s_hpos,
		o_VPos => s_vpos,
		o_Blank => s_blank
	);

	s_pixel <= 
		--'0' when s_blank = '1' else
		'1' when s_hpos = 0 else
		'1' when s_vpos = 0 else
		'1' when s_hpos = 799 else
		'1' when s_vpos = 599 else
		'0';

	Red <= "000";
	Green <= s_pixel & s_pixel & s_pixel;
	Blue <= "00";

end Behavioral;

