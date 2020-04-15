#include "syscon.h"
#include <string.h>

SIGNAL g_sig_cassette;

// From libFatFS
FRESULT f_current_sector(FIL* fp, LBA_t* psector);
FRESULT f_create_sector(FIL* fp, LBA_t* psector);

// The file for playback
const char* g_pszCasFile = NULL;
const char* g_pszCasSaveFile = NULL;

// Cassette operation status
static FIL* pFile = NULL;
static bool bIsRecording = false;
static bool g_bStopNextBlock = false;
static FSIZE_t pos = 0;

void cas_set_block_number(uint32_t blockNumber) __naked
{
__asm
		ld	hl, #2
		add hl,sp

        ; B = length (4 bytes)
        ; C = port number
		ld	bc,#0x0400 + CASSETTE_DATA_PORT
		otir
		ret
__endasm;
}

// Handle IRQs
void handle_irq()
{
    if (pFile != NULL)
    {
        // Operation stopped?  Close the file
        if ((CassetteCmdStatusPort & (CASSETTE_STATUS_PLAYING|CASSETTE_STATUS_RECORDING)) == 0)
        {
            if (bIsRecording)
            {
                // Seek past last block to set file size
                f_lseek(pFile, pos);
            }

            f_close(pFile);
            free(pFile);
            pFile = NULL;
            bIsRecording = false;
            return;
        }
    }
    else 
    {
        // Start playback/record?
        const char* pszFileToOpen = NULL;
        BYTE bMode = 0;
        if (CassetteCmdStatusPort & CASSETTE_STATUS_PLAYING)
        {
            // Check a file is selected
            if (g_pszCasFile == NULL)
            {
                // If not, stop the operation
                CassetteCmdStatusPort = CASSETTE_COMMAND_STOP;
                return;
            }

            pszFileToOpen = g_pszCasFile;
            bMode = FA_OPEN_EXISTING | FA_READ;
        }
        else if (CassetteCmdStatusPort & CASSETTE_STATUS_RECORDING)
        {
            pszFileToOpen = "/RECORD.CAS";
            bMode = FA_CREATE_ALWAYS | FA_WRITE;
            bIsRecording = true;
        }


        // Open/create the file
        if (pszFileToOpen)
        {
            pFile = (FIL*)malloc(sizeof(FIL));
            pos = 0;
            if (f_open(pFile, pszFileToOpen, bMode))
            {
                CassetteCmdStatusPort = CASSETTE_COMMAND_STOP;
                free(pFile);
                pFile = NULL;
                return;
            }
        }

        g_bStopNextBlock = false;
    }

    if (!pFile)
        return;

    // Need a block number?
    if (CassetteCmdStatusPort & CASSETTE_STATUS_NEED_BLOCK)
    {
        // Stop after EOF?
        if (g_bStopNextBlock)
        {
            g_bStopNextBlock = false;
            CassetteCmdStatusPort = CASSETTE_COMMAND_STOP;
            return;
        }

        // Check for attempt to play past end of file?
        if (!bIsRecording && pos >= pFile->obj.objsize)
        {
            // We're past the end of the file, but need to wait
            // for the current block to finish rendering.  Just
            // load the same sector again (coult be anything, don't
            // care), but set a flag to stop playback on the next
            // block request
            CassetteCmdStatusPort = CASSETTE_COMMAND_LOAD_BLOCK;
            g_bStopNextBlock = true;
            return;
        }


        // Seek to the next position
        if (f_lseek(pFile, pos) != FR_OK)
        {
            CassetteCmdStatusPort = CASSETTE_COMMAND_STOP;
            return;
        }

        LBA_t sector;
        if (bIsRecording)
            f_create_sector(pFile, &sector);
        else
            f_current_sector(pFile, &sector);

/*
        sprintf(g_szTemp, "pos:%i block:%i\n", 
                (int)pos, 
                (int)sector,
                (int)pFile->obj.objsize
                );
        uart_write_sz(g_szTemp);
*/
        // Load it
        cas_set_block_number(sector);
        CassetteCmdStatusPort = CASSETTE_COMMAND_LOAD_BLOCK;

        // Move forward for next block
        pos += 512;
    }
}

void cassette_fiber_proc()
{
    uart_write_sz("cassette_fiber_proc()\n");

    while (true)
    {
        // Wait for signal
        wait_signal(&g_sig_cassette);

        // Handle it
        handle_irq();
    }
}


void cassette_fiber_init()
{
    init_signal(&g_sig_cassette);
    create_fiber(cassette_fiber_proc, 1024);
}

void cassette_isr()
{
    if (InterruptControllerPort & IRQ_CASSETTE)
        set_signal(&g_sig_cassette);
}