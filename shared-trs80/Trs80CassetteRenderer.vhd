--------------------------------------------------------------------------
--
-- Trs80CassetteRenderer
--
-- Renders TRS-80 500 Baud audio cassette signals
--
--   * takes a single byte at a time and generates an audio signal for it
--   * asserts o_data_needed for one cycle when a new data byte is needed
--   * after o_data_needed has been asserted the new byte must be available
--      on the next clock cycle
--
-- This component constantly produces an audio signal.  When not in use,
-- assert i_reset to go silent.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity Trs80CassetteRenderer is
generic
(
	p_clken_hz : integer  				-- Frequency of the clock enable
);
port
(
    -- Control
	i_clock : in std_logic;                         -- Clock
	i_clken : in std_logic;					-- Clock Enable
	i_reset : in std_logic;                         -- Reset (synchronous, active high)
	
	-- Data
	i_data : in std_logic_vector(7 downto 0);			-- The byte to be rendered
	o_data_needed : out std_logic;					-- Asserts high for one clock cycle when next byte needed

	-- Audio
	o_audio : out std_logic_vector(1 downto 0)		-- generated audio signal
);
end Trs80CassetteRenderer;
 
architecture behavior of Trs80CassetteRenderer is 

	constant c_baud : integer := 500;						-- Frequency of zero bit pulses
	constant c_pulse_width_us : integer := 200;				-- Width of each pulse (in us)

	-- The width of each pulse in clock enabled ticks (177)
	constant c_pulse_width_ticks : integer := c_pulse_width_us * p_clken_hz / 1_000_000;

	-- Baud rate converted to clock ticks (3548)
	constant c_baudrate_ticks : integer := p_clken_hz  / c_baud;

	signal s_baudrate_divider : integer range 0 to c_baudrate_ticks - 1;
	signal s_current_byte : std_logic_vector(7 downto 0);
	signal s_bit_counter : integer range 0 to 7;
	signal s_in_pulse : std_logic;
	signal s_in_positive_pulse : std_logic;
begin

	-- Byte shifter
	byte_shifter : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_current_byte <= i_data;
				s_bit_counter <= 0;
			elsif i_clken = '1' then
				if s_baudrate_divider = c_baudrate_ticks - 1 then
					if s_bit_counter = 7 then
						s_current_byte <= i_data;
						s_bit_counter <= 0;
					else
						s_current_byte <= s_current_byte(6 downto 0) & '0';
						s_bit_counter <= s_bit_counter + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	o_data_needed <= 
		'1' when s_bit_counter = 7 and s_baudrate_divider = c_baudrate_ticks - 2
		else '0';

	-- Divide clock to baud rate
	audio_clock : process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_baudrate_divider <= 0;
			elsif i_clken = '1' then
				if s_baudrate_divider = c_baudrate_ticks - 1 then
					s_baudrate_divider <= 0;
				else
					s_baudrate_divider <= s_baudrate_divider + 1;
				end if;
			end if;
		end if;
	end process;

	-- currently in pulse
	s_in_pulse <=
		'0' when
			i_reset = '1'
		else '1' when 
			s_baudrate_divider < c_pulse_width_ticks 
		else '1' when 
			s_current_byte(7) = '1' and 
			s_baudrate_divider >= (c_baudrate_ticks / 2) and 
			s_baudrate_divider < (c_baudrate_ticks / 2) + c_pulse_width_ticks 
		else '0';

	s_in_positive_pulse <=
		'1' when 
			s_baudrate_divider < c_pulse_width_ticks / 2 or
			(s_baudrate_divider >= (c_baudrate_ticks / 2) and s_baudrate_divider < (c_baudrate_ticks / 2) + (c_pulse_width_ticks / 2))
		else '0';

	o_audio(0) <= s_in_pulse and s_in_positive_pulse;
	o_audio(1) <= s_in_pulse and not s_in_positive_pulse;

end;
