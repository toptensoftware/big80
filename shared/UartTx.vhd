--------------------------------------------------------------------------
--
-- UartTx
--
-- Simple UART TX module - no parity bit, 1 start and 1 stop bit
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity UartTx is
generic
(
    p_clken_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200                  -- Baud Rate
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_clken : in std_logic;                     -- Clock Enable
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Input
    i_data : in std_logic_vector(7 downto 0);   -- Data to be transmitted
    i_data_available : in std_logic;            -- Assert for one clock cycle to sent i_data

    -- Output
    o_uart_tx : out std_logic;                  -- UART TX Signal

    -- Status
    o_busy : out std_logic                   -- '1' when transmitting
);
end UartTx;

architecture Behavioral of UartTx is
    signal s_clken : std_logic;
    signal s_data : std_logic_vector(9 downto 0);
    signal s_bits_left : integer range 0 to 10;
    signal s_busy : std_logic;
begin

    -- Clock Divider
    clock_divider : entity work.ClockDivider
    generic map
    (
        p_period => p_clken_hz / p_baud
    )
    port map
    (
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        o_clken => s_clken
    );

    -- Transmit process
    tx: process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_data <= (others => '0');
                s_bits_left <= 0;
                o_uart_tx <= '1';
            elsif i_clken = '1' then
                if i_data_available = '1' and s_busy = '0' then
                    s_data <= "1" & i_data & "0";
                    s_bits_left <= 10;
                end if;

                if s_clken ='1' and s_busy = '1' then 
                    o_uart_tx <= s_data(0);
                    s_data <= '1' & s_data(9 downto 1);
                    s_bits_left <= s_bits_left - 1;
                end if;
            end if;
        end if;
    end process;

    -- Generate busy signal
    s_busy <= '0' when s_bits_left = 0 else '1';
    o_busy <= s_busy or i_data_available;

end Behavioral;

