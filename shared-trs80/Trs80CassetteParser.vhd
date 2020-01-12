--------------------------------------------------------------------------
--
-- Trs80CassetteParser
--
-- Parses TRS-80 500 Baud audio cassette signals
--
--   * takes an audio signal and generates a sequence of bytes
--   * asserts o_DataAvailable for one cycle when a new data byte is available
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Trs80CassetteParser is
generic
(
	p_ClockEnableFrequency : integer;  				-- Frequency of the clock enable
	p_BaudRate : integer := 500						-- Frequency of zero bit pulses
);
port
(
    -- Control
	i_Clock : in std_logic;                         -- Clock
	i_ClockEnable : in std_logic;					-- Clock Enable
	i_Reset : in std_logic;                         -- Reset (synchronous, active high)
	
	-- Input
	i_Audio : in std_logic;							-- The audio signal to be parsed

	-- Output
	o_DataAvailable : out std_logic;				-- Asserts high for one clock cycle when next byte available
	o_Data : out std_logic_vector(7 downto 0)		-- Parsed byte
);
end Trs80CassetteParser;
 
architecture behavior of Trs80CassetteParser is 

	-- Baud rate converted to clock ticks (3548)
	constant c_BaudRate_ticks : integer := p_ClockEnableFrequency  / p_BaudRate;

	signal s_TicksSinceLastEdge : integer range 0 to c_BaudRate_ticks - 1;
	signal s_CurrentByte : std_logic_vector(7 downto 0);
	signal s_bit_count : integer range 0 to 7;
	signal s_AudioPrev : std_logic;

	signal s_have_sync_pulse : std_logic;
	signal s_have_one_pulse : std_logic;
	signal s_current_bit : std_logic;
	signal s_bit_available : std_logic;

	signal s_byte_synced : std_logic;
begin

	o_Data <= s_CurrentByte;

	bit_parser : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_AudioPrev <= '0';
				s_have_sync_pulse <= '0';
				s_have_one_pulse <= '0';
				s_current_bit <= '0';
				s_bit_available <= '0';
				s_TicksSinceLastEdge <= 0;
			elsif i_ClockEnable = '1' then

				s_bit_available <= '0';

				-- Detect rising edge
				s_AudioPrev <= i_Audio;
				if i_Audio = '1' and s_AudioPrev = '0' then

					if s_have_sync_pulse = '0' then

						-- Sync pulse detected, start counting ticks
						s_have_sync_pulse <= '1';
						s_have_one_pulse <= '0';
						s_TicksSinceLastEdge <= 0;

					else

						-- Second pulse, is it a 1-bit or start of next pulse?
						if s_TicksSinceLastEdge < (c_BaudRate_ticks * 3/ 4) then

							-- 1-bit
							s_have_one_pulse <= '1';

						else

							-- end of bit (new sync pulse seen)
							s_current_bit <= s_have_one_pulse;
							s_bit_available <= '1';
							s_have_sync_pulse <= '1';
							s_have_one_pulse <= '0';
							s_TicksSinceLastEdge <= 0;

						end if;

					end if;

				elsif s_have_sync_pulse = '1' then

					if s_TicksSinceLastEdge /= c_BaudRate_ticks - 1 then 

						-- Increment tick counter
						s_TicksSinceLastEdge <= s_TicksSinceLastEdge + 1;

					else

						-- End of bit (time out)
						s_current_bit <= s_have_one_pulse;
						s_bit_available <= '1';
						s_have_sync_pulse <= '0';
						s_have_one_pulse <= '0';
						s_TicksSinceLastEdge <= 0;

					end if;
				end if;
			end if;
		end if;
	end process;

	bit_handler : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then

				s_CurrentByte <= (others => '0');
				s_bit_count <= 0;
				s_byte_synced <= '0';
				o_DataAvailable <= '0';
			
			elsif i_ClockEnable = '1' then

				o_DataAvailable <= '0';

				if s_bit_available = '1' then 

					s_CurrentByte <= s_CurrentByte(6 downto 0) & s_current_bit;

					if s_byte_synced = '0' and s_current_bit = '1' then

						s_byte_synced <= '1';
						s_bit_count <= 1;

					else
						if s_bit_count = 7 then

							o_DataAvailable <= '1';
							s_bit_count <= 0;

						else
							
							s_bit_count <= s_bit_count + 1;

						end if;
					end if;
				end if;
			end if;
		end if;
	end process;


end;
