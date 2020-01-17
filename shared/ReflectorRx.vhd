--------------------------------------------------------------------------
--
-- ReflectorRx
--
-- Reflect a bit pattern from a PC to this FPGA design
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity ReflectorRx is
generic
(
    -- Resolution
    p_clock_hz : integer;                       -- Frequency of the system clock
    p_baud : integer := 115200;                 -- Baud Rate
    p_bit_width : integer                       -- Bit width of bits to be reflected
);
port 
( 
    -- Control
    i_clock : in std_logic;                     -- Clock
    i_reset : in std_logic;                     -- Reset (synchronous, active high)

    -- Input
    i_uart_rx : in std_logic;                  -- UART RX Signal

    -- Output
    o_signals : out std_logic_vector(p_bit_width-1 downto 0)
);
end ReflectorRx;

architecture Behavioral of ReflectorRx is

    -- The number of bytes need to be received in each packet (7 bits per packet)
    constant c_bytes_per_packet : integer := (p_bit_width + 6) / 7;

    signal s_uart_data : std_logic_vector(7 downto 0);
    signal s_uart_data_available : std_logic;
    signal s_uart_error : std_logic;
    signal s_bytes_left : integer range 0 to c_bytes_per_packet;
    signal s_receive : std_logic_vector(p_bit_width - 1 downto 0);
    signal s_receive_init : std_logic_vector(p_bit_width - 1 downto 0);
    signal s_receive_shift : std_logic_vector(p_bit_width - 1 downto 0);
    signal s_receive_final : std_logic_vector(p_bit_width - 1 downto 0);

begin


    monitor : process(i_clock)
    begin
        if rising_edge(i_clock) then
            if i_reset = '1' then
                s_bytes_left <= c_bytes_per_packet;
            else
                -- Received a byte?
                if s_uart_data_available = '1' then

                    -- If error, ignore everything until the next valid start of packet
                    if s_uart_error = '1' then
                        s_bytes_left <= c_bytes_per_packet;
                    else
                        if s_uart_data(7) = '1' then
                            -- Start of packet?
                            if c_bytes_per_packet = 1 then
                                o_signals <= s_receive_init;
                                s_bytes_left <= c_bytes_per_packet;
                            else
                                s_receive <= s_receive_init;
                                s_bytes_left <= c_bytes_per_packet - 1;
                            end if;
                        elsif s_bytes_left /= c_bytes_per_packet then
                            -- Continued packet
                            if s_bytes_left = 1 then
                                o_signals <= s_receive_final;
                                s_bytes_left <= c_bytes_per_packet;
                            else
                                s_receive <= s_receive_shift;
                                s_bytes_left <= s_bytes_left - 1;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Uart
    uart_rx : entity work.UartRx
    generic map
    (
        p_clock_hz => p_clock_hz,
        p_baud => p_baud
    )
    port map
    ( 
        i_clock => i_clock,
        i_reset => i_reset,
        o_data => s_uart_data,
        o_data_available => s_uart_data_available,
        i_uart_rx => i_uart_rx,
        o_busy => open,
        o_error => s_uart_error
    );


    data_lt7 : if p_bit_width <= 7 generate
        s_receive_init <= s_uart_data(6-(7-p_bit_width) downto 0);
        s_receive_shift <= (others => '0');
        s_receive_final <= (others => '0');
    end generate;

    data_gt7: if p_bit_width > 7 generate
        s_receive_init(p_bit_width - 1 downto p_bit_width - 7) <= s_uart_data(6 downto 0);
        s_receive_init(p_bit_width - 8 downto 0) <= (others => '0');
        s_receive_shift <= s_uart_data(6 downto 0) & s_receive(p_bit_width - 1 downto 7);
    end generate;

    data_div7 : if p_bit_width > 7 and p_bit_width rem 7 = 0 generate
        s_receive_final <= s_receive_shift;
    end generate;

    data_no_div7 : if  p_bit_width > 7 and p_bit_width rem 7 /= 0 generate
        s_receive_final <= s_uart_data(p_bit_width rem 7 - 1 downto 0) & s_receive(p_bit_width - 1 downto p_bit_width rem 7);
    end generate;
    
end Behavioral;

-- (1 downto 0) & (15 downto 2)