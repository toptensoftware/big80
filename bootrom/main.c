#include <stdio.h>
#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>

char g_szTemp[128];
FATFS g_fs;

void thunkStart();

typedef struct tagHEADER
{
    uint8_t bank;
    uint8_t size;
} HEADER;

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
        HEADER header;
        f_read(&f, &header, sizeof(HEADER), &bytes_read);

        if (bytes_read != sizeof(HEADER))
            break;

        sprintf(g_szTemp, "Bank at 0x%x size 0x%x... ", (int)header.bank, (int)header.size);
        uart_write_sz(g_szTemp);

        ApmPageBank1k = header.bank;

        for (uint8_t i=0; i<header.size; i++)
        {
            f_read(&f, (BYTE*)banked_page, sizeof(banked_page), &bytes_read);
            ApmPageBank1k++;
        }

        uart_write_sz("ok\n");
    }
    ApmEnable = APM_ENABLE_BOOTROM;
    f_close(&f);


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
