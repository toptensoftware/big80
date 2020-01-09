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
    i_Clock : in std_logic;                         -- Clock
    i_Reset : in std_logic;                         -- Reset (synchronous, active high)

	-- Input
	i_LEDs : in std_logic_vector(2 downto 0);

	-- Output to PS2 Keyboard
	o_TXData : out std_logic_vector(7 downto 0);
	o_TXDataAvailable : out std_logic;

	-- Input from PS2 Keyboard
    i_RXData : in std_logic_vector(7 downto 0);
    i_RXDataAvailable : in std_logic;
    i_RXDataError : in std_logic

);
end PS2KeyboardIndicators;

architecture Behavioral of PS2KeyboardIndicators is
	signal s_currentLeds : std_logic_vector(3 downto 0);
	TYPE states IS(idle, wait_byte1_reply, wait_byte2_reply);
	signal s_state : states := idle;
begin

	process (i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_currentLeds <= (others => '0');
				o_TXDataAvailable <= '0';
			else
				o_TXDataAvailable <= '0';

				case s_state is
					when idle =>
						if s_currentLeds /= ('1' & i_LEDs) then

							-- Capture the new state
							s_currentLeds <= '1' & i_LEDs;

							-- Send the first byte
							o_TXData <= x"ED";
							o_TXDataAvailable <= '1';
							s_state <= wait_byte1_reply;

						end if;

					when wait_byte1_reply =>
						if i_RXDataAvailable = '1' then
							if i_RXDataError = '0' and i_RXData = x"FA" then
								o_TXData <= "00000" & s_currentLeds(2 downto 0);
								o_TXDataAvailable <= '1';
								s_state <= wait_byte2_reply;
							else
								s_state <= idle;
							end if;
						end if;

					when wait_byte2_reply => 						
						if i_RXDataAvailable = '1' then
							s_state <= idle;
						end if;

				end case;
			end if;
		end if;
	end process;

end Behavioral;

