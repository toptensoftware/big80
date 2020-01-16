--------------------------------------------------------------------------
--
-- ReflectorTx
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

entity ReflectorTx is
generic
(
    -- Resolution
    p_clock_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200                  -- Baud Rate
    p_bit_width : integer                       -- Bit width of bits to be reflected
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_clken : in std_logic;                     -- Clock Enable
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Output
    o_uart_tx : out std_logic;                  -- UART TX Signal

    -- Input
    o_signals : in std_logic_vector(p_bit_width-1 downto 0)
);
end ReflectorTx;

architecture Behavioral of ReflectorTx is

    -- The number of bytes need to be transmitted in each packet (7 bits per packet)
    constant c_bytes_per_packet : integer := (p_bit_width + 6) / 7;

    signal s_uart_data : std_logic_vector(7 downto 0);
    signal s_uart_data_available : std_logic;
    signal s_uart_busy : std_logic;
    signal s_prev_signals : std_logic(p_bit_width-1 downto 0);
    signal s_transmit : std_logic(p_bit_width-1 downto 0);
    signal s_bytes_left : integer range 0 to c_bytes_per_packet;


    type states is
    (
        state_idle,
        state_transmit,
    );
    signal s_state : states := state_idle;

begin


    monitor : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_prev_signals <= (others => '0');
                s_state <= state_idle;
            elsif i_clken = '1';

                s_uart_data_available <= '0'; 

                case s_state is

                    when state_idle => 
                        -- Currently idle, monitor for changes in any of the signal values and when
                        -- they change, capture the new values and start transmitting them
                        if s_prev_signals /= s_signals then
                            s_prev_signals <= s_signals;
                            s_transmit <= s_signals;
                            s_bytes_left <= c_bytes_per_packet;
                            s_state <= state_transmit;
                        end if;

                    when state_transmit =>
                        s_uart_data <= '1' and s_transmit(IntMin(6, p_bit_width) downto 0);
                        s_uart_data_available <= '1';
                        s_state <= state_wait_transmit;

                    when state_wait_transmit =>
                        if s_uart_busy = '0' then
                            s_state <= state_wait_transmit;
                        end if;


                end case;

            end if;
        end if;
    end process;

    -- Uart
    uart_tx : entity work.UartTx
    generic map
    (
        p_clock_hz => p_clock_hz,
        p_baud => p_baud
    )
    port 
    ( 
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        i_data => s_data,
        i_data_available => s_data_available,
        o_uart_tx => o_uart_tx,
        o_busy_tx => s_uart_busy
    );

end Behavioral;

