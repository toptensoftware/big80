#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include <kernel.h>

// ui_fiber.c
void ui_fiber_init();

// uart_fiber.c
void uart_fiber_init();

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
void cassette_fiber_init();
void cassette_isr();
