#include <libSysCon.h>

char g_szUartBuf[32];

void uart_fiber_proc()
{
    // UART Echo
    while (true)
    {
        uint8_t len = uart_read(g_szUartBuf, sizeof(g_szUartBuf));
        if (len)
        {
            uart_write_sz("R:");
            uart_write(g_szUartBuf, len);
        }
    }
}

// Initialize uart fiber and signals
void uart_init()
{
    // Initialize interrupt service routines
    uart_read_init_isr();
    uart_write_init_isr();

    // Start fiber
    create_fiber(uart_fiber_proc, 512);
}

