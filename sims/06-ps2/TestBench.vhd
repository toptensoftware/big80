library ieee;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '1';
    signal s_reset : std_logic := '0';
    signal s_reset_n : std_logic;
    signal s_PS2Clock : std_logic;
    signal s_PS2Data : std_logic;
    signal s_tx_ready : std_logic;
    constant c_ClockFrequency : integer := 100_000_000;
begin

    reset_proc: process
    begin
        s_reset <= '1';
        wait until falling_edge(s_clock);
        wait until falling_edge(s_clock);
        s_reset <= '0';
        wait;
    end process;

    s_reset_n <= not s_reset;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 sec / (real(c_ClockFrequency) * 2.0);
    end process;

    PS2Device : entity work.PS2Device
    port map
    (
        io_PS2Clock => s_PS2Clock,
        io_PS2Data => s_PS2Data
    );


    PS2InOut : entity work.ps2_transceiver
    generic map
    (
		clk_freq => 100_000_000,
		debounce_counter_size => 16
    )
	port map
	(
		clk => s_clock,
		reset_n => s_reset_n,
		tx_ena => s_tx_ready,
		tx_cmd => "010110100",
		tx_busy => open,
		ack_error => open,
		ps2_code => open,
		ps2_code_new => open,
		rx_error => open,
		ps2_clk => s_PS2Clock,
		ps2_data => s_PS2Data
	);

--    PS2InOut : entity work.PS2InOut
--    generic map
--    (
--        p_ClockFrequency => c_ClockFrequency
--    )
--	port map
--	(
--        i_Clock => s_Clock,
--        i_Reset => s_Reset,
--        io_PS2Clock => s_PS2Clock,
--        io_PS2Data => s_PS2Data,
--        i_Data => "01011010",
--        i_DataAvailable => s_tx_ready,
--        o_Busy => open,
--        o_Data => open,
--        o_DataAvailable => open,
--        o_Error => open
--	);

    tx_proc : process
    begin
        s_tx_ready <= '0';
        wait for 300 us;
        s_tx_ready <= '1';
        wait until falling_edge(s_Clock);
        wait until falling_edge(s_Clock);
        s_tx_ready <= '0';

    end process;

end;