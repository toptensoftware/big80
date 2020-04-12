#include "syscon.h"

#define COMMAND_CHOOSETAPE	0
#define COMMAND_SAVE_RECORDING 1
#define COMMAND_PLAY 3
#define COMMAND_RECORD 4
#define COMMAND_STOP 5
#define COMMAND_OPTIONS		7
#define COMMAND_RESET		8

static char* items[] = {
	"Choose Tape...",
	"Save Recording...",
	"\1",
	"Play",
	"Record",
	"Stop",
	"\1",
	"Options...",
	"Reset",
	NULL
};

static void HideUI()
{
	ApmEnable &= ~(APM_ENABLE_VIDEOSHOW|APM_ENABLE_ALLKEYS);
}

bool copy_file(const char* pszFrom, const char* pszTo)
{
	FIL src;
	if (f_open(&src, pszFrom, FA_OPEN_EXISTING | FA_READ))
		return false;

	FIL dst;
	if (f_open(&dst, pszTo, FA_CREATE_ALWAYS | FA_WRITE))
	{
		f_close(&src);
		return false;
	}

	while (true)
	{
		UINT byteCount = 0;
		f_read(&src, g_szTemp, sizeof(g_szTemp), &byteCount);
		if (byteCount == 0)
			break;	
		f_write(&dst, g_szTemp, byteCount, &byteCount);
	}

	f_close(&src);
	f_close(&dst);
	return true;
}

static void invoke_command(LISTBOX* pListBox)
{
	switch (pListBox->selectedItem)
	{
		case COMMAND_CHOOSETAPE:
		{
			const char* pszFile = choose_file("*.cas", g_pszCasFile, "(eject)");
			if (pszFile)
			{
				if (g_pszCasFile)
					free(g_pszCasFile);
				g_pszCasFile = pszFile;
				config_save();
			}
			break;
		}

		case COMMAND_SAVE_RECORDING:
		{
			const char* psz = prompt_input("Save As", g_pszCasSaveFile);
			if (psz)
			{
				bool success = copy_file("/RECORD.CAS", psz);
				message_box("Save", success ? "Saved" : "Failed!", okButtons, success ? 0 : MB_ERROR);

				if (success)
				{
					if (g_pszCasSaveFile)
						free(g_pszCasSaveFile);
					g_pszCasSaveFile = NULL;
				}
				else
				{
					free(psz);
				}
			}
			break;
		}

		case COMMAND_PLAY:
			CassetteCmdStatusPort = CASSETTE_COMMAND_PLAY;
			HideUI();
			break;

		case COMMAND_RECORD:
			CassetteCmdStatusPort = CASSETTE_COMMAND_RECORD;
			HideUI();
			break;

		case COMMAND_STOP:
			CassetteCmdStatusPort = CASSETTE_COMMAND_STOP;
			HideUI();
			break;

		case COMMAND_OPTIONS:
			options_menu();
			break;

		case COMMAND_RESET:
            ApmEnable |= APM_ENABLE_RESET;
			break;
	}
}



size_t main_menu_proc(WINDOW* pWindow, MSG* pMsg)
{
	switch (pMsg->message)
	{
		case MESSAGE_KEYDOWN:
		{
			switch (pMsg->param1)
			{
				case KEY_ESCAPE:
					HideUI();
					return 0;

				case KEY_ENTER:
                    invoke_command((LISTBOX*)pWindow);
					return 0;
			}
			break;
		}
	}
	
	return listbox_wndproc(pWindow, pMsg);
}

void main_menu()
{
	LISTBOX lb;
	memset(&lb, 0, sizeof(LISTBOX));

	lb.window.rcFrame.left = 0;
	lb.window.rcFrame.top = 0;
	lb.window.rcFrame.width = 22;
	lb.window.rcFrame.height = 11;
	lb.window.attrNormal = MAKECOLOR(COLOR_WHITE, COLOR_BLUE);
	lb.window.attrSelected = MAKECOLOR(COLOR_BLACK, COLOR_YELLOW);
	lb.window.title = "Big80 v2.0";
	lb.window.wndProc = main_menu_proc;
	lb.selectedItem = 0;
    listbox_set_data(&lb, -1, items);

	window_run_modal(&lb.window);

}