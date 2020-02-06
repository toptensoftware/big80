#include <libSysCon.h>
#include <stdio.h>

char buf[128];

uint32_t block_number = 0;

void show_sd_status()
{
    sprintf(buf, "status: %x\n", (int)SdStatusPort);
    uart_write_sz(buf);
}

void set_block_number(uint32_t val)
{
    SdSetBlockNumberPort = val & 0xFF;
    SdSetBlockNumberPort = (val >> 8) & 0xFF;
    SdSetBlockNumberPort = (val >> 16) & 0xFF;
    SdSetBlockNumberPort = (val >> 24) & 0xFF;
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
                SdCommandPort = SD_COMMAND_READ;
                show_sd_status();
            }

            if (buf[0] == 'w')
            {
                SdCommandPort = SD_COMMAND_WRITE;
                show_sd_status();
            }

            if (buf[0] == 's')
            {
                show_sd_status();
            }

            if (buf[0] == 'n')
            {
                set_block_number(++block_number);
            }
            if (buf[0] == 's')
            {
                set_block_number(--block_number);
            }
        }

        // Write it back
        //uart_write(buf, recv);
    }
}

