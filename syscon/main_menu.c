#include "syscon.h"

#define COMMAND_CHOOSETAPE	0
#define COMMAND_OPTIONS		2
#define COMMAND_RESET		3

static char* items[] = {
	"Choose Tape...",
	"\1",
	"Options...",
	"Reset",
	NULL
};

static void invoke_command(LISTBOX* pListBox)
{
	switch (pListBox->selectedItem)
	{
		case COMMAND_CHOOSETAPE:
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
	lb.window.rcFrame.height = 6;
	lb.window.attrNormal = MAKECOLOR(COLOR_WHITE, COLOR_BLUE);
	lb.window.attrSelected = MAKECOLOR(COLOR_BLACK, COLOR_YELLOW);
	lb.window.title = "Big80 v2.0";
	lb.window.wndProc = main_menu_proc;
	lb.selectedItem = 0;
    listbox_set_data(&lb, -1, items);

	window_run_modal(&lb.window);

}