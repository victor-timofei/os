#include "multiboot.h"
#include "psf.h"
#include <stdint.h>
#include <stdarg.h>

#if defined (__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

#if !defined (__x86_64__)
#error "The kernel needs to be compiled with a x86_64-elf compiler"
#endif

/* graphics framebuffer */
char *fb;
/* number of bytes in each line */
int scanline;
/* extern the symbols in the psf object */
extern char consolefonts_binary__start;
extern char consolefonts_binary__end;

multiboot_info_t *mbi;
uint32_t console_y;
uint32_t console_x;

uint32_t console_max_y;
uint32_t console_max_x;

#define PIXEL uint32_t

#define CONSOLE_BG 0
#define CONSOLE_FG 0xFFFFFFFF

void putchar (uint16_t c, int32_t cx, int32_t cy, uint32_t fg, uint32_t bg)
{
  psf_font_t *font = (psf_font_t *)&consolefonts_binary__start;
  uint32_t bytesperline = (font->width + 7) / 8;

  unsigned char *glyph = (unsigned char *)&consolefonts_binary__start + font->headersize +
    (c > 0 && c < font->numglyphs ? c : 0) * font->bytesperglyph;

  uint32_t offs = (cy * font->height * scanline) + (cx * (font->width) * sizeof (PIXEL));

  uint32_t x, y, line, mask;
  for (y = 0; y < font->height; y++) {
    line = offs;
    mask = 1 << (font->width -1);
    for (x = 0; x < font->width; x++) {
      *((PIXEL *)(fb+line)) = *((uint32_t *)glyph) & mask ? fg : bg;
      mask >>= 1;
      line += sizeof (PIXEL);
    }
    glyph += bytesperline;
    offs += scanline;
  }

}

void console_push()
{
  // TODO: implement console pushing
}

void console_puts(uint16_t ch)
{
  if (ch == '\n') {
    console_x = 0;
    console_y++;
    return;
  }

  if (console_x >= console_max_x) {
    console_x = 0;
    console_y++;
  }

  if (console_y > console_max_y)
    console_push();

  putchar((uint16_t) ch, console_x, console_y, CONSOLE_FG, CONSOLE_BG);
  console_x++;
}

void console_write(char *str)
{
  for (int idx = 0; str[idx] != '\0'; idx++ ) {
    console_puts(str[idx]);
  }
}

void console_init(multiboot_info_t *mbi)
{
  psf_font_t *font = (psf_font_t *)&consolefonts_binary__start;

  console_max_y = mbi->framebuffer_height / font->height - 1;
  console_max_x = mbi->framebuffer_width / font->width - 1;

  console_x = 0;
  console_y = 0;
}

void convert(int num, int base, char *buf, int bufsize)
{
  int idx = 0;
  buf[idx] = '\0';

  do {
    /* Avoid buffer overrun */
    if (idx == bufsize - 1)
      break;

    buf[idx] = (num % base) + '0';
    num /= base;
    idx++;
  } while(num != 0);

  buf[idx] = '\0';

  for (int i = 0; i < idx / 2; i++) {
    int tmp = buf[i];
    buf[i] = buf[idx-1-i];
    buf[idx-1-i] = tmp;
  }
}

void kprintf(char *format, ...)
{
  va_list arg;
  va_start(arg, format);

  char buffer[50];
  int i;

  for (int idx = 0; format[idx] != '\0'; idx++) {
    while (format[idx] != '%') {

      /* Never overrun the buffer */
      if (format[idx] == '\0')
        return;

      console_puts(format[idx]);
      idx++;
    }
    idx++;
    switch (format[idx]) {
      case 'd':
        i = va_arg(arg, int);
        if (i < 0) {
          i = -i;
          console_puts('-');
        }

        convert(i, 10, buffer, 50);
        console_write(buffer);
        break;
    }
  }

  va_end(arg);
}

void kernel_main (uint32_t multiboot_struct_addr)
{
  mbi = (multiboot_info_t *)multiboot_struct_addr;
  fb = (char *)mbi->framebuffer_addr;
  scanline = mbi->framebuffer_pitch;

  console_init(mbi);
  kprintf("Console width is %d\n", mbi->framebuffer_width);
}
