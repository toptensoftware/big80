#include "syscon.h"

#define CONFIG_SIGNATURE 0xb180
#define CONFIG_VERSION	3

typedef struct tagCONFIG
{
	uint16_t signature;
	uint8_t version;
	uint8_t options;
} CONFIG;

int f_write_str(FIL* pf, const char* psz)
{
	uint8_t len = psz ? strlen(psz) : 0;
	UINT bytes_written = 0;
	f_write(pf, &len, 1, &bytes_written);
	if (len > 0)
	{
		f_write(pf, psz, len, &bytes_written);
	}
	return 0;
}

const char* f_read_str(FIL* pf)
{
	uint8_t len;
	UINT bytes_read;
	if (f_read(pf, &len, 1, &bytes_read) != 0)
		return NULL;

	char* psz = malloc(len + 1);
	f_read(pf, psz, len, &bytes_read);
	psz[len] = '\0';
	return psz;
}

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

	if (cfg.version >= 2)
	{
		g_pszCasFile = f_read_str(pf);
	}

	if (cfg.version >= 3)
	{
		g_pszCasSaveFile = f_read_str(pf);
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
	f_write_str(pf, g_pszCasFile);
	f_write_str(pf, g_pszCasSaveFile);

	// Done
	f_close(pf);
	free(pf);
}