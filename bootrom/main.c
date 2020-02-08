#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>
#include <stdio.h>

char buf[128];

FATFS g_fs;

// Main Entry Point
void main(void) 
{
    // Hello!
    uart_write_sz("Hello world from Big80\n");

    FRESULT r = f_mount(&g_fs, "0", 1);
//    sprintf(buf, "f_mount returned %i\n", r);
//    uart_write_sz(buf);

    DIR d;
    r = f_opendir (&d, "0:/");
//    sprintf(buf, "f_opendir returned %i\n", r);
//    uart_write_sz(buf);

    while (1)
    {
        FILINFO fno;
        r = f_readdir(&d, &fno);
//        sprintf(buf, "f_readdir returned %i\n", r);
//        uart_write_sz(buf);
        if (!fno.fname[0])
            break;


        sprintf(buf, "%5i %s\n", (int)fno.fsize, fno.fname);
        uart_write_sz(buf);
    }

    f_closedir(&d);

/*
    FIL f;
    f_open(&f, "0:/big80.sys", FA_CREATE_NEW);
    f_close(&f);
    f_lseek(&f, 0);
    f_read(&f, 0, 0, 0);
    f_write(&f, 0, 0, 0);
    f_unlink("");
    f_rename("","");
    f_mkdir("");    
    */


/*
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
                // Invoke command
                SdCommandPort = SD_COMMAND_READ;

                // Wait for it
                while (SdStatusPort & SD_STATUS_BUSY)
                    ;

                // Dump it
                sprintf(buf, "\nBlock %4x", (int)block_number);
                uart_write_sz(buf);
                for (int i=0; i<512; i++)
                {
                    if ((i % 16) == 0)
                        uart_write_sz("\n");
                    sprintf(buf, "%2x ", (int)SdDataPort);
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
                    SdDataPort = (uint8_t)(start_fill_byte + i);
                }

                SdCommandPort = SD_COMMAND_WRITE;

                // Wait for it
                while (SdStatusPort & SD_STATUS_BUSY)
                    ;

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
*/
}

