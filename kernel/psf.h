#include <stdint.h>

#ifndef PSF_HEADER
#define PSF_HEADER 1

#define PSF_FONT_MAGIC 0x864ab572

/* extern the symbols in the psf object */
extern char consolefonts_binary__start;
extern char consolefonts_binary__end;

struct psf_font {
  uint32_t magic;         /* magic bytes to identify psf */
  uint32_t version;       /* zero */
  uint32_t headersize;    /* offset of bitmaps in file, 32 */
  uint32_t flags;         /* 0 if there's no unicode table */
  uint32_t numglyphs;     /* number of glyphs */
  uint32_t bytesperglyph; /* size of each glyph */
  uint32_t height;        /* height in pixels */
  uint32_t width;         /* width in pixels */
};
typedef struct psf_font psf_font_t;

#endif
