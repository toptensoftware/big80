library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	SevenSegment : out std_logic_vector(7 downto 0);
	SevenSegmentEnable : out std_logic_vector(2 downto 0);
	PS2_Clock : inout std_logic;
	PS2_Data : inout std_logic
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_counter : unsigned(11 downto 0);
	signal s_clken_sevenseg : std_logic;
	signal s_scan_code : std_logic_vector(6 downto 0);
	signal s_extended_key : std_logic;
	signal s_key_release : std_logic;
	signal s_key_available : std_logic;
begin

	-- Reset signal
	s_reset <= not Button_B;

	-- Clock divider
	clk_div_seven_seg : entity work.ClockDividerPow2
	GENERIC MAP
	(
		p_DividerWidth_1 => 19
	)
	PORT MAP
	(
		i_Clock => CLK_100Mhz,
		i_Reset => s_reset,
		o_ClockEnable_1 => s_clken_sevenseg
	);

	-- Use an instance of the SevenSegmentHexDisplay component
	display : entity work.SevenSegmentHexDisplay
	PORT MAP 
	(
		i_Clock => CLK_100MHz,
		i_ClockEnable => s_clken_sevenseg,
		i_Reset => s_reset,
		i_Value => std_logic_vector(s_counter),
		o_SevenSegment => SevenSegment(7 downto 1),
		o_SevenSegmentEnable => SevenSegmentEnable
	);

	-- The display component doesn't handle the 'dot', turn it off
	SevenSegment(0) <= '1';

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


	process (CLK_100Mhz, s_reset)
	begin
		if rising_edge(CLK_100MHz) then
			if s_reset = '1' then
				s_counter <= (others => '0');
			else
				if s_key_available = '1' then
					if s_key_release = '0' then
						s_counter(6 downto 0) <= unsigned(s_scan_code);

						if s_extended_key = '1' then
							s_counter(11 downto 7) <= "11111";
						else
							s_counter(11 downto 7) <= "00000";
						end if;
					else
						s_counter <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

