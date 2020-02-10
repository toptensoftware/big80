#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>
#include <stdio.h>

char g_szTemp[128];
FATFS g_fs;

void thunkStart();

// NMI handler is a no-op while booting
void nmi_handler() __naked
{
    __asm
    retn
    __endasm;
}

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
    r = f_open(&f, "0:/level2-a.sys", FA_OPEN_EXISTING | FA_READ);
    if (r != 0)
    {
        sprintf(g_szTemp, " FAILED (%i)\n", r);
        uart_write_sz(g_szTemp);
        return;
    }
    uart_write_sz(" OK\n");

    // Map our hi-address range (0x8000-0xFFFF) to the RAM that will be used for the
    // TRS80's 0x0000->0x7FFF address range and read the TRS-80 ROM image from SD Card
    ApmHiBankPage = 0x00;
    UINT bytes_read = 0;
    f_read(&f, (BYTE*)0x8000, f_size(&f), &bytes_read);
    f_close(&f);
    ApmHiBankPage = 0x03;       

    sprintf(g_szTemp, "big-80.sys loaded (%lu bytes).\n", (int)(bytes_read));
    uart_write_sz(g_szTemp);

    uart_write_sz("Jumping to TRS-80 ROM...");

    // Request exit hijack mode and jump to TRS80 ROM start (0x0000)
    __asm
    ld      a,#ICFLAG_EXIT_HIJACK_MODE
    out     (_InterruptControllerPort),a
    ld      HL, #0
    jp      (HL)
    __endasm;
}
