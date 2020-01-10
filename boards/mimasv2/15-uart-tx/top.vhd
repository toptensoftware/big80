library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

entity top is
port 
( 
	-- These signals must match what's in the .ucf file
	CLK_100MHz : in std_logic;
	Button_B : in std_logic;
	UART_TX : out std_logic;
	UART_RX : in std_logic;
	ReflectTx : out std_logic;
	ReflectRx : out std_logic;
	LEDs : out std_logic_vector(7 downto 0)
);
end top;

architecture Behavioral of top is
	signal s_reset : std_logic;
	signal s_data : std_logic_vector(7 downto 0);
	signal s_data_available : std_logic;
	signal s_100ms_enable : std_logic;
	signal s_tx : std_logic;
begin

	-- Reset signal
	s_reset <= not Button_B;

	UART_TX <= s_tx;
	ReflectTx <= s_tx;
	ReflectRx <= UART_RX;

	tx : entity work.UartTx
	generic map
	(
		-- Resolution
		p_ClockFrequency  => 100_000_000
	)
	port map
	( 
		i_Clock => CLK_100MHz,
		i_ClockEnable => '1',
		i_Reset => s_reset,
		i_Data => s_data,
		i_DataAvailable => s_data_available,
		o_UartTx => s_tx,
		o_Busy => open
	);

	LEDs <= s_data;

	div : entity work.ClockDivider
	generic map
	(
		p_DivideCycles => 100_000_000
	)	
	port map
	(
		i_Clock => CLK_100MHz,
		i_ClockEnable => '1',
		i_Reset => s_reset,
		o_ClockEnable => s_100ms_enable
	);

	gen : process(CLK_100MHz)
	begin
		if rising_edge(CLK_100MHz) then
			if s_reset = '1' then
				s_data_available <= '0';
				s_data <= x"00";
			else
				s_data_available <= '0';

				if s_100ms_enable = '1' then
					s_data <= std_logic_vector(unsigned(s_data) + 1);
					s_data_available <= '1';
				end if;
			end if;
		end if;
	end process;

end Behavioral;

