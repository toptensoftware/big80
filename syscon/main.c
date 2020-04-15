#include "syscon.h"

// Main Entry Point
bool user_init() 
{
    // Load config
    config_load();

    // Open big80.sys
    FIL* pf = (FIL*)malloc(sizeof(FIL));
    uart_write_sz("Opening level2-a.rom...");
    FRESULT r = f_open(pf, "0:/level2-a.rom", FA_OPEN_EXISTING | FA_READ);
    if (r != 0)
    {
        free(pf);
        sprintf(g_szTemp, " FAILED (%i)\n", r);
        uart_write_sz(g_szTemp);
        return false;
    }
    uart_write_sz(" OK\n");

    // Map page bank to trs80 ram area (bank 0)
    ApmEnable |= APM_ENABLE_PAGEBANK_1K;
    ApmPageBank1k = 0;
    uint16_t totalBytes = 0;
    while (1)
    {
        UINT bytes_read = 0;
        f_read_no_marshal(pf, (BYTE*)banked_page, sizeof(banked_page), &bytes_read);
        totalBytes += bytes_read;
        ApmPageBank1k++;
        if (bytes_read != sizeof(banked_page))
            break;
    }
    f_close(pf);
    free(pf);
    ApmEnable = 0;   

    sprintf(g_szTemp, "level2-a.rom loaded (%u bytes).\n", totalBytes);
    uart_write_sz(g_szTemp);

    // Initialize fibers
    ui_fiber_init();
    cassette_fiber_init();
    uart_fiber_init();

    return true;
}

void user_isr()
{
    cassette_isr();
}


