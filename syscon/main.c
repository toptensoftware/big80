#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>

void uart_interrupts();
void uart_init();
void ui_fiber_proc();


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
    sd_init_isr();
    msg_init();

    // Create the main UI Fiber
    create_fiber(ui_fiber_proc, 512);


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

// Main UI Fiber
void ui_fiber_proc()
{

    // Display blank screen
    video_clear();
    ApmEnable |= APM_ENABLE_VIDEOBANK;
    memset(video_color_ram, 0x4f, sizeof(video_color_ram));
    video_char_ram[0] = BOX_TL;
    video_char_ram[31] = BOX_TR;
    video_char_ram[0 + 15*32] = BOX_BL;
    video_char_ram[31 + 15*32] = BOX_BR;
    for (char i=1; i<31; i++)
    {
        video_char_ram[i] = BOX_H;
        video_char_ram[i+ 15*32] = BOX_H;
    }
    for (char i=1; i<15; i++)
    {
        video_char_ram[i * 32] = BOX_V;
        video_char_ram[i * 32 + 31] = BOX_V;
    }
    ApmEnable &= ~APM_ENABLE_VIDEOBANK;
    video_write_sz(10, 7, "Big80 SysCon", 0x4f);
    video_write_sz(10, 8, "Keyboard Test", 0x4f);
    ApmEnable |= APM_ENABLE_VIDEOSHOW;

    while (true)
    {
        // Get the next message
        MSG msg;
        msg_get(&msg);

        if (msg.message == MESSAGE_KEYDOWN)
        {
            // Toggle video overlay on/off
            if (msg.param1 == KEY_F11 || msg.param1 == KEY_F12)
            {
                ApmEnable ^= APM_ENABLE_VIDEOSHOW;
            }
        }
    }
}


