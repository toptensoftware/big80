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
        sd_read(sector++, buff);
        buff += 512;
        count--;
    }

	return 0;
}

DRESULT disk_write (BYTE pdrv, const BYTE* buff, LBA_t sector, UINT count)
{
    while (count)
    {
        sd_write(sector++, buff);
        buff += 512;
        count--;
    }
	return 0;
}

DRESULT disk_ioctl (BYTE pdrv, BYTE cmd, void* buff)
{
	return RES_PARERR;
}

