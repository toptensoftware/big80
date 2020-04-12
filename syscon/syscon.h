#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <libSysCon.h>
#include <ff.h>

extern char g_szTemp[128];

// uart_fiber.c
void uart_interrupts();
void uart_init();

// main_menu.c
void main_menu();

// options_menu.c
void options_menu();

// config.c
void config_load();
void config_save();

// cassette_fiber.c
extern const char* g_pszCasFile;
extern const char* g_pszCasSaveFile;
void cassette_init();
void cassette_isr();
