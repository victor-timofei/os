#include "console.h"
#include "psf.h"
#include <stdint.h>

/* graphics framebuffer */
char *fb;
/* number of bytes in each line */
int scanline;

uint32_t console_y;
uint32_t console_x;

uint32_t console_rows;
uint32_t console_cols;

multiboot_info_t *mbi;

psf_font_t *font;

void putchar (uint16_t c, int32_t cx, int32_t cy, uint32_t fg, uint32_t bg)
{
  uint32_t bytesperline = (font->width + 7) / 8;

  unsigned char *glyph = (unsigned char *)font + font->headersize +
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

void set_pixel(uint64_t x, uint64_t y, PIXEL color)
{
  uint32_t pos = (y * sizeof (PIXEL) * mbi->framebuffer_width) + (x * sizeof (PIXEL));
  *((PIXEL *)(fb+pos)) = color;
}

PIXEL get_pixel(uint64_t x, uint64_t y)
{
  uint32_t pos = (y * sizeof (PIXEL) * mbi->framebuffer_width) + (x * sizeof (PIXEL));
  return *((PIXEL *)(fb+pos));
}

void console_scroll()
{
  const uint32_t width = mbi->framebuffer_width;
  const uint32_t font_height = font->height;

  /* Move each row to the previous one */
  for (uint32_t row = 1; row < console_rows; row++) {
    for (uint32_t y = 0; y < font_height; y++ ) {
      for (uint32_t x = 0; x < width; x++ ) {
        PIXEL p = get_pixel(x, (row * font_height) + y);
        set_pixel(x, ((row - 1) * font_height) + y, p);
      }
    }
  }

  /* Reset bottom row*/
  for (uint32_t y = 0; y < font_height; y++ ) {
    for (uint32_t x = 0; x < width; x++ ) {
      set_pixel(x, ((console_rows - 1) * font_height) + y, CONSOLE_BG);
    }
  }
}

void console_puts(uint16_t ch)
{
  if (ch == '\n') {
    console_x = 0;
    console_y++;
    return;
  }

  if (console_x >= console_cols) {
    console_x = 0;
    console_y++;
  }

  if (console_y >= console_rows)
    console_scroll();

  putchar((uint16_t) ch, console_x, console_y, CONSOLE_FG, CONSOLE_BG);
  console_x++;
}

void console_write(char *str)
{
  for (int idx = 0; str[idx] != '\0'; idx++ ) {
    console_puts(str[idx]);
  }
}

void console_init(multiboot_info_t *multiboot_struct)
{
  mbi = multiboot_struct;
  fb = (char *)mbi->framebuffer_addr;
  scanline = mbi->framebuffer_pitch;

  font = (psf_font_t *)&consolefonts_binary__start;

  console_rows = mbi->framebuffer_height / font->height;
  console_cols = mbi->framebuffer_width / font->width;

  console_x = 0;
  console_y = 0;
}
