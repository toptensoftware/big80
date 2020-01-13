library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestBench is
end TestBench;

architecture behavior of TestBench is
    signal s_clock : std_logic := '1';
    signal s_reset : std_logic := '0';
    signal s_HPos : integer range -2048 to 2047;
    signal S_VPos : integer range -2048 to 2047;
    signal s_VideoRamAddr : std_logic_vector(9 downto 0);
    signal s_VideoRamData : std_logic_vector(7 downto 0);
    signal s_CharRomAddr :  std_logic_vector(10 downto 0);
    signal s_CharRomData :  std_logic_vector(5 downto 0);
    signal s_Pixel : std_logic;
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
        p_HRes => 6 * 2 * 4,            -- 4 characters wide
        p_VRes => 12 * 3 * 2,           -- 2 lines high
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
        o_HPos => s_HPos,
        o_VPos => s_VPos,
        o_Blank => open
    );
    
    -- Fake Video RAM
    video_ram_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_VideoRamData <= x"FF";
            else
                s_VideoRamData <= "000000" & s_VideoRamAddr(1 downto 0);
            end if;
        end if;
    end process;

    -- Fake Character ROM
    char_rom_proc : process(s_clock)
    begin
        if rising_edge(s_clock) then
            if s_reset = '1' then
                s_CharRomData <= "111111";
            else
                case s_CharRomAddr(5 downto 4) is
                    when "00" => s_CharRomData <= "101010";
                    when "01" => s_CharRomData <= "000000";
                    when "10" => s_CharRomData <= "010101";
                    when "11" => s_CharRomData <= "000000";
                    when others => s_CharRomData <= "111111";
                end case;
            end if;
        end if;
    end process;

    -- Video Controller (UUT)
    videoController : entity work.Trs80VideoController
    generic map
    (
        p_LeftMarginPixels => 0,
        p_TopMarginPixels => 0
    )
    port map
    (
        i_Clock => s_Clock,
        i_ClockEnable => '1',
        i_Reset => s_Reset,
        i_HPos => s_HPos,
        i_VPos => s_VPos,
        i_WideMode => '0',
        o_VideoRamAddr => s_VideoRamAddr,
        i_VideoRamData => s_VideoRamData,
        o_CharRomAddr => s_CharRomAddr,
        i_CharRomData => s_CharRomData,
        o_Pixel => s_Pixel
    );
end;