#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>
#include <stdio.h>

char buf[512];

FATFS g_fs;

// Main Entry Point
void main(void) 
{
    // Hello!
    uart_write_sz("Hello world from Big80\n");

    // Mount SD Card
    uart_write_sz("Mounting SD card...");
    FRESULT r = f_mount(&g_fs, "0", 1);
    if (r != 0)
    {
        sprintf(buf, " FAILED (%i)\n", r);
        uart_write_sz(buf);
        return;
    }
    uart_write_sz(" OK\n");

    FIL f;

    // Open ROM image
    uart_write_sz("Opening level2-a.rom...");
    r = f_open(&f, "0:/level2-a.rom", FA_OPEN_EXISTING | FA_READ);
    if (r != 0)
    {
        sprintf(buf, " FAILED (%i)\n", r);
        uart_write_sz(buf);
        return;
    }
    uart_write_sz(" OK\n");

    // Map our hi-address range (0x8000-0xFFFF) to the RAM that will be used for the
    // TRS80's 0x0000->0x7FFF address range and read the TRS-80 ROM image from SD Card
    ApmHiBankPage = 0x00;
    UINT bytes_read = 0;
    f_read(&f, (BYTE*)0x8000, f_size(&f), &bytes_read);
    f_close(&f);
    sprintf(buf, "ROM image loaded (%i bytes).\n", (int)(bytes_read));
    uart_write_sz(buf);
    ApmHiBankPage = 0x03;       

    // Request exit hijack mode and jump to TRS80 ROM start (0x0000)
    __asm
    ld      a,#ICFLAG_EXIT_HIJACK_MODE
    out     (_InterruptControllerPort),a
    ld      HL, #0
    jp      (HL)
    __endasm;
}
