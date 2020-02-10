#include <libSysCon.h>
#include <stdio.h>

char buf[128];

uint8_t dbuf[512];

uint32_t block_number = 0;
uint8_t start_fill_byte = 0;

void show_sd_status()
{
    sprintf(buf, "status: %x\n", (int)SdStatusPort);
    uart_write_sz(buf);
}

void set_block_number(uint32_t val)
{
    sprintf(buf, "block number: %4x\n", (int)val);
    uart_write_sz(buf);
}

void set_start_fill_byte(uint8_t val)
{
    sprintf(buf, "start fill with: %2x\n", val);
    uart_write_sz(buf);
}

// Main Entry Point
void main(void) 
{
    // Hello!
    uart_write_sz("Hello world from Big80\n");
    show_sd_status();

    // Echo
    while (1)
    {
        // Read serial
        uint8_t recv = uart_read(buf, sizeof(buf));

        if (recv > 0)
        {
            if (buf[0] == 'r')
            {
                // Invoke read command
                sd_read(block_number, dbuf);

                // Dump it
                sprintf(buf, "\nBlock %4x", (int)block_number);
                uart_write_sz(buf);
                for (int i=0; i<512; i++)
                {
                    if ((i % 16) == 0)
                        uart_write_sz("\n");
                    sprintf(buf, "%2x ", (int)dbuf[i]);
                    uart_write_sz(buf);
                }
                
                continue;
            }

            if (buf[0] == 'w')
            {
                // Reset buffer
                SdCommandPort = SD_COMMAND_NOP;

                // Fill buffer
                for (int i=0; i<512; i++)
                {
                    dbuf[i] = (char)(uint8_t)(start_fill_byte + i);
                }

                sd_write(block_number, dbuf);

                sprintf(buf, "Filled block %4x starting with value %2x", (int)block_number, (int)start_fill_byte);
                uart_write_sz(buf);
                continue;
            }

            if (buf[0] == 's')
            {
                show_sd_status();
                continue;
            }

            if (buf[0] == 'n')
            {
                set_block_number(++block_number);
                continue;
            }
            if (buf[0] == 'p')
            {
                set_block_number(--block_number);
                continue;
            }
            if (buf[0] == 'N')
            {
                set_start_fill_byte(++start_fill_byte);
                continue;
            }
            if (buf[0] == 'P')
            {
                set_start_fill_byte(--start_fill_byte);
                continue;
            }
        }
    }
}

