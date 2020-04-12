--------------------------------------------------------------------------
--
-- Trs80CassetteFifo
--
-- Implements cassette render/parse fifo
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

entity Trs80CassetteFifo  is
generic
(
	p_clken_hz : integer;  							-- Frequency of the clock enable
	p_buffer_size : integer := 7					-- Size of half buffer as power of 2
);
port
(
	-- Control
	i_clock : in std_logic;                 		-- Main Clock
	i_clken : in std_logic;							-- Clock Enable
	i_reset : in std_logic;                 		-- Reset (synchronous, active high)

	-- Playback or Record?
	i_play : in std_logic;							-- Assert to play
	i_record : in std_logic;						-- Assert to record 

	-- Audio signals
	o_audio : out std_logic_vector(1 downto 0);		-- generated audio signal
	i_audio : in std_logic;							-- input audio stream

	-- Data signals
	i_din : in std_logic_vector(7 downto 0);		-- Play: Input data
	o_dout : out std_logic_vector(7 downto 0);		-- Record: Output data
	i_data_cycle : in std_logic;					-- Assert to read/write fifo

	-- State
	o_data_irq : out std_logic;						-- Asserted when fifo nearing 
													-- empty (on read) or full (on write)
	o_full : out std_logic;							-- Asserted when fifo full													
	o_empty : out std_logic							-- Asserted when fifo empty										
);
end Trs80CassetteFifo;
 
architecture behavior of Trs80CassetteFifo is 

	signal s_render_byte : std_logic_vector(7 downto 0);
	signal s_render_data_needed : std_logic;
	signal s_renderer_reset : std_logic;

	signal s_parser_byte : std_logic_vector(7 downto 0);
	signal s_parser_data_available : std_logic;
	signal s_parser_reset : std_logic;

	signal s_fifo_write : std_logic;
	signal s_fifo_din : std_logic_vector(7 downto 0);
	signal s_fifo_read : std_logic;
	signal s_fifo_dout : std_logic_vector(7 downto 0);
	signal s_fifo_full : std_logic;
	signal s_fifo_empty : std_logic;
	signal s_fifo_count : std_logic_vector(p_buffer_size-1 downto 0);

begin

	-- renderer reset condition
	s_renderer_reset <= i_reset or not i_play;

	-- renderer
	renderer : entity work.Trs80CassetteRenderer
	generic map
	(
		p_clken_hz => p_clken_hz
	)
	port map
	(
		i_clock => i_clock,
		i_clken => i_clken,
		i_reset => s_renderer_reset,
		i_data => s_render_byte,
		o_data_needed => s_render_data_needed,
		o_audio => o_audio
	);

	-- parser reset condition
	s_parser_reset <= i_reset or not i_record;

	-- parser
	parser : entity work.Trs80CassetteParser
	generic map
	(
		p_clken_hz => p_clken_hz
	)
	port map
	(
		i_clock => i_clock,
		i_clken => i_clken,
		i_reset => s_parser_reset,
		i_audio => i_audio,
		o_data_available => s_parser_data_available,
		o_data => s_parser_byte
	);

	-- Generate state signals
	o_empty <= s_fifo_empty;
	o_full <= s_fifo_full;
	o_data_irq <= 
				not s_fifo_count(p_buffer_size-1) when i_play = '1' else
				s_fifo_count(p_buffer_size-1) when i_record = '1' else
				'0';

	-- Connect FIFO data signals
	s_render_byte <= s_fifo_dout;
	s_fifo_din <= s_parser_byte when i_record = '1' else i_din;
	o_dout <= s_fifo_dout;

	-- Connect FIFO read/write signals
	s_fifo_write <= s_parser_data_available when i_record = '1' else i_data_cycle;
	s_fifo_read <= s_render_data_needed when i_record = '0' else i_data_cycle;

	-- fifo
	fifo : entity work.Fifo
	generic map
	(
		p_bit_width => 8,
		p_addr_width => p_buffer_size
	)
	port map
	(
		i_clock => i_clock,
		i_clken => i_clken,
		i_reset => i_reset,
		i_write => s_fifo_write,
		i_din => s_fifo_din,
		i_read => s_fifo_read,
		o_dout => s_fifo_dout,
		o_full => s_fifo_full,
		o_empty => s_fifo_empty,
		o_underflow => open,
		o_overflow => open,
		o_count => s_fifo_count
	);

end;


