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

extern char g_szTemp[];

DRESULT disk_read (BYTE pdrv, BYTE* buff, LBA_t sector, UINT count)
{
//    sprintf(g_szTemp, "disk_read(%i)\n", (int)sector);
//    uart_write_sz(g_szTemp);

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
//    sprintf(g_szTemp, "disk_write(%i)\n", (int)sector);
//    uart_write_sz(g_szTemp);

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
	return 0;
}

// only one drive, so only one mutex needed
MUTEX g_mutexSync;

int ff_cre_syncobj (	/* 1:Function succeeded, 0:Could not create the sync object */
	BYTE vol,			/* Corresponding volume (logical drive number) */
	FF_SYNC_t* sobj		/* Pointer to return the created sync object */
)
{
    init_mutex(&g_mutexSync);
    *sobj = (FF_SYNC_t*)&g_mutexSync;
    return 1;
}


int ff_del_syncobj(FF_SYNC_t sobj)
{
    // nop
    return 1;
}

int ff_req_grant(FF_SYNC_t sobj)
{
    // If haven't started fibers yet, don't need locks
    if (get_current_fiber() == NULL)
        return 1;

    enter_mutex((MUTEX*)sobj);
    return 1;
}

void ff_rel_grant (FF_SYNC_t sobj)
{
    // If haven't started fibers yet, don't need locks
    if (get_current_fiber() == NULL)
        return;

    leave_mutex((MUTEX*)sobj);
}

