library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity TestBench is
end TestBench;

architecture behavior of TestBench is

    constant c_clock_hz : real := 1_774_000.0 * 2.0;

    signal s_clock : std_logic := '0';
    signal s_reset : std_logic;
    signal s_clken : std_logic;

	signal s_play : std_logic;
	signal s_record : std_logic;
	signal s_audio_out : std_logic_vector(1 downto 0);
	signal s_audio_in : std_logic;
	signal s_din : std_logic_vector(7 downto 0);
	signal s_dout : std_logic_vector(7 downto 0);
	signal s_data_cycle : std_logic;
    signal s_data_irq : std_logic;
	signal s_full : std_logic;
	signal s_empty : std_logic;
    signal s_state : integer;
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
        wait for 1 sec / (c_clock_hz * 2.0);
    end process;

    clken_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then 
                s_clken <= '0';
            else
                s_clken <= not s_clken;
            end if;
        end if;
    end process;

	e_Trs80CassetteFifo : entity work.Trs80CassetteFifo
	generic map
	(
        p_clken_hz => 1_774_000,
        p_buffer_size => 3
	)
	port map
	(
		i_clock => s_clock,
		i_clken => s_clken,
		i_reset => s_reset,
		i_play => s_play,
		i_record => s_record,
		o_audio => s_audio_out,
		i_audio => s_audio_in,
		i_din => s_din,
		o_dout => s_dout,
		i_data_cycle => s_data_cycle,
		o_full => s_full,
		o_empty => s_empty,
        o_data_irq => s_data_irq
	);

    s_record <= '0';

    data_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_state <= 0;
                s_din <= x"10";
                s_play <= '0';
            elsif s_clken = '1' then

                s_state <= s_state + 1;
                s_data_cycle <= '0';

                case s_state is

                    when 10|12|14|16 =>
                        s_data_cycle <= '1';
                        s_din <= std_logic_vector(unsigned(s_din) + 1);

                    when 20 =>
                        s_play <= '1';

                    when others =>
                        if s_data_irq = '1' then
                            s_data_cycle <= '1';
                            s_din <= std_logic_vector(unsigned(s_din) + 1);
                        end if;

                        if s_play = '1' and s_empty = '1' then
                            s_play <= '0';
                        end if;

                end case;




            end if;
        end if;
    end process;

end;