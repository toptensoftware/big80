library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity PS2Device is
port 
( 
    io_PS2Clock : inout std_logic;
    io_PS2Data : inout std_logic
);
end PS2Device;

architecture Behavioral of PS2Device is
begin

    sim : process
    begin
        io_PS2Clock <= 'Z';
        io_PS2Data <= 'Z';

        wait for 10 us;

        io_PS2Data <= '0'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '1'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '0'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '1'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '0'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '0'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '1'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '0'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '1'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '1'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;
        io_PS2Data <= '0'; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1'; wait for 10 us;

        io_PS2Clock <= 'Z';
        io_PS2Data <= 'Z';

        wait until io_PS2Clock'event;
        wait until io_PS2Clock'event;

--        io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--
--        io_PS2Data <= '0';
--        wait for 10 us; io_PS2Clock <= '0'; wait for 10 us; io_PS2Clock <= '1';
--
--        io_PS2Data <= 'Z';
--        io_PS2Clock <= 'Z';

        wait;
    end process;

end Behavioral;

