#include <libSysCon.h>
#include <stdio.h>

char buf[128];

// Main Entry Point
void main(void) 
{
    uart_write_sz("Hello world from Big80\n");

    // Echo
    while (1)
    {
        /*
        uint8_t bytesAvailable = UartRxStatusPort;
        if (bytesAvailable != 0)
        {
            uint8_t byte = UartRxDataPort;
            uint8_t newCount = UartRxStatusPort;
            sprintf(buf, "Received: %i (count = %i -> %i)\n", (int)byte, (int)bytesAvailable, (int)newCount);
            uart_write_sz(buf);
        }
        */
        uint8_t recv = uart_read(buf, sizeof(buf));
        if (recv)
        {
            uart_write(buf, recv);
        }
    }
}

