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
	signal s_key_switches : std_logic_vector(63 downto 0);
	signal s_bank_0 : std_logic_vector(7 downto 0);
	signal s_bank_1 : std_logic_vector(7 downto 0);
	signal s_bank_2 : std_logic_vector(7 downto 0);
	signal s_bank_3 : std_logic_vector(7 downto 0);
	signal s_bank_4 : std_logic_vector(7 downto 0);
	signal s_bank_5 : std_logic_vector(7 downto 0);
	signal s_bank_6 : std_logic_vector(7 downto 0);
	signal s_bank_7 : std_logic_vector(7 downto 0);
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
	keyboardSwitches : entity work.Trs80KeySwitches
	PORT MAP
	(
		i_Clock => CLK_100Mhz,
		i_Reset => s_reset,
		i_ScanCode => s_scan_code,
		i_ExtendedKey => s_extended_key,
		i_KeyRelease => s_key_release,
		i_DataAvailable => s_key_available,
		o_KeySwitches => s_key_switches
	);

	s_bank_0 <= s_key_switches(7 downto 0) when Switches(0)='1' else x"00";
	s_bank_1 <= s_key_switches(15 downto 8) when Switches(1)='1' else x"00";
	s_bank_2 <= s_key_switches(23 downto 16) when Switches(2)='1' else x"00";
	s_bank_3 <= s_key_switches(31 downto 24) when Switches(3)='1' else x"00";
	s_bank_4 <= s_key_switches(39 downto 32) when Switches(4)='1' else x"00";
	s_bank_5 <= s_key_switches(47 downto 40) when Switches(5)='1' else x"00";
	s_bank_6 <= s_key_switches(55 downto 48) when Switches(6)='1' else x"00";
	s_bank_7 <= s_key_switches(63 downto 56) when Switches(7)='1' else x"00";

	LEDs <= s_bank_0 or s_bank_1 or s_bank_2 or s_bank_3 or
			s_bank_4 or s_bank_5 or s_bank_6 or s_bank_7;


end Behavioral;

