library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	i_clock_100mhz : in std_logic;
	i_button_b : in std_logic;
	io_ps2_clock : inout std_logic;
	io_ps2_data : inout std_logic;
	o_leds : out std_logic_vector(7 downto 0);
	i_switches : in std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_scan_code : std_logic_vector(6 downto 0);
	signal s_extended_key : std_logic;
	signal s_key_release : std_logic;
	signal s_key_available : std_logic;
begin

	-- Reset signal
	s_reset <= not i_button_b;

	-- PS2 Keyboard Controller
	keyboardController : entity work.PS2KeyboardController
	GENERIC MAP
	(
		p_clock_hz => 100_000_000 
	)
	PORT MAP
	(
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		io_ps2_clock => io_ps2_clock,
		io_ps2_data => io_ps2_data,
		o_key_scancode => s_scan_code,
		o_key_extended => s_extended_key,
		o_key_released => s_key_release,
		o_key_available => s_key_available
	);

	-- TRS80 Keyboard Switches
	keyboardSwitches : entity work.Trs80KeyMemoryMap
	PORT MAP
	(
		i_clock => i_clock_100mhz,
		i_reset => s_reset,
		i_key_scancode => s_scan_code,
		i_key_extended => s_extended_key,
		i_key_released => s_key_release,
		i_key_available => s_key_available,
		i_typing_mode => '0',
		i_addr => i_switches,
		o_data => o_leds
	);

end Behavioral;

