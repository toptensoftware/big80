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
        p_horz_res => 20,
        p_vert_res => 20,
        p_pixel_latency => 0,
        p_horz_front_porch => 5,
        p_horz_sync_width => 5,
        p_horz_back_porch => 5,
        p_vert_front_porch => 5,
        p_vert_sync_width => 5,
        p_vert_back_porch => 5
    )
	port map
	(
        i_clock => s_Clock,
        i_clken => '1',
        i_reset => s_Reset,
        o_horz_sync => open,
        o_vert_sync => open,
        o_horz_pos => open,
        o_vert_pos => open,
        o_blank => open
	);

end;