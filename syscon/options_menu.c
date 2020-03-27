#include "syscon.h"

#define COMMAND_SCREEN_COLOR	0
#define COMMAND_SCAN_LINES		1
#define COMMAND_AUTO_TAPE		2
#define COMMAND_TURBO_TAPE		3
#define COMMAND_TAPE_AUDIO		4
#define COMMAND_TYPING_MODE		5

static char* items[] = {
	"Screen Color      Green",
	"Scan Lines          Yes",
	"Auto Start Tape     Yes",
	"Turbo Tape          Yes",
	"Tape Audio Monitor  Yes",
	"Typing Mode         Yes",
	NULL
};

static void update_option(char* psz, bool val)
{
	if (psz == items[COMMAND_SCAN_LINES])
		val =!val;
	if (psz == items[COMMAND_SCREEN_COLOR])
		strcpy(psz + strlen(psz) - 5, val ? "Green" : "Amber");
	else
		strcpy(psz + strlen(psz) - 3, val ? "Yes" : " No");
}

static void invoke_command(LISTBOX* pListBox)
{
	// Map command to bit
	uint8_t bit = 0;
	switch (pListBox->selectedItem)
	{
		case COMMAND_SCREEN_COLOR: bit = OPTION_GREEN_SCREEN; break;
		case COMMAND_SCAN_LINES: bit = OPTION_NO_SCAN_LINES; break;
		case COMMAND_AUTO_TAPE: bit = OPTION_AUTO_CAS; break;
		case COMMAND_TURBO_TAPE: bit = OPTION_TURBO_TAPE; break;
		case COMMAND_TAPE_AUDIO: bit = OPTION_CAS_AUDIO; break;
		case COMMAND_TYPING_MODE: bit = OPTION_TYPING_MODE; break;
	}

	// Toggle the bit
	OptionsPort ^= bit;

	// Update command text
	update_option(items[pListBox->selectedItem], OptionsPort & bit);

	// Redraw the item
	listbox_drawitem(pListBox, pListBox->selectedItem);

	// Save config
	config_save();
}



size_t options_menu_proc(WINDOW* pWindow, MSG* pMsg)
{
	switch (pMsg->message)
	{
		case MESSAGE_KEYDOWN:
		{
			switch (pMsg->param1)
			{
				case KEY_ESCAPE:
					window_end_modal(0);
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

void options_menu()
{
	update_option(items[COMMAND_SCREEN_COLOR], OptionsPort & OPTION_GREEN_SCREEN);
	update_option(items[COMMAND_SCAN_LINES], OptionsPort & OPTION_NO_SCAN_LINES);
	update_option(items[COMMAND_AUTO_TAPE], OptionsPort & OPTION_AUTO_CAS);
	update_option(items[COMMAND_TURBO_TAPE], OptionsPort & OPTION_TURBO_TAPE);
	update_option(items[COMMAND_TAPE_AUDIO], OptionsPort & OPTION_CAS_AUDIO);
	update_option(items[COMMAND_TYPING_MODE], OptionsPort & OPTION_TYPING_MODE);

	LISTBOX lb;
	memset(&lb, 0, sizeof(LISTBOX));

	lb.window.rcFrame.left = 2;
	lb.window.rcFrame.top = 1;
	lb.window.rcFrame.width = 25;
	lb.window.rcFrame.height = 8;
	lb.window.attrNormal = MAKECOLOR(COLOR_WHITE, COLOR_BLUE);
	lb.window.attrSelected = MAKECOLOR(COLOR_BLACK, COLOR_YELLOW);
	lb.window.title = "Options";
	lb.window.wndProc = options_menu_proc;
	lb.selectedItem = 0;
    listbox_set_data(&lb, -1, items);

	window_run_modal(&lb.window);

}