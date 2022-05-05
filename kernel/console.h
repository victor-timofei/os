#include "multiboot.h"

#ifndef CONSOLE_HEADER
#define CONSOLE_HEADER 1

#define PIXEL uint32_t

#define CONSOLE_BG 0
#define CONSOLE_FG 0xFFFFFFFF

void console_init(multiboot_info_t *mbi);

void console_write(char *str);

void console_puts(uint16_t ch);

#endif
