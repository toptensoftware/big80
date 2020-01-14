--------------------------------------------------------------------------
--
-- PS2KeyboardIndicators
--
-- Monitors a LED state signal and generates the appropriate
-- commands for a PS2 keyboard to set the new state when it changes.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity PS2KeyboardIndicators is
port 
( 
    -- Control
    i_clock : in std_logic;                         -- Clock
    i_reset : in std_logic;                         -- Reset (synchronous, active high)

	-- Input
	i_leds : in std_logic_vector(2 downto 0);

	-- Output to PS2 Keyboard
	o_tx_data : out std_logic_vector(7 downto 0);
	o_tx_data_available : out std_logic;

	-- Input from PS2 Keyboard
    i_rx_data : in std_logic_vector(7 downto 0);
    i_rx_data_available : in std_logic;
    i_rx_error : in std_logic

);
end PS2KeyboardIndicators;

architecture Behavioral of PS2KeyboardIndicators is
	signal s_currentLeds : std_logic_vector(3 downto 0);
	type states is
	(
		idle, 
		wait_byte1_reply, 
		wait_byte2_reply
	);
	signal s_state : states := idle;
begin

	process (i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_currentLeds <= (others => '0');
				o_tx_data_available <= '0';
			else
				o_tx_data_available <= '0';

				case s_state is
					when idle =>
						if s_currentLeds /= ('1' & i_leds) then

							-- Capture the new state
							s_currentLeds <= '1' & i_leds;

							-- Send the first byte
							o_tx_data <= x"ED";
							o_tx_data_available <= '1';
							s_state <= wait_byte1_reply;

						end if;

					when wait_byte1_reply =>
						if i_rx_data_available = '1' then
							if i_rx_error = '0' and i_rx_data = x"FA" then
								o_tx_data <= "00000" & s_currentLeds(2 downto 0);
								o_tx_data_available <= '1';
								s_state <= wait_byte2_reply;
							else
								s_state <= idle;
							end if;
						end if;

					when wait_byte2_reply => 						
						if i_rx_data_available = '1' then
							s_state <= idle;
						end if;

				end case;
			end if;
		end if;
	end process;

end Behavioral;

