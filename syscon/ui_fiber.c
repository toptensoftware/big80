#include "syscon.h"

// Main UI Fiber
void ui_fiber_proc()
{
    uart_write_sz("ui_fiber_proc\n");

    video_clear();

    // Run the main menu
    main_menu();
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


void ui_fiber_init()
{
    // Hook the default window proces to capture
    // F12 key presses to enter/exit syscon menus from
    // anywhere    
    window_set_hook(window_proc_hook);

    // Create the main UI Fiber
    create_fiber(ui_fiber_proc, 1024);
}