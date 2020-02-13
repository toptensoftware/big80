#include <stdio.h>
#include <stdbool.h>
#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>

void uart_interrupts();
void uart_init();


char g_szTemp[128];
FATFS g_fs;

// Required by crt0 to set top of stack on entry
__at(0xFC00) char top_of_stack[];

// Main Entry Point
void main(void) 
{
    // Hello!
    uart_write_sz("...landed in big80.sys!\n");

    // Mount SD Card
    uart_write_sz("Mounting SD card...");
    FRESULT r = f_mount(&g_fs, "0", 1);
    if (r != 0)
    {
        sprintf(g_szTemp, " FAILED (%i)\n", r);
        uart_write_sz(g_szTemp);
        return;
    }
    uart_write_sz(" OK\n");

    // Open big80.sys
    FIL f;
    uart_write_sz("Opening level2-a.rom...");
    r = f_open(&f, "0:/level2-a.rom", FA_OPEN_EXISTING | FA_READ);
    if (r != 0)
    {
        sprintf(g_szTemp, " FAILED (%i)\n", r);
        uart_write_sz(g_szTemp);
        return;
    }
    uart_write_sz(" OK\n");

    // Map page bank to trs80 ram area (bank 0)
    ApmEnable = APM_ENABLE_PAGEBANK;
    ApmPageBank = 0;
    uint16_t totalBytes = 0;
    while (1)
    {
        UINT bytes_read = 0;
        f_read(&f, (BYTE*)banked_page, sizeof(banked_page), &bytes_read);
        totalBytes += bytes_read;
        ApmPageBank++;
        if (bytes_read != sizeof(banked_page))
            break;
    }
    f_close(&f);
    ApmEnable = 0;   

    sprintf(g_szTemp, "level2-a.rom loaded (%u bytes).\n", totalBytes);
    uart_write_sz(g_szTemp);
    uart_write_sz("Starting interrupt loop\n");

    uart_init();

    // Main processing loop
    while (true)
    {
        // Run all active fibers
        run_fibers();

        // Yield
        yield_from_nmi();

        // Process all interrupts
        uart_read_isr();
        uart_write_isr();
    }

/*
    // Setup yield proc to return external machine and wake again on NMI
    yield = YieldNmiProc;

    // Run our infinite echo loop
    while (true)
    {
        uint8_t len = uart_read(g_szTemp, sizeof(g_szTemp));
        if (len)
        {
            uart_write_sz("R:");
            uart_write(g_szTemp, len);
        }
    }
*/
}


