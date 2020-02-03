#include "ff.h"

WORD g_wHighPtr;

// Main Entry Point
void main(void) 
{
	// Mount file system
	FATFS fs;
	f_mount(&fs, "0", 1);

	// Open big80.sys
	FIL f;
	f_open(&f, "0:/big80.sys", FA_OPEN_EXISTING);
	
	// Write paged high memory
	g_wHighPtr = 0;
	BYTE* pDest = (BYTE*)0x8000;

	// Read big80.sys
	while (1)
	{
		// Read block
		UINT t;
		if (f_read(&f, pDest, 512, &t) != FR_OK || t != 512)
			break;

		// Update pointer, adjust paging if wrapped
		pDest+=512;
		if (pDest == 0)
		{
			g_wHighPtr++;
			pDest = (BYTE)0x8000;
		}
	}

	// Close
	f_close(&f);

	// Create a stub to fixup paging and jump to big80.sys

}

