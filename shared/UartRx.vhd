--------------------------------------------------------------------------
--
-- UartRx
--
-- UART Receive Module
--
-- Simple UART RX module - no parity bit, 1 start and 1 stop bit
--
-- Re-synchronizes on each data bit edge.   Handles transmitter 
-- running between approx +3.5% and -5.0% of the specified baud rate.
--
-- Takes a majority vote by sampling at 7/16, 8/16 and 9/16 point 
-- of each bit. Edges < 5/16 or > 11/16 are considered bit boundaries
-- and will cause a re-sync.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity UartRx is
generic
(
    -- Resolution
    p_clock_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200;                 -- Baud Rate
    p_sync: boolean := true;                 -- Sync the i_uart_rx signal to this clock domain
    p_debounce: boolean := true                -- Debounce the incoming signal
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Output
    i_uart_rx : in std_logic;                   -- UART TX Signal

    -- Input
    o_data : out std_logic_vector(7 downto 0);  -- Data to be transmitted
    o_data_available : out std_logic;           -- Assert for one clock cycle to sent i_data

    -- Status
    o_busy : out std_logic;                  -- '1' when receiving
    o_error : out std_logic                  -- stop bit error
);
end UartRx;

architecture Behavioral of UartRx is
    constant c_ticks_per_bit : integer := p_clock_hz / p_baud;
    signal s_data : std_logic_vector(9 downto 0);
    signal s_bits_left : integer range 0 to 10;
    signal s_busy : std_logic;
    signal s_sample_sum : integer range 0 to 3;
    signal s_ticks_since_edge : integer range 0 to c_ticks_per_bit - 1;
    signal s_prev_uart_rx : std_logic;
    signal s_current_bit : std_logic;
    signal s_data_available : std_logic;
    signal s_rx_sync0 : std_logic;
    signal s_rx_sync : std_logic;
    signal s_rx_clean : std_logic;
begin

    -- Synchronize incoming UART signal to our clock domain
    sync: if p_sync generate

        syncer : process(i_clock)
        begin
            if rising_edge(i_clock) then
                s_rx_sync0 <= i_uart_rx;
                s_rx_sync <= s_rx_sync0;
            end if;
        end process;
    
    end generate;

    -- Or, not...
    nosync: if not p_sync generate
        
        s_rx_sync <= i_uart_rx;

    end generate;


    -- Debounce rx signal
    debounce: if p_debounce generate

        debouncer : entity work.DebounceFilter
        generic map
        (
            p_clock_hz => p_clock_hz,
            p_stable_us => integer(1_000_000.0 / (real(p_baud) * 32.0)),
            p_default_state => '1'
        )
        port map
        (
            i_clock => i_clock,
            i_reset => i_reset,
            i_signal => s_rx_sync,
            o_signal => s_rx_clean
        );

    end generate;

    -- Or, not
    nodebounce: if not p_debounce generate
        s_rx_clean <= s_rx_sync;
    end generate;


    o_data <= s_data(8 downto 1);       -- get from shift register
    o_data_available <= s_data_available;
    o_error <= not s_data(9) and s_data_available;        -- error when stop bit is 0

    -- Current bit is 1 when sample count >= 2
    s_current_bit <= '1' when s_sample_sum > 1 else '0';


    -- Receive process
    rx: process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_data <= (others => '0');
                s_bits_left <= 0;
                s_prev_uart_rx <= '0';
                s_data_available <= '0';
            else

                -- For edge detection
                s_prev_uart_rx <= s_rx_clean;

                -- Clear output pulses
                s_data_available <= '0';

                if s_busy = '0' then

                    -- Currently idle, waiting for falling edge of the start bit
                    if s_prev_uart_rx = '1' and s_rx_clean = '0' then
                        s_bits_left <= 10;
                        s_ticks_since_edge <= 0;
                        s_sample_sum <= 0;
                    end if;

                else

                    -- Count the number of ticks since the last edge.  The current bit
                    -- ends when we reach c_ticks_per_bit or if there's an edge when 
                    -- we're getting close
                    if s_ticks_since_edge = c_ticks_per_bit - 1 or 
                                (s_prev_uart_rx /= s_rx_clean and 
                                 s_ticks_since_edge > c_ticks_per_bit * 11 / 16) then

                        -- end of the current bit
                        s_bits_left <= s_bits_left - 1;

                        -- Shift bits
                        s_data <= s_current_bit & s_data(9 downto 1);

                        -- Full byte?
                        if s_bits_left = 1 then
                            s_data_available <= '1';
                            
                            if s_prev_uart_rx = '1' and s_rx_clean = '0' then
                                s_bits_left <= 10;
                                s_ticks_since_edge <= 0;
                                s_sample_sum <= 0;
                            end if;
                        end if;

                        -- Reset for the next bit
                        s_ticks_since_edge <= 0;
                        s_sample_sum <= 0;

                    else

                        s_ticks_since_edge <= s_ticks_since_edge + 1;

                    end if;

                    -- If there's an edge near the start of the bit then it's probably a late
                    -- running transition between the previous bit and this bit.  Re-sync
                    -- the tick counter to this edge as the start of the bit.
                    if s_prev_uart_rx /= s_rx_clean and s_ticks_since_edge < c_ticks_per_bit * 5 / 16 then
                        s_ticks_since_edge <= 0;
                    end if;

                    -- Sample three times at 7/16, 8/16 and 9/16
                    if s_ticks_since_edge = c_ticks_per_bit * 7 / 16 or
                        s_ticks_since_edge = c_ticks_per_bit * 8 / 16 or
                        s_ticks_since_edge = c_ticks_per_bit * 9 / 16 then

                        if s_rx_clean = '1' then
                            s_sample_sum <= s_sample_sum + 1;
                        end if;

                    end if;

                end if;

            end if;
        end if;
    end process;

    -- Generate busy signal
    s_busy <= '0' when s_bits_left = 0 else '1';
    o_busy <= s_busy;

end Behavioral;

