--------------------------------------------------------------------------
--
-- Trs80CassetteStreamer
--
-- Fills a buffer of 1024 bytes (2 SD card blocks) that are used
-- to supply bytes to a Trs80AudioRenderer.  As each buffer is emptied
-- asserts o_block_needed and receives incoming stream of new data that
-- uses to fill the next buffer.
--
-- The client should assert i_data_cycle for one exactly one clock
-- cycle everytime a new byte of data is available on i_data and should
-- do this exactly 512 times for every time o_block_needed is pulsed.
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

entity Trs80CassetteStreamer is
generic
(
	p_clken_hz : integer;  				-- Frequency of the clock enable
	p_buffer_size : integer := 9					-- Size of half buffer as power of 2
);
port
(
	-- Control
	i_clock : in std_logic;                         -- Main Clock
	i_clken : in std_logic;					-- Clock Enable
	i_reset : in std_logic;                         -- Reset (synchronous, active high)

	-- Playback or Record?
	i_record_mode : in std_logic;					-- Keep high while releasing reset to enter record mode

	-- Playback
	o_block_needed : out std_logic;					-- Asserts high for one main clock cycle when next 512 bytes needed
	o_audio : out std_logic_vector(1 downto 0);		-- generated audio signal

	-- Record
	i_audio : in std_logic;							-- input audio stream
	o_block_available : out std_logic;				-- Asserts for one main clock cycle when next 512 bytes are available

	-- Buffering
	i_data_cycle : in std_logic;					-- Play: assert for one main clock cycle when 
													--       input data on o_data is valid
													-- Record: assert for one main clock cycle when
													--       next output byte on o_data needed. Will
													--		 be available on the next cycle
	i_data : in std_logic_vector(7 downto 0);		-- Play: Input data
	o_data : out std_logic_vector(7 downto 0);		-- Record: Output data

	i_stop_recording : in std_logic;				-- Assert for 1 cycle to stop the recorder and flush buffers
	o_recording_finished : out std_logic			-- Asserts for 1 cycle when recording buffers have been flushed
);
end Trs80CassetteStreamer;
 
architecture behavior of Trs80CassetteStreamer is 

	signal s_record_mode : std_logic;

	signal s_render_byte : std_logic_vector(7 downto 0);
	signal s_render_data_needed : std_logic;
	signal s_renderer_reset : std_logic;

	signal s_parser_byte : std_logic_vector(7 downto 0);
	signal s_parser_data_available : std_logic;
	signal s_parser_reset : std_logic;

	signal s_ram_write : std_logic;
	signal s_ram_write_addr : std_logic_vector(p_buffer_size downto 0);
	signal s_ram_write_data : std_logic_vector(7 downto 0);
	signal s_ram_read_addr : std_logic_vector(p_buffer_size downto 0);
	signal s_ram_read_data : std_logic_vector(7 downto 0);

	constant c_low_addr_ones : std_logic_vector(p_buffer_size - 1 downto 0) := (others => '1');
	constant c_low_addr_zeros : std_logic_vector(p_buffer_size - 1 downto 0) := (others => '0');

    type states is
    (
		state_Idle,

        state_PlayInit, 
        state_PlayPreBuffering, 		-- from sd card
        state_PlayDraining, 			-- to renderer
		state_PlayBuffering,			-- from sd card
		
		state_RecInit,				
		state_RecBuffering,				-- from parser
		state_RecDraining,				-- to sd card
		state_RecFlush,					-- start flush
		state_RecFlushZero,				-- fill final buffer with zeros
		state_RecFlushWrite,			-- write final buffer
		state_RecFinished0,				-- delay finished signal one cycle
		state_RecFinished
    );

	signal s_state : states := state_Idle;
--pragma synthesis_off
	signal s_state_integer : integer;
--pragma synthesis_on
begin

--pragma synthesis_off
	process
	begin
		aloop : for s in states loop
			report  integer'image(states'pos(s)) & " " & states'image(s);
		end loop;
		wait;
	end process;

	s_state_integer <= states'pos(s_state);
--pragma synthesis_on

	-- hold renderer in reset state until pre-buffering finished
	s_renderer_reset <= '1' when 
		i_reset = '1' or 
		s_state = state_PlayInit or
		s_state = state_PlayPreBuffering or
		s_record_mode = '1'
		else '0';

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

	-- hold parser in reset state unless recording
	s_parser_reset <= '1' when i_reset='1' or s_record_mode = '0' else '0';

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

	-- 2 x 512 byte block buffers
	ram : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_addr_width => p_buffer_size + 1
	)
	PORT MAP
	(
		-- Read port
		i_clock_a => i_clock,
		i_clken_a => '1',
		i_write_a  => '0',
		i_addr_a => s_ram_read_addr,
		i_din_a => (others => '0'),
		o_dout_a => s_ram_read_data,

		-- Write port
		i_clock_b => i_clock,
		i_clken_b => '1',
		i_write_b => s_ram_write,
		i_addr_b => s_ram_write_addr,
		i_din_b => s_ram_write_data,
		o_dout_b => open
	);

	-- RAM write depends on record/playback
	s_ram_write_data <= 
		x"00" when s_state = state_RecFlushZero else
		i_data when s_record_mode = '0' else 
		s_parser_byte;
	s_ram_write <= 
		'1' when s_state = state_RecFlushZero else 
		i_data_cycle when s_record_mode = '0' else 
		(s_parser_data_available and i_clken);

	-- RAM read goes to both renderer and to output
	s_render_byte <= s_ram_read_data;
	o_data <= s_ram_read_data;

	o_recording_finished <= '1' when s_state = state_RecFinished else '0';

	-- whenever the client sends us data, move to next write address
	buffer_proc: process(i_clock)
	begin
		if rising_edge(i_clock) then
			if i_reset = '1' then
				s_ram_write_addr <= (others => '0');
				s_ram_read_addr <= (others => '0');
				o_block_needed <= '0';
				o_block_available <= '0';
				s_state <= state_idle;
			else
				o_block_needed <= '0';
				o_block_available <= '0';

				if i_clken = '1' then

					-- whenever the renderer wants more data, move to the next read address
					if s_record_mode = '0' and s_render_data_needed = '1' then
						s_ram_read_addr <= std_logic_vector(unsigned(s_ram_read_addr) + 1);
					end if;

					-- whenever the parser has more data, move to the next write address
					if (s_record_mode = '1' and s_parser_data_available = '1') or (s_state = state_RecFlushZero) then
						s_ram_write_addr <= std_logic_vector(unsigned(s_ram_write_addr) + 1);
					end if;

				end if;

				-- Stop recording?
				if i_stop_recording = '1' then 
					s_record_mode <= '0';
				end if;

				case s_state is
					when state_Idle => 
						s_record_mode <= i_record_mode;
						if i_record_mode = '0' then
							s_state <= state_PlayInit;
						else
							s_state <= state_RecInit;
						end if;
					
					when state_PlayInit => 
						-- Start first SD read operation
						s_state <= state_PlayPreBuffering;
						o_block_needed <= '1';

					when state_PlayPreBuffering  => 
						-- Fill first buffer
						if i_data_cycle = '1' then
							s_ram_write_addr <= std_logic_vector(unsigned(s_ram_write_addr) + 1);
							if s_ram_write_addr(p_buffer_size-1 downto 0) = c_low_addr_ones then
								s_state <= state_PlayDraining;
							end if;
						end if;

					when state_PlayDraining => 
						-- Monitor for half buffer drained and start a new SD read operation
						if s_ram_read_addr(p_buffer_size) /= s_ram_write_addr(p_buffer_size) then
							o_block_needed <= '1';
							s_state <= state_PlayBuffering;
						end if;

					when state_PlayBuffering  => 
						-- Fill buffer from SD card
						if i_data_cycle = '1' then
							s_ram_write_addr <= std_logic_vector(unsigned(s_ram_write_addr) + 1);
							if s_ram_write_addr(p_buffer_size-1 downto 0)  = c_low_addr_ones then
								s_state <= state_PlayDraining;
							end if;
						end if;

					when state_RecInit => 
						-- Jump straight to buffering state
						s_state <= state_RecBuffering;

					when state_RecBuffering => 
						-- Monitor for half buffer full and then start a SD write operation
						if s_record_mode = '0' then
							s_state <= state_RecFlush;
						else
							if s_ram_read_addr(p_buffer_size) /= s_ram_write_addr(p_buffer_size) then
								o_block_available <= '1';
								s_state <= state_RecDraining;
							end if;
						end if;

					when state_RecDraining => 
						-- Suppy data to SD card from buffer until drained
						if i_data_cycle = '1' then
							s_ram_read_addr <= std_logic_vector(unsigned(s_ram_read_addr) + 1);
							if s_ram_read_addr(p_buffer_size-1 downto 0)  = c_low_addr_ones then
								if s_record_mode = '1' then
									s_state <= state_RecBuffering;
								else
									s_state <= state_RecFlush;
								end if;
							end if;
						end if;

					when state_RecFlush => 
						-- If the write buffer is partially used, then
						-- fill it with zeros and write it
						if s_ram_write_addr = s_ram_read_addr then
							s_state <= state_RecFinished0;
						else
							s_state <= state_RecFlushZero;
						end if;

					when state_RecFlushZero => 
						-- Fill buffer with zeros
						if s_ram_read_addr(p_buffer_size) /= s_ram_write_addr(p_buffer_size) then
							o_block_available <= '1';
							s_state <= state_RecFlushWrite;
						end if;

					when state_RecFlushWrite =>	
						-- Write final block to SD Card
						if i_data_cycle = '1' then
							s_ram_read_addr <= std_logic_vector(unsigned(s_ram_read_addr) + 1);
							if s_ram_read_addr(p_buffer_size-1 downto 0)  = c_low_addr_ones then
								s_state <= state_RecFinished0;
							end if;
					end if;

					when state_RecFinished0 =>
						s_state <= state_RecFinished;

					when state_RecFinished =>
						-- stay here until reset
						null;

				end case;
			end if;
		end if;
	end process;
end;


