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
    p_clken_hz : integer;                       -- Frequency of the clock
    p_baud : integer := 115200;                 -- Baud Rate
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
    i_signals : in std_logic_vector(p_bit_width-1 downto 0)
);
end ReflectorTx;

architecture Behavioral of ReflectorTx is

    -- The number of bytes need to be transmitted in each packet (7 bits per packet)
    constant c_bytes_per_packet : integer := (p_bit_width + 6) / 7;

    signal s_uart_data : std_logic_vector(7 downto 0);
    signal s_uart_data_available : std_logic;
    signal s_uart_busy : std_logic;
    signal s_prev_signals : std_logic_vector(p_bit_width-1 downto 0);
    signal s_transmit : std_logic_vector(p_bit_width-1 downto 0);
    signal s_transmit_shift : std_logic_vector(p_bit_width-1 downto 0);
    signal s_bytes_left : integer range 0 to c_bytes_per_packet;

    type states is
    (
        state_idle,
        state_shift,
        state_wait_transmit
    );
    signal s_state : states := state_idle;

begin


    monitor : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_prev_signals <= (others => '0');
                s_state <= state_idle;
                s_uart_data(7) <= '0';
                s_transmit <= (others => '0');
            elsif i_clken = '1' then

                s_uart_data_available <= '0'; 
                s_uart_data(7) <= '0';

                case s_state is

                    when state_idle => 
                        -- Currently idle, monitor for changes in any of the signal values and when
                        -- they change, capture the new values and start transmitting them
                        if s_prev_signals /= i_signals then
                            -- capture
                            s_prev_signals <= i_signals;

                            -- setup transfer
                            s_transmit(p_bit_width-1 downto 0) <= i_signals;
                            s_bytes_left <= c_bytes_per_packet - 1;

                            -- start transfer
                            s_state <= state_wait_transmit;
                            s_uart_data(7) <= '1';
                            s_uart_data_available <= '1';

                            -- wait
                            s_state <= state_shift;
                        end if;

                    when state_shift =>
                        s_transmit <= s_transmit_shift;
                        s_state <= state_wait_transmit;


                    when state_wait_transmit =>
                        if s_uart_busy = '0' then

                            if s_bytes_left = 0 then
                                -- end of transfer
                                s_state <= state_idle;
                            else
                                -- decrement byte counter
                                s_bytes_left <= s_bytes_left - 1;

                                -- start next byte
                                s_uart_data_available <= '1';
                                s_state <= state_shift;

                            end if;

                        end if;

                end case;

            end if;
        end if;
    end process;

    -- Uart
    uart_tx : entity work.UartTx
    generic map
    (
        p_clken_hz => p_clken_hz,
        p_baud => p_baud
    )
    port map
    ( 
        i_clock => i_clock,
        i_clken => i_clken,
        i_reset => i_reset,
        i_data => s_uart_data,
        i_data_available => s_uart_data_available,
        o_uart_tx => o_uart_tx,
        o_busy => s_uart_busy
    );


    data_lt7 : if p_bit_width < 7 generate
        s_uart_data(6 - (7-p_bit_width) downto 0) <= (others => '0');
    end generate;

    data_eq7 : if p_bit_width <= 7 generate
        s_uart_data(p_bit_width-1 downto 0) <= s_transmit(p_bit_width-1 downto 0);
    end generate;

    shift_na: if p_bit_width <= 7 generate
        s_transmit_shift <= (others => '0');
    end generate;

    shift0: if p_bit_width > 7 generate
        s_transmit_shift <= "0000000" & s_transmit(p_bit_width-1 downto 7);
        s_uart_data(6 downto 0) <= s_transmit(6 downto 0);
    end generate;

end Behavioral;

