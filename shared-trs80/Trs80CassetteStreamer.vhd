--------------------------------------------------------------------------
--
-- Trs80CassetteStreamer
--
-- Fills a buffer of 1024 bytes (2 SD card blocks) that are used
-- to supply bytes to a Trs80AudioRenderer.  As each buffer is emptied
-- asserts o_BlockNeeded and receives incoming stream of new data that
-- uses to fill the next buffer.
--
-- The client should assert i_DataCycle for one exactly one clock
-- cycle everytime a new byte of data is available on i_Data and should
-- do this exactly 512 times for every time o_BlockNeeded is pulsed.
--
-- This component constantly produces an audio signal.  When not in use,
-- assert i_Reset to go silent.
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
	p_ClockEnableFrequency : integer;  				-- Frequency of the clock enable
	p_BaudRate : integer := 500;					-- Frequency of zero bit pulses
	p_BufferSize : integer := 9;					-- Size of half buffer as power of 2
	p_PulseWidth_us : integer := 100				-- Width of each pulse (in us)
);
port
(
	-- Control
	i_Clock : in std_logic;                         -- Main Clock
	i_ClockEnable : in std_logic;					-- Clock Enable
	i_Reset : in std_logic;                         -- Reset (synchronous, active high)

	-- Playback or Record?
	i_RecordMode : in std_logic;					-- Keep high while releasing reset to enter record mode

	-- Playback
	o_BlockNeeded : out std_logic;					-- Asserts high for one main clock cycle when next 512 bytes needed
	o_Audio : out std_logic;						-- generated audio signal

	-- Record
	i_Audio : in std_logic;							-- input audio stream
	o_BlockAvailable : out std_logic;				-- Asserts for one main clock cycle when next 512 bytes are available

	-- Buffering
	i_DataCycle : in std_logic;						-- Play: assert for one main clock cycle when 
													--       input data on o_Data is valid
													-- Record: assert for one main clock cycle when
													--       next output byte on o_Data needed. Will
													--		 be available on the next cycle
	i_Data : in std_logic_vector(7 downto 0);		-- Play: Input data
	o_Data : out std_logic_vector(7 downto 0);		-- Record: Output data

	i_StopRecording : in std_logic;					-- Assert for 1 cycle to stop the recorder and flush buffers
	o_RecordingFinished : out std_logic			-- Asserts for 1 cycle when recording buffers have been flushed
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
	signal s_ram_write_addr : std_logic_vector(p_BufferSize downto 0);
	signal s_ram_write_data : std_logic_vector(7 downto 0);
	signal s_ram_read_addr : std_logic_vector(p_BufferSize downto 0);
	signal s_ram_read_data : std_logic_vector(7 downto 0);

	constant c_low_addr_ones : std_logic_vector(p_BufferSize - 1 downto 0) := (others => '1');
	constant c_low_addr_zeros : std_logic_vector(p_BufferSize - 1 downto 0) := (others => '0');

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
		i_Reset='1' or 
		s_state = state_PlayInit or
		s_state = state_PlayPreBuffering 
		else '0';

	-- renderer
	renderer : entity work.Trs80CassetteRenderer
	generic map
	(
		p_ClockEnableFrequency => p_ClockEnableFrequency
	)
	port map
	(
		i_Clock => i_Clock,
		i_ClockEnable => i_ClockEnable,
		i_Reset => s_renderer_reset,
		i_Data => s_render_byte,
		o_DataNeeded => s_render_data_needed,
		o_Audio => o_Audio
	);

	-- hold parser in reset state unless recording
	s_parser_reset <= '1' when i_Reset='1' or s_record_mode = '0' else '0';

	-- parser
	parser : entity work.Trs80CassetteParser
	generic map
	(
		p_ClockEnableFrequency => p_ClockEnableFrequency
	)
	port map
	(
		i_Clock => i_Clock,
		i_ClockEnable => i_ClockEnable,
		i_Reset => s_parser_reset,
		i_Audio => i_Audio,
		o_DataAvailable => s_parser_data_available,
		o_Data => s_parser_byte
	);

	-- 2 x 512 byte block buffers
	ram : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_AddrWidth => p_BufferSize + 1
	)
	PORT MAP
	(
		-- Read port
		i_Clock_A => i_Clock,
		i_ClocKEn_A => '1',
		i_Write_A  => '0',
		i_Addr_A => s_ram_read_addr,
		i_Data_A => (others => '0'),
		o_Data_A => s_ram_read_data,

		-- Write port
		i_Clock_B => i_Clock,
		i_ClocKEn_B => '1',
		i_Write_B => s_ram_write,
		i_Addr_B => s_ram_write_addr,
		i_Data_B => s_ram_write_data,
		o_Data_B => open
	);

	-- RAM write depends on record/playback
	s_ram_write_data <= 
		x"00" when s_state = state_RecFlushZero else
		i_Data when s_record_mode = '0' else 
		s_parser_byte;
	s_ram_write <= 
		'1' when s_state = state_RecFlushZero else 
		i_DataCycle when s_record_mode = '0' else 
		(s_parser_data_available and i_ClockEnable);

	-- RAM read goes to both renderer and to output
	s_render_byte <= s_ram_read_data;
	o_Data <= s_ram_read_data;

	o_RecordingFinished <= '1' when s_state = state_RecFinished else '0';

	-- whenever the client sends us data, move to next write address
	buffer_proc: process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_ram_write_addr <= (others => '0');
				s_ram_read_addr <= (others => '0');
				o_BlockNeeded <= '0';
				o_BlockAvailable <= '0';
				s_state <= state_idle;
			else
				o_BlockNeeded <= '0';
				o_BlockAvailable <= '0';

				if i_ClockEnable = '1' then

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
				if i_StopRecording = '1' then 
					s_record_mode <= '0';
				end if;

				case s_state is
					when state_Idle => 
						s_record_mode <= i_RecordMode;
						if i_RecordMode = '0' then
							s_state <= state_PlayInit;
						else
							s_state <= state_RecInit;
						end if;
					
					when state_PlayInit => 
						-- Start first SD read operation
						s_state <= state_PlayPreBuffering;
						o_BlockNeeded <= '1';

					when state_PlayPreBuffering  => 
						-- Fill first buffer
						if i_DataCycle = '1' then
							s_ram_write_addr <= std_logic_vector(unsigned(s_ram_write_addr) + 1);
							if s_ram_write_addr(p_BufferSize-1 downto 0) = c_low_addr_ones then
								s_state <= state_PlayDraining;
							end if;
						end if;

					when state_PlayDraining => 
						-- Monitor for half buffer drained and start a new SD read operation
						if s_ram_read_addr(p_BufferSize) /= s_ram_write_addr(p_BufferSize) then
							o_BlockNeeded <= '1';
							s_state <= state_PlayBuffering;
						end if;

					when state_PlayBuffering  => 
						-- Fill buffer from SD card
						if i_DataCycle = '1' then
							s_ram_write_addr <= std_logic_vector(unsigned(s_ram_write_addr) + 1);
							if s_ram_write_addr(p_BufferSize-1 downto 0)  = c_low_addr_ones then
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
							if s_ram_read_addr(p_BufferSize) /= s_ram_write_addr(p_BufferSize) then
								o_BlockAvailable <= '1';
								s_state <= state_RecDraining;
							end if;
						end if;

					when state_RecDraining => 
						-- Suppy data to SD card from buffer until drained
						if i_DataCycle = '1' then
							s_ram_read_addr <= std_logic_vector(unsigned(s_ram_read_addr) + 1);
							if s_ram_read_addr(p_BufferSize-1 downto 0)  = c_low_addr_ones then
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
						if s_ram_read_addr(p_BufferSize) /= s_ram_write_addr(p_BufferSize) then
							o_BlockAvailable <= '1';
							s_state <= state_RecFlushWrite;
						end if;

					when state_RecFlushWrite =>	
						-- Write final block to SD Card
						if i_DataCycle = '1' then
							s_ram_read_addr <= std_logic_vector(unsigned(s_ram_read_addr) + 1);
							if s_ram_read_addr(p_BufferSize-1 downto 0)  = c_low_addr_ones then
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


