--------------------------------------------------------------------------
--
-- SDCardController
--
-- Controller for SD and SDHC cards.
--
-- Init
--   * Wait for o_status(STATUS_BIT_INIT) to assert
--   * o_status(STATUS_BIT_SDHC) = 1 if SDHC card
--
-- Read
--   * set i_op_block_number
--   * set i_op_cmd to "01"
--   * set i_op_write to "1"
--   * o_data_start will be raised for possibly multiple cycles to indicate
--         data is about the be sent.  (ie: i_reset DMA address)
--   * o_data_cycle will be raised exactly 512 times for one cycle
--         for each byte with the data on o_data.  Data will be available for 
--         multiple cycles (about 10)
--   * wait for STATUS_BIT_BUSY to clear to indicate operation finished
--
-- Write
--   * set i_op_block_number
--   * set i_op_cmd to "10"
--   * provide first byte on i_data
--   * set i_op_write to "1"
--   * o_data_start will be raised for possibly multiple cycles to indicate
--         data is about the needed.  (ie: i_reset DMA address)
--   * o_data_cycle will be raised exactly 512 times.  Each time the next byte
--         should be supplied on i_data.  Data needs to be available before 
--		   the next cycle 
--   * wait for STATUS_BIT_BUSY to clear to indicate operation finished
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package SDStatusBits is

	constant STATUS_LO_READY : std_logic_vector(2 downto 0) :=    "000";
	constant STATUS_LO_BUSY : std_logic_vector(2 downto 0) :=     "001";
	constant STATUS_LO_READING : std_logic_vector(2 downto 0) :=  "011";
	constant STATUS_LO_WRITING : std_logic_vector(2 downto 0) :=  "101";

	constant STATUS_BIT_BUSY : natural := 0;		-- controller is busy (read, write or init)
	constant STATUS_BIT_READING : natural := 1;		-- read operation in progress
	constant STATUS_BIT_WRITING : natural := 2;		-- write operation in progress
	constant STATUS_BIT_ERROR : natural := 3;		-- error occurred, busy cleared, 
	constant STATUS_BIT_INIT : natural := 4;		-- card was successfully initialized
	constant STATUS_BIT_UNUSED1 : natural := 5;
	constant STATUS_BIT_UNUSED2 : natural := 6;
	constant STATUS_BIT_SDHC : natural := 7;		-- card is SDHC card
	
end SDStatusBits;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SDStatusBits.ALL;

entity SDCardController is
generic
(
	-- Thse parameters should be set so the supplied i_clock can 
	-- be divided down to provide a frequency that doesn't exceed
	-- 800Khz and 50Mhz.  These clocks are used to drive the SD
	-- card at 25Mhz and 400Khz respectively
	-- eg: for a 100Mhz i_clock, these would be set to 125 and 2
	p_clock_div_800khz : integer;
	p_clock_div_50mhz : integer
);
port 
(
	-- Clocking
	i_reset : in std_logic;
	i_clock : in std_logic;

	-- SD Card Signals
	o_ss_n : out std_logic;
	o_mosi : out std_logic;
	i_miso : in std_logic;
	o_sclk : out std_logic;

	-- o_status signals
	o_status : out std_logic_vector(7 downto 0) := (others => '1');
	o_last_block_number : out std_logic_vector(31 downto 0);

	-- Operation
	i_op_write : in std_logic;
	i_op_cmd : in std_logic_vector(1 downto 0);
	i_op_block_number : in std_logic_vector(31 downto 0);

	-- Data in/out
	o_data_start : out std_logic;
	o_data_cycle : out std_logic;
	i_data : in std_logic_vector(7 downto 0);
	o_data : out std_logic_vector(7 downto 0)
);
end SDCardController;

architecture Behavioral of SDCardController is

	type states is 
	(
		RST,
		DESELECT,				-- deselect the card and pulse i_clock
		PULSE_SCLK,
		SEND_CMD0,
		RECV_CMD0,
		SEND_CMD8,
		RECV_CMD8,
		RECV_CMD8_DATA,
		SEND_CMD55,
		RECV_CMD55,
		SEND_CMD41,
		POLL_CMD41,
		SEND_CMD58,
		RECV_CMD58,
		RECV_CMD58_DATA,
		SEND_CMD16,
		RECV_CMD16,
	  
		IDLE,					-- wait for i_op_cmd
		SEND_CMD17,
		RECV_CMD17,
		READ_BLOCK_WAIT,
		WRITE_DMA,
		READ_BLOCK_DATA,

		SEND_CMD24,
		RECV_CMD24,
		WRITE_BLOCK_DATA,		-- loop through all data bytes
		WAIT_WRITE_DATA_RESPONSE,		-- wait until not busy
		CHECK_WRITE_RESPONSE,
		WAIT_WRITE_DATA_FINISHED,

		TX_CMD,
		TX_DATA,
		TX_BITS,
		WAIT_CMD_RESPONSE,
		RX_BITS,
		RX_BITS_FINISHED,
		ERROR

	);



	-- one start byte, plus 512 bytes of data, plus two FF end bytes (CRC)
	constant c_write_data_size : integer := 515;

	signal op_wr_prev : std_logic;

	signal state : states := RST;
	signal return_state : states;
	signal sclk_sig : std_logic := '0';
	signal tx_buf : std_logic_vector(55 downto 0);
	signal rx_buf : std_logic_vector(31 downto 0);
	signal in_tx_cmd : std_logic := '1';
	signal do_deselect : std_logic := '1';

	signal clock_div_limit : unsigned(7 downto 0);
	signal clock_div, clock_div_next : unsigned(7 downto 0);
	signal clock_en : std_logic;

	signal din_used : std_logic;
	signal s_block_number : std_logic_vector(31 downto 0);
	signal cmd_address : std_logic_vector(31 downto 0);

	signal sdhc : std_logic;

begin
  	
	clock_en <= '1' when clock_div = (clock_div_limit-1) else '0';
	clock_div_next <= (others=>'0') when clock_en='1' else clock_div + 1;

	o_last_block_number <= s_block_number;

	cmd_address <= s_block_number(31 downto 0) 
					when sdhc='1' else
					s_block_number(22 downto 0) & "000000000";

	o_sclk <= sclk_sig;

	process(i_clock)
	begin
		if rising_edge(i_clock) then
		if i_reset = '1' then
			clock_div <= (others=>'0');
		else
			clock_div <= clock_div_next;
		end if;
		end if;
	end process;

	o_data <= rx_buf(7 downto 0);
	o_data_cycle <= '1' when state = WRITE_DMA or din_used='1' else '0';


	process(i_clock)
		variable byte_counter : integer range 0 to c_write_data_size;
		variable bit_counter : integer range 0 to 160;
	begin

		if rising_edge(i_clock) then
		if i_reset='1' then
		
 			state <= RST;
			sclk_sig <= '0';

			op_wr_prev <= '0';

			do_deselect <= '0';
			din_used <= '0';
			o_data_start <= '0';

			o_status <= (others => '1');			
			s_block_number(31 downto 0) <= x"FFFFFFFF";

		else

			op_wr_prev <= i_op_write;

			din_used <= '0';
			o_data_start <= '0';

			-- i_reset?
			if op_wr_prev = '0' and i_op_write = '1' and i_op_cmd="00" then
				state <= RST;
			end if;

			case state is

				when RST =>
					clock_div_limit <= to_unsigned(p_clock_div_800khz, 8);
					tx_buf <= (others => '1');
					byte_counter := 0;
					o_status <= "00000" & STATUS_LO_BUSY;
					sdhc <= '0';

					-- setup for initial i_clock pulse
					-- o_ss_n=1, o_mosi=1, pulse clocks, o_ss_n=0
					bit_counter := 160;
					state <= DESELECT;
					return_state <= SEND_CMD0;

				when DESELECT =>
					if clock_en='1' then
						o_ss_n <= '1';
						o_mosi <= '1';
						sclk_sig <= '0';
						do_deselect <= '0';
						state <= PULSE_SCLK;
					end if;

				when PULSE_SCLK =>		
					-- pulse i_clock bit_counter times then return to return_state		
					-- enter with sclk_sig at 0
					-- bit_counter:    : 2 2 1 1 ret
					-- sclk_sig:       : 0 1 0 1 0
					if clock_en='1' then
						if sclk_sig = '1' then
							if bit_counter = 1 then
								state <= return_state;
							else
								bit_counter := bit_counter - 1;
							end if;	
						end if;
						sclk_sig <= not sclk_sig;
					end if;


				when SEND_CMD0 =>
					tx_buf <= x"FF400000000095";
					state <= TX_CMD;
					do_deselect <= '1';
					byte_counter := 512;	-- Number of times to retry ACMD41
					return_state <= RECV_CMD0;

				when RECV_CMD0 =>
					-- just idle bit 0x01 should be set
					if rx_buf(7 downto 0) = "00000001" then 	
						state <= SEND_CMD8;
					else
						state <= ERROR;
					end if;

				when SEND_CMD8 => 
					tx_buf <= x"FF48000001aa87";
					state <= TX_CMD;
					do_deselect <= '0';
					return_state <= RECV_CMD8;

				when RECV_CMD8 =>
					if rx_buf(7 downto 1) = "0000000" then	-- ignore idle bit
						state <= RX_BITS;
						bit_counter := 32;
						return_state <= RECV_CMD8_DATA;
						do_deselect <= '1';
					else
						-- CMD8 not accepted so not a SDHC
						-- continue in SD v1 mode
						bit_counter := 2;
						state <= DESELECT;
						return_state <= SEND_CMD55;
					end if;

				when RECV_CMD8_DATA =>
					if rx_buf(11 downto 0) = x"1AA" then
						-- Looks like SDHC
						sdhc <= '1';
						state <= SEND_CMD55;
					else
						-- Reject card
						state <= ERROR;
					end if;


				when SEND_CMD55 =>
					tx_buf <= x"FF770000000001";	-- 55d OR 40h = 77h
					do_deselect <= '1';
					return_state <= RECV_CMD55;
					state <= TX_CMD;

				when RECV_CMD55 =>
					if rx_buf(7 downto 1) = "0000000" then	-- ignore idle bit
						state <= SEND_CMD41;
					else
						state <= ERROR;
					end if;

				when SEND_CMD41 =>
					tx_buf <= x"FF69" & "0" & sdhc & "00" & x"000000001";	-- 41d OR 40h = 69h
					do_deselect <= '1';
					return_state <= POLL_CMD41;
					state <= TX_CMD;
			
				when POLL_CMD41 =>
					if rx_buf(0) = '0' then
						if sdhc = '1' then
							state <= SEND_CMD58;
						else
							state <= SEND_CMD16;
						end if;
					else
						state <= SEND_CMD55;
						byte_counter := byte_counter-1;
						if byte_counter=1 then
							state <= RST;		-- Restart the whole process
						end if;
					end if;

				when SEND_CMD58 =>
					tx_buf <= x"FF7A0000000001";	-- 58d OR 40h = 7Ah
					return_state <= RECV_CMD58;
					do_deselect <= '0';
					state <= TX_CMD;

				when RECV_CMD58 =>
					if rx_buf(7 downto 1) = "0000000" then	-- ignore idle bit
						do_deselect <= '1';
						bit_counter := 32;
						state <= RX_BITS;
						return_state <= RECV_CMD58_DATA;
					else
						-- CMD58 not accepted - bail
						state <= ERROR;
					end if;

				when RECV_CMD58_DATA =>
					if rx_buf(30)='1' then
						-- SDHC mode successfully initialized
						clock_div_limit <= to_unsigned(p_clock_div_50mhz, 8);
						state <= IDLE;
					else
						-- SDHC but not in block addressing mode
						sdhc <= '0';
						state <= SEND_CMD16;
						do_deselect <= '1';
					end if;

				when SEND_CMD16 =>
					-- Set block size
					tx_buf <= x"FF500000020001";	-- 16d OR 40h = 50h
					return_state <= RECV_CMD16;
					do_deselect <= '1';
					state <= TX_CMD;

				when RECV_CMD16 =>
					if rx_buf(7 downto 1) = "0000000" then	-- ignore idle bit
						clock_div_limit <= to_unsigned(p_clock_div_50mhz, 8);
						state <= IDLE;
					else
						state <= ERROR;
					end if;


				when IDLE =>
					o_status(2 downto 0) <= STATUS_LO_READY;
					o_status(STATUS_BIT_INIT) <= '1';
					o_status(STATUS_BIT_SDHC) <= sdhc;
					if op_wr_prev = '0' and i_op_write = '1' then

						case i_op_cmd is

							when "01" =>		-- read
								state <= SEND_CMD17;
								s_block_number <= i_op_block_number;
								o_data_start <= '1';

							when "10" =>		-- write
								state <= SEND_CMD24;
								s_block_number <= i_op_block_number;
								o_data_start <= '1';

							when others =>		-- read CSD
								state <= IDLE;

						end case;
					end if;


				when SEND_CMD17 =>
					o_status(2 downto 0) <= STATUS_LO_READING;
					tx_buf <= x"FF" & x"51" & cmd_address & x"FF";
					state <= TX_CMD;
					do_deselect <= '0';
					return_state <= RECV_CMD17;
				
				when RECV_CMD17 =>
					-- Check response from read command
					if rx_buf(7 downto 1) = "0000000" then	-- ignore idle bit

						-- Read bytes until we get non-FF response
						bit_counter := 8;
						state <= RX_BITS;
						return_state <= READ_BLOCK_WAIT;

					else
						state <= ERROR;
					end if;

				when READ_BLOCK_WAIT =>
					if rx_buf(7 downto 0) = x"FF" then

						-- Keep waiting
						bit_counter := 8;
						state <= RX_BITS;
						return_state <= READ_BLOCK_WAIT;
					
					elsif rx_buf(7 downto 0) = x"FE" then

						-- Data ready token received - start the transfer
						byte_counter := 512;
						bit_counter := 8;
						state <= RX_BITS;
						return_state <= WRITE_DMA;

					else

						-- Bad token - quit
						state <= ERROR;

					end if;

				when READ_BLOCK_DATA =>
					if byte_counter = 1 then

						-- last byte received, read and discard 2x CRC bytes
						bit_counter := 16;
						state <= RX_BITS;
						do_deselect <= '1';
						return_state <= IDLE;
					
					else

						-- decrement byte counter and read another byte
						byte_counter := byte_counter - 1;
						bit_counter := 8;
						state <= RX_BITS;
						return_state <= WRITE_DMA;

					end if;
			
				when WRITE_DMA =>
					state <= READ_BLOCK_DATA;

				when SEND_CMD24 =>
					o_status(2 downto 0) <= STATUS_LO_WRITING;
					byte_counter := 512; 
					tx_buf <= x"FF" & x"58" & cmd_address & x"FF";	-- single block
					state <= TX_CMD;
					return_state <= RECV_CMD24;
					
				when RECV_CMD24 => 
					if rx_buf(7 downto 1) = "0000000" then

						-- Write command accepted.
						-- Send the data packet header bytes
						tx_buf(55 downto 40) <= x"FFFE"; -- 1 nop byte (FF), 1 start token (FE)
						bit_counter := 16;
						state <= TX_DATA;
						return_state <= WRITE_BLOCK_DATA;

					else
						state <= ERROR;
					end if;
					
				when WRITE_BLOCK_DATA => 
					if byte_counter = 0 then
						-- Send the fake CRC
						tx_buf(55 downto 40) <= x"FFFF";
						bit_counter := 16;
						state <= TX_DATA;
						return_state <= WAIT_WRITE_DATA_RESPONSE;
					else 	
						-- Send data byte
						bit_counter := 8;
						tx_buf(55 downto 48) <= i_data;
						state <= TX_DATA;
						return_state <= WRITE_BLOCK_DATA;
						byte_counter := byte_counter - 1;
						din_used <= '1';
					end if;

				when WAIT_WRITE_DATA_RESPONSE =>
					if clock_en='1' then
						if sclk_sig = '1' and i_miso = '0' then
							rx_buf(0) <= '0';
							bit_counter := 4;
							state <= RX_BITS;
							return_state <= CHECK_WRITE_RESPONSE;
						end if;
						sclk_sig <= not sclk_sig;
					end if;

				when CHECK_WRITE_RESPONSE =>
					if rx_buf(4 downto 0) = "00101" then
						state <= WAIT_WRITE_DATA_FINISHED;
					else
						state <= ERROR;
					end if;

				when WAIT_WRITE_DATA_FINISHED =>
					if clock_en='1' then
						if sclk_sig = '1' and i_miso = '1' then
							bit_counter := 2;
							state <= DESELECT;
							return_state <= IDLE;
						end if;
						sclk_sig <= not sclk_sig;
					end if;


				when TX_CMD =>
					in_tx_cmd <= '1';
					sclk_sig <= '0';
					o_ss_n <= '0';
					o_mosi <= tx_buf(55);
					tx_buf <= tx_buf(54 downto 0) & '1';
					bit_counter := 56;
					state <= TX_BITS;

				when TX_DATA => 
					in_tx_cmd <= '0';
					sclk_sig <= '0';
					o_ss_n <= '0';
					o_mosi <= tx_buf(55);
					tx_buf <= tx_buf(54 downto 0) & '1';
					state <= TX_BITS;

				when TX_BITS =>
					-- Send bit_counter bits to SD Card
					-- Assumes o_mosi already set to first bit, o_sclk is lo
					-- and bit_counter - 1 bits left in tx_buf

					-- bit_counter  : 2 2 1 1 ret
					-- sclk_sig     : 0 1 0 1 0
					-- o_mosi         :*    * 
					if clock_en='1' then
						if sclk_sig = '1' then
							if bit_counter = 1 then
								if in_tx_cmd='1' then
									state <= WAIT_CMD_RESPONSE;
								else
									state <= return_state;
								end if;
							else
								bit_counter := bit_counter - 1;
								o_mosi <= tx_buf(55);
								tx_buf <= tx_buf(54 downto 0) & '1';
							end if;
						end if;
						sclk_sig <= not sclk_sig;
					end if;
				
				when WAIT_CMD_RESPONSE =>
					if clock_en='1' then
						if sclk_sig = '1' then
							if i_miso = '0' then
								rx_buf(0) <= '0';
								bit_counter := 7; -- already read bit 7
								state <= RX_BITS;
							end if;
						end if;
						sclk_sig <= not sclk_sig;
					end if;

				when RX_BITS =>
					-- Receive bit_counter bits from SD card
					-- Bits are stored in rx_buf
					-- bit_counter  : 2 2 1 1 ret
					-- sclk_sig     : 0 1 0 1 0
					-- bit read     :     *   *
					if clock_en='1' then
						if sclk_sig = '1' then
							rx_buf <= rx_buf(30 downto 0) & i_miso;
							if bit_counter = 1 then
								state <= RX_BITS_FINISHED;
							else
								bit_counter := bit_counter - 1;
							end if;
						end if;
						sclk_sig <= not sclk_sig;
					end if;

				when RX_BITS_FINISHED =>
					if do_deselect='1' then
						bit_counter := 2;
						state <= DESELECT;
					else
						state <= return_state;
					end if;

				when others => 
					o_status(STATUS_BIT_ERROR) <= '1';
					o_status(STATUS_BIT_BUSY) <= '0';
			end case;
		end if;
		end if;
	end process;

end Behavioral;


