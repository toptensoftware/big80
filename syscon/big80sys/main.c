#include "ff.h"

// Main Entry Point
void main(void) 
{
	FATFS fs;
	f_mount(&fs, "0", 1);

	FIL f;
	f_open(&f, "0:/big80.sys", FA_OPEN_EXISTING);
	
	UINT t;
	f_read(&f, 0, 0, &t);
	f_close(&f);
}

