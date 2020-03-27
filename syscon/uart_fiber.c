#include "syscon.h"

char g_szUartBuf[32];
char g_szLineBuf[128];
uint8_t g_iLineBufPos = 0;

void cmd_push(uint8_t argc, const char** argv);
void cmd_reset(uint8_t argc, const char** argv);


typedef struct _CMD
{
    const char* pszCmd;
    void (*fn)(uint8_t, const char**);
} CMD;

CMD g_commands[] = {
    { "push", cmd_push },
    { "reset", cmd_reset },
    { NULL, NULL },
};

#define CHAR_ACK ((char)0x06)
#define CHAR_EOT ((char)0x04)
#define CHAR_NULL ((char)0x00)

void uart_write_char(char ch)
{
    uart_write(&ch, 1);
}


void on_uart_line()
{
    char* argv[4];
    uint8_t argc = 0;

    char* p = g_szLineBuf;
    while (*p)
    {
        if (*p == ' ' || *p == '\t')
        {
            p++;
        }
        else
        {
            if (argc < sizeof(argv) / sizeof(argv[0]))
            {
                argv[argc++] = p;
                while (*p != '\0' && *p != ' ' && *p != '\t')
                    p++;
                *p = '\0';
                p++;
            }
            else
            {
                uart_write_sz("!too many args\n");
                return;
            }
        }
    }

    if (argc == 0)
    {
        uart_write_char(CHAR_ACK);
        return;
    }

    // Find a command handler
    CMD* pCmd = g_commands;
    while (pCmd->pszCmd)
    {
        if (strcmp(pCmd->pszCmd, argv[0])==0)
        {
            pCmd->fn(argc, argv);
            return;
        }
        pCmd++;
    }

    uart_write_sz("!unknown command\n");
}

void uart_fiber_proc()
{
    uart_write_sz("uart_fiber_proc()\n");

    while (true)
    {
        uint8_t len = uart_read(g_szUartBuf, sizeof(g_szUartBuf));
        char* p = g_szUartBuf;
        bool bWasCR = false;
        while (len)
        {
            // Ignore \n after \r
            if (bWasCR && *p == '\n')
            {
                p++;
                len--;
                continue;
            }

            if (*p == '\r' || *p == '\n')
            {
                if (g_iLineBufPos < sizeof(g_szLineBuf))
                {
                    g_szLineBuf[g_iLineBufPos] = '\0';
                    on_uart_line();
                }
                else
                {
                    uart_write_sz("!Line too long\n");
                }

                g_iLineBufPos = 0;
            }
            else
            {
                if (g_iLineBufPos < sizeof(g_szLineBuf))
                {
                    g_szLineBuf[g_iLineBufPos++] = *p;
                }
            }

            bWasCR = *p == '\r';
            p++;
            len--;
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
    create_fiber(uart_fiber_proc, 1024);
}


uint8_t calculateChecksum(uint8_t* p, uint8_t length)
{
    uint8_t checksum = 0;
    for (uint8_t i=0; i<length; i++)
    {
        checksum += *p++;
    }
    return checksum;
}



void cmd_push(uint8_t argc, const char** argv)
{
    // Capture filename and size
    const char* pszFileName = argv[1];
    long size = atol(argv[2]);

    char buf[128];

    // Create a temp file
    FIL f;
    FRESULT err = f_open(&f, "0:/receive.tmp", FA_WRITE | FA_CREATE_ALWAYS);
    if (err)
    {
        uart_write_sz("!f_open\n");
        return;
    }

    // Read blocks
    long  received = 0;
    while (received < size)
    {
        // Read for data block
        uart_write_char(CHAR_ACK);

        // Read block length
        uint8_t blockSize;
        uart_read_wait(&blockSize, 1);

        // Read the data
        uart_read_wait(buf, blockSize);

        // Read the checksum
        uint8_t checksumSent;
        uart_read_wait(&checksumSent, 1);

        // Check it
        uint8_t checksumData = calculateChecksum(buf, blockSize);
        if (checksumData != checksumSent)
        {
            sprintf(g_szTemp, "!checksum:%2x!=%2x\n", (int)checksumSent, (int)checksumData);
            uart_write_sz(g_szTemp);
            f_close(&f);
            return;
        }

        // Write it to the file
        UINT unused;
        err = f_write(&f, buf, blockSize, &unused);
        if (err)
        {
            uart_write_sz("!f_write\n");
            f_close(&f);
            return;
        }

        // Update received count
        received += blockSize;
    }

    // Close the file
    f_close(&f);

    // Check size
    if (received != size)
    {
        uart_write_sz("!length mismatch\n");
        return;
    }

    // Ack the last block
    uart_write_char(CHAR_ACK);

    // Read the eot
    char chEot;
    uart_read_wait(&chEot, 1);

    if (chEot != CHAR_EOT)
    {
        uart_write_sz("!expected eot\n");
        return;
    }

    // Replace file
    f_unlink(pszFileName);
    err = f_rename("0:\\receive.tmp", pszFileName);
    if (err)
    {
        sprintf(g_szTemp, "!f_rename(\"%s\")=%i\n", pszFileName, err);
        uart_write_sz(g_szTemp);
        return;
    }

    // Ack the EOT
    uart_write_char(CHAR_ACK);
}

void cmd_reset(uint8_t argc, const char** argv)
{
    ApmEnable = APM_ENABLE_RESET;
}
