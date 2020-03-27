#include "syscon.h"


char g_szTemp[128];

FATFS g_fs;

// Required by crt0 to set top of stack on entry
__at(0xFC00) char top_of_stack[];

// Forward declarations
void ui_fiber_proc();

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

    // Load config
    config_load();

    // Open big80.sys
    FIL* pf = (FIL*)malloc(sizeof(FIL));
    uart_write_sz("Opening level2-a.rom...");
    r = f_open(pf, "0:/level2-a.rom", FA_OPEN_EXISTING | FA_READ);
    if (r != 0)
    {
        free(pf);
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
        f_read(pf, (BYTE*)banked_page, sizeof(banked_page), &bytes_read);
        totalBytes += bytes_read;
        ApmPageBank++;
        if (bytes_read != sizeof(banked_page))
            break;
    }
    f_close(pf);
    free(pf);
    ApmEnable = 0;   

    sprintf(g_szTemp, "level2-a.rom loaded (%u bytes).\n", totalBytes);
    uart_write_sz(g_szTemp);

    uart_write_sz("Starting interrupt loop\n");

    uart_init();
    sd_init_isr();
    msg_init();

    // Create the main UI Fiber
    create_fiber(ui_fiber_proc, 1024);

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
        sd_isr();
        msg_isr();
    }

}

size_t window_proc_hook(WINDOW* pWindow, MSG* pMsg, bool* pbHandled)
{
    if (pMsg->message == MESSAGE_KEYDOWN)
    {
        // Toggle video overlay and all keys on/off...
        if (pMsg->param1 == KEY_F11 || pMsg->param1 == KEY_F12)
        {
            if (ApmEnable & APM_ENABLE_VIDEOSHOW)
            {
                ApmEnable &= ~(APM_ENABLE_VIDEOSHOW|APM_ENABLE_ALLKEYS);
            }
            else
            {
                ApmEnable |= (APM_ENABLE_VIDEOSHOW|APM_ENABLE_ALLKEYS);
            }
            *pbHandled = true;
        }
    }
    return 0;
}

// Main UI Fiber
void ui_fiber_proc()
{
    uart_write_sz("ui_fiber_proc\n");

    // Hook the default window proces to capture
    // F12 key presses to enter/exit syscon menus from
    // anywhere
    window_msg_hook = window_proc_hook;

    // Run the main menu
    main_menu();
}


