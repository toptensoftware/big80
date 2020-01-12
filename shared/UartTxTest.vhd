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
    p_ClockFrequency : integer;                 -- Frequency of the clock
    p_BytesPerChunk : integer;                  -- Number of bytes to send per chunk
    p_ChunksPerSecond : integer;                -- Number of chunks to send per second
    p_BaudRate : integer := 115200              -- Baud Rate
);
port 
( 
    -- Control
    i_Clock : in std_logic;                     -- Clock
    i_Reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Output
    o_UartTx : out std_logic                    -- UART TX Signal
);
end UartTxTest;

architecture Behavioral of UartTxTest is
    signal s_chunk_enable : std_logic;
    signal s_tx_data : std_logic_vector(7 downto 0);
    signal s_tx_data_available : std_logic;
    signal s_tx_busy : std_logic;
    signal s_in_chunk : std_logic;
    signal s_byte_count : integer range 0 to p_BytesPerChunk - 1;
begin

    uart : entity work.UartTx
    generic map
    (
        p_ClockFrequency => p_ClockFrequency,
        p_BaudRate => p_BaudRate
    )
    port map
    ( 
        i_Clock => i_Clock,
        i_ClockEnable => '1',
        i_Reset => i_Reset,
        i_Data => s_tx_data,
        i_DataAvailable => s_tx_data_available,
        o_UartTx => o_UartTx,
        o_Busy => s_tx_busy
    );

    chunk_divider : entity work.ClockDivider
    generic map
    (
        p_DivideCycles => p_ClockFrequency / p_ChunksPerSecond
    )
    port map
    (
        i_Clock => i_Clock,
        i_ClockEnable => '1',
        i_Reset => i_Reset,
        o_ClockEnable => s_chunk_enable
    );

    driver : process(i_Clock)
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
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
                        if s_byte_count = p_BytesPerChunk - 1 then
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

