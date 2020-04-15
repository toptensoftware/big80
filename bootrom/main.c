#include <stdio.h>
#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>

char g_szTemp[128];
FATFS g_fs;

void thunkStart();

// Main Entry Point
void main(void) 
{
    // Hello!
    uart_write_sz("\nHello world from Big80\n");

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
    uart_write_sz("Opening big80.sys...");
    r = f_open(&f, "0:/big80.sys", FA_OPEN_EXISTING | FA_READ);
    if (r != 0)
    {
        sprintf(g_szTemp, " FAILED (%i)\n", r);
        uart_write_sz(g_szTemp);
        return;
    }
    uart_write_sz(" OK\n");

    // Map page bank to the syscon memory (starting at bank 64 after trs80 64k address space)
    ApmEnable = APM_ENABLE_BOOTROM | APM_ENABLE_PAGEBANK_1K;
    ApmPageBank1k = 64;
    uint32_t totalBytes = 0;
    while (1)
    {
        UINT bytes_read = 0;
        FRESULT err = f_read(&f, (BYTE*)banked_page, sizeof(banked_page), &bytes_read);
        totalBytes += bytes_read;
        ApmPageBank1k++;
        if (bytes_read != sizeof(banked_page))
            break;
    }
    ApmEnable = APM_ENABLE_BOOTROM;
    f_close(&f);

    sprintf(g_szTemp, "big-80.sys loaded (%lu bytes).\n", totalBytes);
    uart_write_sz(g_szTemp);

    // Jump to big80.sys
    uart_write_sz("Jumping to big80.sys...\n");

    thunkStart();
}


void thunkStart()
{
	__asm

	; Copy the thunk routine to high memory
	ld		HL,#90$
	ld		DE,#0xFFF0
	ld		BC,#99$ - #90$
	ldir	

    ; Jump to thunk
    jp      0xFFF0

90$:
	; Kick out the bootrom firmware (ie: this code)
	ld		A,#0
	out		(_ApmEnable),A

    ; Jump to big80.sys entry point
    jp      0x0000
99$:
	__endasm;
}
