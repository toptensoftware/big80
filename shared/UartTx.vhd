--------------------------------------------------------------------------
--
-- UartTx
--
-- UART Transmit Module
--
-- This is a really simple UART TX module.  No parity bit, no
-- configuration of start/stop bits.
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
    -- Resolution
    p_ClockFrequency : integer;                 -- Frequency of the clock
    p_BaudRate : integer := 115200              -- Baud Rate
);
port 
( 
    -- Control
    i_Clock : in std_logic;                     -- Clock
    i_ClockEnable : in std_logic;               -- Clock Enable
    i_Reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Input
    i_Data : in std_logic_vector(7 downto 0);   -- Data to be transmitted
    i_DataAvailable : in std_logic;             -- Assert for one clock cycle to sent i_Data

    -- Output
    o_UartTx : out std_logic;                   -- UART TX Signal
    o_Busy : out std_logic                     -- '1' when transmitting
);
end UartTx;

architecture Behavioral of UartTx is
    signal s_clock_enable : std_logic;
    signal s_data : std_logic_vector(9 downto 0);
    signal s_bits_left : integer range 0 to 10;
    signal s_busy : std_logic;
begin

    -- Clock Divider
    clock_divider : entity work.ClockDivider
    generic map
    (
        p_DivideCycles => p_ClockFrequency / p_BaudRate
    )
    port map
    (
        i_Clock => i_Clock,
        i_ClockEnable => i_ClockEnable,
        i_Reset => i_Reset,
        o_ClockEnable => s_clock_enable
    );

    -- Transmit process
    tx: process(i_Clock)
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
                s_data <= (others => '0');
                s_bits_left <= 0;
                o_UartTx <= '1';
            elsif i_ClockEnable = '1' then
                if i_DataAvailable = '1' and s_busy = '0' then
                    s_data <= "1" & i_Data & "0";
                    s_bits_left <= 10;
                end if;

                if s_clock_enable ='1' and s_busy = '1' then 
                    o_UartTx <= s_data(0);
                    s_data <= '1' & s_data(9 downto 1);
                    s_bits_left <= s_bits_left - 1;
                end if;
            end if;
        end if;
    end process;

    -- Generate busy signal
    s_busy <= '0' when s_bits_left = 0 else '1';
    o_Busy <= s_busy or i_DataAvailable;

end Behavioral;

