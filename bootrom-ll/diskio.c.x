#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>

DSTATUS disk_initialize (BYTE pdrv)
{
    // Wait for it init
    while (SdStatusPort & SD_STATUS_BUSY)
        ;

    return (SdStatusPort & SD_STATUS_INIT) ? 0 : STA_NODISK;
}

DSTATUS disk_status (BYTE pdrv)
{
    return (SdStatusPort & SD_STATUS_INIT) ? 0 : STA_NODISK;
}

DRESULT disk_read (BYTE pdrv, BYTE* buff, LBA_t sector, UINT count)
{
    while (count)
    {
        // Set block
        disk_set_block_number(sector++);

        // Invoke command
        SdCommandPort = SD_COMMAND_READ;

        // Wait for it
        while (SdStatusPort & SD_STATUS_BUSY)
            ;

        // Read it
        for (int i=0; i<512; i++)
        {
            *buff++ = SdDataPort;
        }

        count--;
    }

	return 0;
}

DRESULT disk_write (BYTE pdrv, const BYTE* buff, LBA_t sector, UINT count)
{
    while (count)
    {
        // Set block
        disk_set_block_number(sector++);

        // Read it
        for (int i=0; i<512; i++)
        {
            SdDataPort = *buff++;
        }

        // Invoke command
        SdCommandPort = SD_COMMAND_WRITE;

        // Wait for it
        while (SdStatusPort & SD_STATUS_BUSY)
            ;

        count--;
    }

	return 0;
}

DRESULT disk_ioctl (BYTE pdrv, BYTE cmd, void* buff)
{
	return RES_PARERR;
}

