library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Buttons : in std_logic_vector(0 downto 0);
	SevenSegment : out std_logic_vector(7 downto 0);
	SevenSegmentEnable : out std_logic_vector(2 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_counter : unsigned(11 downto 0);
	signal s_clken_sevenseg : std_logic;
	signal s_clken_counter : std_logic;
begin

	-- Reset signal
	s_reset <= not Buttons(0);

	-- Clock divider
	clk_div_seven_seg : entity work.ClockDividerPow2
	GENERIC MAP
	(
		p_DividerWidth_1 => 19,
		p_DividerWidth_2 => 23
	)
	PORT MAP
	(
		i_Clock => CLK_100Mhz,
		i_Reset => s_reset,
		o_ClockEnable_1 => s_clken_sevenseg,
		o_ClockEnable_2 => s_clken_counter
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

	-- Process to increment counter
	process (CLK_100MHz, s_clken_counter, s_reset)
	begin
		if rising_edge(CLK_100MHz) then
			if s_reset = '1' then
				s_counter <= (others => '0');
			elsif s_clken_counter = '1' then
				s_counter <= s_counter + 1;
			end if;
		end if;
	end process;

end Behavioral;

