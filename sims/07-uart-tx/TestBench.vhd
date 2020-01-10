library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clock_enable : std_logic;
    signal s_data : std_logic_vector(7 downto 0);
    signal s_data_available : std_logic;
    signal s_uart_tx : std_logic;
    signal s_uart_busy : std_logic;
    constant c_ClockFrequency : real := 460800.0;
begin


    reset_proc: process
    begin
        s_reset <= '1';
        wait until rising_edge(s_clock);
        wait until falling_edge(s_clock);
        s_reset <= '0';
        wait;
    end process;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 sec / (c_ClockFrequency * 2.0);
    end process;

    uart : entity work.UartTx
    generic map
    (
        p_ClockFrequency => integer(c_ClockFrequency)
    )
    port map
    (
        i_Clock => s_clock,
        i_Reset => s_reset,
        i_Data => s_data,
        i_DataAvailable => s_data_available,
        o_UartTx => s_uart_tx,
        o_Busy => s_uart_busy
    );

    data : process(s_clock)
        variable count : integer := 0;
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_data <= x"00";
                count := 0;
                s_data_available <= '0';
            else
                s_data_available <= '0';
                if s_uart_busy = '0' then
                    s_data_available <= '1';
                    if count < 4 then
                        s_data <= x"00";
                        count := count + 1;
                    elsif count = 4 then
                        s_data <= x"55";
                        count := count + 1;
                    elsif count = 5 then
                        s_data <= x"00";
                        count := count + 1;
                    else
                       s_data <= std_logic_vector(unsigned(s_data) + 1);
                    end if;
                end if;
            end if;
        end if;
    end process;

end;