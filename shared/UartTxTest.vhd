--------------------------------------------------------------------------
--
-- UartTxTest
--
-- UART Transmit Module TestBench
--
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity UartTxTest is
generic
(
    -- Resolution
    p_clock_hz : integer;                 -- Frequency of the clock
    p_bytes_per_chunk : integer;       -- Number of bytes to send per chunk
    p_chunks_per_second : integer;     -- Number of chunks to send per second
    p_baud : integer := 115200         -- Baud Rate
);
port 
( 
    -- Control
    i_clock : in std_logic;            -- Clock
    i_reset : in std_logic;            -- Reset (synchronous, active high)

    -- Output
    o_uart_tx : out std_logic          -- UART TX Signal
);
end UartTxTest;

architecture Behavioral of UartTxTest is
    signal s_chunk_enable : std_logic;
    signal s_tx_data : std_logic_vector(7 downto 0);
    signal s_tx_data_available : std_logic;
    signal s_tx_busy : std_logic;
    signal s_in_chunk : std_logic;
    signal s_byte_count : integer range 0 to p_bytes_per_chunk - 1;
begin

    uart : entity work.UartTx
    generic map
    (
        p_clock_hz => p_clock_hz,
        p_baud => p_baud
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => '1',
        i_reset => i_reset,
        i_data => s_tx_data,
        i_data_available => s_tx_data_available,
        o_uart_tx => o_uart_tx,
        o_busy_tx => s_tx_busy
    );

    chunk_divider : entity work.ClockDivider
    generic map
    (
        p_period => p_clock_hz / p_chunks_per_second
    )
    port map
    (
        i_clock => i_clock,
        i_clken => '1',
        i_reset => i_reset,
        o_clken => s_chunk_enable
    );

    driver : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_tx_data <= x"FF";
                s_tx_data_available <= '0';
                s_in_chunk <= '0';
                s_byte_count <= 0;
            else

                s_tx_data_available <= '0'; 

                if s_in_chunk = '0' then
                    -- start new chunk
                    if s_chunk_enable = '1' then 
                        s_in_chunk <= '1';
                        s_byte_count <= 0;
                    end if;
                else
                    if s_tx_busy = '0' then
                        

                        -- bump data
                        if s_tx_data = x"06" then
                            s_tx_data <= x"00";
                        else
                            s_tx_data <= std_logic_vector(unsigned(s_tx_data) + 1);
                        end if;

                        -- Transmit it
                        s_tx_data_available <= '1';

                        -- Revert to idle mode?
                        if s_byte_count = p_bytes_per_chunk - 1 then
                            s_in_chunk <= '0';
                        else
                            -- bump byte count
                            s_byte_count <= s_byte_count + 1;
                        end if;

                    end if;
                end if;
                
            end if;
        end if;
    end process;

end Behavioral;

