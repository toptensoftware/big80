#include "syscon.h"

#define CONFIG_SIGNATURE 0xb180
#define CONFIG_VERSION	1

typedef struct tagCONFIG
{
	uint16_t signature;
	uint8_t version;
	uint8_t options;
} CONFIG;

void config_load()
{
	// Open config file
    FIL* pf = (FIL*)malloc(sizeof(FIL));
    int r = f_open(pf, "0:/big80.cfg", FA_OPEN_EXISTING | FA_READ);
	if (r)
	{
		free(pf);
		return;
	}

	// Read header
	UINT bytes_read = 0;
	CONFIG cfg;
	f_read(pf, (BYTE*)&cfg, sizeof(cfg), &bytes_read);

	// Check signature
	if (cfg.signature != CONFIG_SIGNATURE)
		goto exit;

	// Load FPGA options
	if (cfg.version >= 1)
	{
		OptionsPort = cfg.options;
	}

exit:
	f_close(pf);
	free(pf);
}

void config_save()
{
	// Open config file
    FIL* pf;
	pf = (FIL*)malloc(sizeof(FIL));
    int r = f_open(pf, "0:/big80.cfg", FA_CREATE_ALWAYS | FA_WRITE);
	if (r)
	{
		free(pf);
		return;
	}

	// Read header
	UINT bytes_written = 0;
	CONFIG cfg;
	cfg.signature = CONFIG_SIGNATURE;
	cfg.version = CONFIG_VERSION;
	cfg.options = OptionsPort;
	f_write(pf, (BYTE*)&cfg, sizeof(cfg), &bytes_written);

	// Done
	f_close(pf);
	free(pf);
}