library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	Button_Right : in std_logic;
	UART_TX : out std_logic;
	LEDs : out std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
begin

	-- Reset signal
	s_reset <= not Button_B;

	uat : entity work.Trs80CassetteStreamerTest
	generic map
	(
		p_ClockFrequency => 100_000_000,
		p_BufferSize => 6
	)
	port map
	( 
		i_Clock => CLK_100MHz,
		i_Reset => s_reset,
		i_RecordButton => Button_Right,
		o_UartTx => UART_TX,
		o_debug => LEDs
	);
		

end Behavioral;

