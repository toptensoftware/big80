library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	PS2_Clock : inout std_logic;
	PS2_Data : inout std_logic;
	LEDs : out std_logic_vector(7 downto 0);
	Switches : in std_logic_vector(7 downto 0)
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
	s_reset <= not Button_B;

	-- PS2 Keyboard Controller
	keyboardController : entity work.PS2KeyboardController
	GENERIC MAP
	(
		p_ClockFrequency => 100_000_000 
	)
	PORT MAP
	(
		i_Clock => CLK_100MHz,
		i_Reset => s_reset,
		io_PS2Clock => PS2_Clock,
		io_PS2Data => PS2_Data,
		o_ScanCode => s_scan_code,
		o_ExtendedKey => s_extended_key,
		o_KeyRelease => s_key_release,
		o_DataAvailable => s_key_available
	);

	-- TRS80 Keyboard Switches
	keyboardSwitches : entity work.Trs80KeyMemoryMap
	PORT MAP
	(
		i_Clock => CLK_100Mhz,
		i_Reset => s_reset,
		i_ScanCode => s_scan_code,
		i_ExtendedKey => s_extended_key,
		i_KeyRelease => s_key_release,
		i_DataAvailable => s_key_available,
		i_TypingMode => '0',
		i_Addr => Switches,
		o_Data => LEDs
	);

end Behavioral;

