#include <libSysCon.h>
#include <ff.h>
#include <diskio.h>
#include <stdio.h>

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
	return RES_PARERR;
}

DRESULT disk_ioctl (BYTE pdrv, BYTE cmd, void* buff)
{
	return RES_PARERR;
}

int ff_cre_syncobj (	/* 1:Function succeeded, 0:Could not create the sync object */
	BYTE vol,			/* Corresponding volume (logical drive number) */
	FF_SYNC_t* sobj		/* Pointer to return the created sync object */
)
{
    return 1;
}


int ff_del_syncobj(FF_SYNC_t sobj)
{
    // nop
    return 1;
}

int ff_req_grant(FF_SYNC_t sobj)
{
    return 1;
}

void ff_rel_grant (FF_SYNC_t sobj)
{
}

