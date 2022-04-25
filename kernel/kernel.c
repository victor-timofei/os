#include "multiboot.h"
#include "psf.h"
#include <stdint.h>

#if defined (__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

#if !defined (__i386__)
#error "The kernel needs to be compiled with a ix86-elf compiler"
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

#define PIXEL uint32_t

void putchar (uint16_t c, int32_t cx, int32_t cy, uint32_t fg, uint32_t bg)
{
  psf_font_t *font = (psf_font_t *)&consolefonts_binary__start;
  uint32_t bytesperline = (font->width + 7) / 8;

  unsigned char *glyph = (unsigned char *)&consolefonts_binary__start + font->headersize +
    (c > 0 && c < font->numglyphs ? c : 0) * font->bytesperglyph;

  uint32_t offs = (cy * font->height * scanline) + (cx * (font->width + 1) * sizeof (PIXEL));

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

void kernel_main (uint64_t multiboot_struct_addr)
{
  mbi = (multiboot_info_t *)multiboot_struct_addr;

  fb = (char *)mbi->framebuffer_addr;
  scanline = mbi->framebuffer_pitch;

  putchar ((uint16_t)'H', 0,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'e', 1,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'l', 2,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'l', 3,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'o', 4,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)' ', 5,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'W', 6,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'o', 7,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'r', 8,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'l', 9,  0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'d', 10, 0, 0xFFFFFFFF, 0);
  putchar ((uint16_t)'!', 11, 0, 0xFFFFFFFF, 0);
}
