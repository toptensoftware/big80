library ieee;
use ieee.std_logic_1164.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '1';
    signal s_reset : std_logic := '0';
begin

    reset_proc: process
    begin
        s_reset <= '1';
        wait for 2 us;
        s_reset <= '0';
        wait;
    end process;

    stim_proc: process
    begin
        s_clock <= not s_clock;
        wait for 1 us;
    end process;


    vgaTiming : entity work.VGATiming
    generic map
    (
        p_HRes => 20,
        p_VRes => 20,
        p_PixelLatency => 0,
        p_HFrontPorch => 5,
        p_HSyncWidth => 5,
        p_HBackPorch => 5,
        p_VFrontPorch => 5,
        p_VSyncWidth => 5,
        p_VBackPorch => 5
    )
	port map
	(
        i_Clock => s_Clock,
        i_ClockEnable => '1',
        i_Reset => s_Reset,
        o_HSync => open,
        o_VSync => open,
        o_HPos => open,
        o_VPos => open,
        o_Blank => open
	);

end;