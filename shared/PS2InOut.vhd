--------------------------------------------------------------------------
--
-- PS2InOut
--
-- Read-write interface to PS2 devices (eg: keyboard)
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use work.FunctionLib.all;

entity PS2InOut is
generic
(
    p_ClockFrequency : integer                  -- In Hz, used to calculate timings
);
port 
( 
    -- Control
    i_Clock : in std_logic;                     -- Clock
    i_Reset : in std_logic;                     -- Reset (synchronous, active high)
    
    -- PS2 Signals
    io_PS2Clock : inout std_logic;              -- PS2 Clock
    io_PS2Data : inout std_logic;               -- PS2 Data

    -- Transmit
    i_TXData : in std_logic_vector(7 downto 0);   -- Input data to transmit
    i_TXDataAvailable : in std_logic;             -- Assert for one cycle when data to be transmitted
    o_TXBusy : out std_logic;                     -- High when transmitting
    o_TXError : out std_logic;                  -- High when transmit error

    -- Receive
    o_RXData : out std_logic_vector(7 downto 0);  -- Outputs received data byte
    o_RXDataAvailable : out std_logic;            -- Asserts for one cycle when data available
    o_RXError : out std_logic                   -- When data available, indicates if parity error
);
end PS2InOut;

architecture Behavioral of PS2InOut is
    signal s_ps2_clock_sync : std_logic;
    signal s_ps2_data_sync : std_logic;
    signal s_ps2_clock_debounced : std_logic;
    signal s_ps2_clock_edge : std_logic;
    signal s_data : std_logic_vector(10 downto 0);
    signal s_data_valid : std_logic;
    signal s_data_parity : std_logic;
    signal s_busy : std_logic;
    signal s_bit_count : integer range 0 to 11;
    constant c_IdleTicks : integer := p_ClockFrequency * 100 / 1_000_000;    -- 100us
    signal s_idle_count : integer range 0 to c_IdleTicks;
    signal s_tx_error : std_logic;
    type states IS
    (
        state_Receive, 
        state_StartTransmit, 
        state_Transmit, 
        state_FinishTransmit
    );
	signal state : states := state_Receive;
begin

    -- Output signals
    o_RXData <= s_Data(8 downto 1);
    --o_RXDataAvailable <= '1' when s_idle_count = c_IdleTicks-1 and s_busy = '0' else '0';
    o_RXError <= not s_data_valid;
    o_TXError <= s_tx_error;
    o_TXBusy <= s_busy;

    -- Busy when in any state except receive
    s_busy <= '0' when state = state_Receive else '1';
                
    -- Synchronize the async PS2 clock signals to our clock
    process (i_Clock)
    begin
        if rising_edge(i_Clock) then
            s_ps2_clock_sync <= io_PS2Clock;
            s_ps2_data_sync <= io_PS2Data;
        end if;
    end process;

    -- Debounce PS2 clock 
	debounce_clock : entity work.DebounceFilterWithEdge
	GENERIC MAP
	(
		p_ClockFrequency => p_ClockFrequency,
		p_DebounceTimeUS => 5
	)
	PORT MAP
	(
		i_Clock => i_Clock,
		i_Reset => i_Reset,
		i_Signal => s_ps2_clock_sync,
        o_Signal => s_ps2_clock_debounced,
        o_SignalEdge => s_ps2_clock_edge
	);

    -- Work out if data is valid
    s_data_parity <= s_data(1) xor s_data(2) xor s_data(3) xor s_data(4) xor
                     s_data(5) xor s_data(6) xor s_data(7) xor s_data(8) xor s_data(9);
    s_data_valid <= '1' when (s_data(0) = '0' and s_data(10) = '1' and s_data_parity = '1') else '0';

    -- State machine
    process (i_Clock)
    begin
        if rising_edge(i_Clock) then
            if i_Reset = '1' then
                state <= state_Receive;
                s_data <= (others => '0');
                io_PS2Clock <= '0';
                io_PS2Data <= 'Z';
                s_idle_count <= 0;
                s_tx_error <= '0';
                o_RXDataAvailable <= '0';
            else
                o_RXDataAvailable <= '0';

                case state is
                    when state_Receive =>
                        if i_TXDataAvailable = '1' then

                            -- Switch to transmit mode
                            state <= state_StartTransmit;

                            -- Setup the bits we'll transmit
                            -- Zero the parity for now, we'll fill it in out later
                            s_data <=  "10" & i_TXData & "0";

                            -- Reset transmit vars
                            s_bit_count <= 0;
                            s_tx_error <= '0';
                            s_idle_count <= c_IdleTicks;

                            -- Claim the bus
                            io_PS2Clock <= '0';
                            io_PS2Data <= 'Z';

                        else

                            -- Release the bus
                            io_PS2Clock <= 'Z';
                            io_PS2Data <= 'Z';

                            -- On falling edge, capture incoming data
                            if s_ps2_clock_edge = '1' and s_ps2_clock_debounced = '0' then
                                s_data <= s_ps2_data_sync & s_data(10 downto 1);
                            end if;

                            -- Track idle time
                            if s_ps2_clock_debounced = '0' then
                                s_idle_count <= 0;
                            elsif s_idle_count /= c_IdleTicks then
                                s_idle_count <= s_idle_count + 1;
                            end if;

                            -- Send the data available pulse
                            if s_idle_count = c_IdleTicks - 1 then 
                                o_RXDataAvailable <= '1';
                            end if;

                        end if;
            
                    when state_StartTransmit =>

                        if s_idle_count /= c_IdleTicks then

                            -- Continue to hold clock line low
                            s_idle_count <= s_idle_count + 1;

                        else

                            -- Put first bit on the data line
                            io_PS2Data <= s_data(0);

                            -- Calculate the parity bit
                            if s_data_parity = '0' then
                                s_data(9) <= not s_data(9);
                            end if;

                            -- Switch to transmit state 
                            state <= state_Transmit;

                        end if;

                    when state_Transmit =>

                        -- Release the clock
                        io_PS2Clock <= 'Z';

                        -- On falling edge, the device will have already captured
                        -- the bit that was on the data line so we can now shift 
                        -- the next bit
                        if s_ps2_clock_edge = '1' and s_ps2_clock_debounced = '0' then
                            s_data <= '0' & s_data(10 downto 1);
                            s_bit_count <= s_bit_count + 1;
                        end if;

                        -- Output data
                        if s_bit_count < 10 then
                            -- Transmit data bits
                            io_PS2Data <= s_data(0);
                        elsif s_bit_count = 10 then
                            -- All data bits transmitted, release the
                            -- data line so we can receive the ack in return
                            io_PS2Data <= 'Z';
                        else
                            -- End of transmit, capture the returned ack signal
                            s_tx_error <= s_ps2_data_sync;
                            state <= state_FinishTransmit;
                        end if;

                    when state_FinishTransmit =>

                        -- Wait for bus to go idle then return to the receive state
                        if s_ps2_clock_debounced = '1' and s_ps2_data_sync = '1' then 
                            state <= state_Receive;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;

