--------------------------------------------------------------------------
--
-- Trs80CassetteStreamer
--
-- Fills a buffer of 1024 bytes (2 SD card blocks) that are used
-- to supply bytes to a Trs80AudioRenderer.  As each buffer is emptied
-- asserts o_DataNeeded and receives incoming stream of new data that
-- uses to fill the next buffer.
--
-- The client should assert i_DataAvailable for one exactly one clock
-- cycle everytime a new byte of data is available on i_Data and should
-- do this exactly 512 times for every time o_DataNeeded is pulsed.
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
	p_ClockEnableFrequency : integer := 1_774_000;  -- Frequency of the clock enable
	p_BaudRate : integer := 500;					-- Frequency of zero bit pulses
	p_PulseWidth_us : integer := 100				-- Width of each pulse (in us)
);
port
(
    -- Control
	i_Clock : in std_logic;                         -- Main Clock
	i_ClockEnable : in std_logic;					-- Clock Enable
	i_Reset : in std_logic;                         -- Reset (synchronous, active high)

	-- Input
	i_Data : in std_logic_vector(7 downto 0);		-- The byte to be buffered
	i_DataAvailable : in std_logic;					-- Assert for one main clock cycle when ever data available on i_Data

	-- Output
	o_DataNeeded : out std_logic;					-- Asserts high for one main clock cycle when next 512 bytes needed
	o_Audio : out std_logic							-- generated audio signal
);
end Trs80CassetteStreamer;
 
architecture behavior of Trs80CassetteStreamer is 
	signal s_render_byte : std_logic_vector(7 downto 0);
	signal s_render_ram_addr : std_logic_vector(9 downto 0);
	signal s_render_data_needed : std_logic;
	signal s_ram_write : std_logic;
	signal s_ram_write_addr : std_logic_vector(9 downto 0);
	signal s_buffer_state : std_logic_vector(1 downto 0);
	signal s_renderer_reset : std_logic;
begin

	-- keep renderer in reset state until pre-buffering finished
	s_renderer_reset <=  i_Reset or not s_buffer_state(1);

	-- renderer
	renderer : entity work.Trs80CassetteRenderer
	port map
	(
		i_Clock => i_Clock,
		i_ClockEnable => i_ClockEnable,
		i_Reset => s_renderer_reset,
		i_Data => s_render_byte,
		o_DataNeeded => s_render_data_needed,
		o_Audio => o_Audio
	);

	-- 2 x 512 cluster buffers
	ram : entity work.RamDualPortInferred	
	GENERIC MAP
	(
		p_AddrWidth => 10
	)
	PORT MAP
	(
		-- Read port
		i_Clock_A => i_Clock,
		i_ClocKEn_A => '1',
		i_Write_A  => '0',
		i_Addr_A => s_render_ram_addr,
		i_Data_A => (others => '0'),
		o_Data_A => s_render_byte,

		-- Write port
		i_Clock_B => i_Clock,
		i_ClocKEn_B => '1',
		i_Write_B => i_DataAvailable,
		i_Addr_B => s_ram_write_addr,
		i_Data_B => i_Data,
		o_Data_B => open
	);

	-- whenever the renderer wants more data, move to the next read address
	render_proc: process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_render_ram_addr <= (others => '0');
			elsif i_ClockEnable = '1' then
				if s_render_data_needed = '1' then
					s_render_ram_addr <= std_logic_vector(unsigned(s_render_ram_addr) + 1);
				end if;
			end if;
		end if;
	end process;

	-- whenever the client sends us data, move to next write address
	buffer_proc: process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			if i_Reset = '1' then
				s_ram_write_addr <= (others => '0');
				s_buffer_state <= "00";
				o_DataNeeded <= '0';
			else
				o_DataNeeded <= '0';
				case s_buffer_state is
					
					when "00" => 
						-- initial
						s_buffer_state <= "01";
						o_DataNeeded <= '1';

					when "01"  => 
						-- pre-loading
						if i_DataAvailable = '1' then

							s_ram_write_addr <= std_logic_vector(unsigned(s_ram_write_addr) + 1);

							-- Once first cluster is loaded, release the prebuffering flag
							-- which releases the reset on the renderer, letting it "go".
							if s_ram_write_addr = "0111111111" then
								s_buffer_state <= "10";
							end if;

						end if;

					when "10" => 
						-- monitoring

						-- readerer has finished with that cluster, request the next
						if s_render_ram_addr(9) /= s_ram_write_addr(9) then
							o_DataNeeded <= '1';
							s_buffer_state <= "11";
						end if;

					when "11"  => 
						-- loading first half of buffer
						if i_DataAvailable = '1' then

							s_ram_write_addr <= std_logic_vector(unsigned(s_ram_write_addr) + 1);

							-- When cluster loaded, back to monitoring state
							if s_ram_write_addr(8 downto 0)  = "111111111" then
								s_buffer_state <= "10";
							end if;

						end if;

					when others =>
						s_buffer_state <= "00";
				end case;
			end if;
		end if;
	end process;
end;


