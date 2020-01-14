--------------------------------------------------------------------------
--
-- Trs80CassetteParser
--
-- Parses TRS-80 500 Baud audio cassette signals
--
--   * takes an audio signal and generates a sequence of bytes
--   * asserts o_data_available for one cycle when a new data byte is available
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
	p_clken_hz : integer  							-- Frequency of the clock enable
);
port
(
    -- Control
	i_clock : in std_logic;                         -- Clock
	i_clken : in std_logic;							-- Clock Enable
	i_reset : in std_logic;                         -- Reset (synchronous, active high)
	
	-- Input
	i_audio : in std_logic;							-- The audio signal to be parsed

	-- Output
	o_data_available : out std_logic;				-- Asserts high for one clock cycle when next byte available
	o_data : out std_logic_vector(7 downto 0)		-- Parsed byte
);
end Trs80CassetteParser;
 
architecture behavior of Trs80CassetteParser is 

	-- Baud rate converted to clock ticks (3548)
	constant c_baud : integer := 500;
	constant c_baud_ticks : integer := p_clken_hz  / c_baud;

	signal s_tick_since_last_edge : integer range 0 to c_baud_ticks - 1;
	signal s_current_byte : std_logic_vector(7 downto 0);
	signal s_bit_count : integer range 0 to 7;
	signal s_audio_prev : std_logic;

	signal s_have_sync_pulse : std_logic;
	signal s_have_one_pulse : std_logic;
	signal s_current_bit : std_logic;
	signal s_bit_available : std_logic;

	signal s_byte_synced : std_logic;
begin

	o_data <= s_current_byte;

	bit_parser : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_audio_prev <= '0';
				s_have_sync_pulse <= '0';
				s_have_one_pulse <= '0';
				s_current_bit <= '0';
				s_bit_available <= '0';
				s_tick_since_last_edge <= 0;
			elsif i_clken = '1' then

				s_bit_available <= '0';

				-- Detect rising edge
				s_audio_prev <= i_audio;
				if i_audio = '1' and s_audio_prev = '0' then

					if s_have_sync_pulse = '0' then

						-- Sync pulse detected, start counting ticks
						s_have_sync_pulse <= '1';
						s_have_one_pulse <= '0';
						s_tick_since_last_edge <= 0;

					else

						-- Second pulse, is it a 1-bit or start of next pulse?
						if s_tick_since_last_edge < (c_baud_ticks * 3/ 4) then

							-- 1-bit
							s_have_one_pulse <= '1';

						else

							-- end of bit (new sync pulse seen)
							s_current_bit <= s_have_one_pulse;
							s_bit_available <= '1';
							s_have_sync_pulse <= '1';
							s_have_one_pulse <= '0';
							s_tick_since_last_edge <= 0;

						end if;

					end if;

				elsif s_have_sync_pulse = '1' then

					if s_tick_since_last_edge /= c_baud_ticks - 1 then 

						-- Increment tick counter
						s_tick_since_last_edge <= s_tick_since_last_edge + 1;

					else

						-- End of bit (time out)
						s_current_bit <= s_have_one_pulse;
						s_bit_available <= '1';
						s_have_sync_pulse <= '0';
						s_have_one_pulse <= '0';
						s_tick_since_last_edge <= 0;

					end if;
				end if;
			end if;
		end if;
	end process;

	bit_handler : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then

				s_current_byte <= (others => '0');
				s_bit_count <= 0;
				s_byte_synced <= '0';
				o_data_available <= '0';
			
			elsif i_clken = '1' then

				o_data_available <= '0';

				if s_bit_available = '1' then 

					s_current_byte <= s_current_byte(6 downto 0) & s_current_bit;

					if s_byte_synced = '0' and s_current_bit = '1' then

						s_byte_synced <= '1';
						s_bit_count <= 1;

					else
						if s_bit_count = 7 then

							o_data_available <= '1';
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
