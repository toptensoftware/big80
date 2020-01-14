--------------------------------------------------------------------------
--
-- PS2Input
--
-- Read-only interface to PS2 devices (eg: keyboard)
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity PS2Input is
generic
(
    p_clock_hz : integer                               -- In Hz, used to calculate timings
);
port 
( 
    -- Control
    i_clock : in std_logic;                         -- Clock
    i_reset : in std_logic;                         -- Reset (synchronous, active high)
    
    -- PS2 Signals
    io_ps2_clock : inout std_logic;                 -- PS2 Clock
    io_ps2_data : inout std_logic;                  -- PS2 Data

    -- Output
    o_rx_data : out std_logic_vector(7 downto 0);   -- Outputs received data byte
    o_rx_data_available : out std_logic;            -- Asserts for one cycle when data available
    o_rx_error : out std_logic                      -- When data available, indicates if error
);
end PS2Input;

architecture Behavioral of PS2Input is
    signal s_ps2_clock_sync : std_logic;
    signal s_ps2_clock_debounced : std_logic;
    signal s_data : std_logic_vector(10 downto 0);
    signal s_data_valid : std_logic;
    signal s_data_parity : std_logic;
    constant c_idle_ticks : integer := p_clock_hz * 100 / 1_000_000;    -- 100us
    signal s_idle_count : integer range 0 to c_idle_ticks;
begin

    -- Output signals
    o_rx_data <= s_Data(8 downto 1);
    o_rx_data_available <= '1' when s_idle_count = c_idle_ticks-1 else '0';
    o_rx_error <= not s_data_valid;
                
    -- Synchronize the async PS2 clock signals to our clock
    process (i_clock)
    begin
        if rising_edge(i_clock) then
            s_ps2_clock_sync <= io_ps2_clock;
        end if;
    end process;

    -- Debounce PS2 clock 
	debounce_clock : entity work.DebounceFilter
	GENERIC MAP
	(
		p_clock_hz => p_clock_hz,
		p_stable_us => 5
	)
	PORT MAP
	(
		i_clock => i_clock,
		i_reset => i_reset,
		i_signal => s_ps2_clock_sync,
		o_signal => s_ps2_clock_debounced
	);

    -- Shift incoming bits into s_data register
    process(s_ps2_clock_debounced)
    begin
        if falling_edge(s_ps2_clock_debounced) then
            s_data <= io_ps2_data & s_data(10 downto 1);
        end if;
    end process;

    -- Work out if data is valid
    s_data_parity <= s_data(1) xor s_data(2) xor s_data(3) xor s_data(4) xor
                     s_data(5) xor s_data(6) xor s_data(7) xor s_data(8) xor s_data(9);
    s_data_valid <= '1' when (s_data(0) = '0' and s_data(10) = '1' and s_data_parity = '1') else '0';

    -- Idle time measure
    process (i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_idle_count <= 0;
            else
                if s_ps2_clock_debounced = '0' then
                    s_idle_count <= 0;
                elsif s_idle_count /= c_idle_ticks then
                    s_idle_count <= s_idle_count + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;

