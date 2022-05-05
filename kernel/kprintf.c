#include "console.h"
#include "kprintf.h"
#include <stdarg.h>
#include <stdint.h>

/*
 * Converts a decimal number to a different base.
 */
void convert(uint64_t num, int base, char *buf, int bufsize)
{
  int idx = 0;
  buf[idx] = '\0';

  do {
    /* Avoid buffer overrun */
    if (idx == bufsize - 1)
      break;

    int remainder = num % base;

    if (remainder > 9)
      buf[idx] = remainder - 10 + 'A';
    else
      buf[idx] = remainder + '0';

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

/*
 * Print formatted string.
 */
void kprintf(char *format, ...)
{
  va_list arg;
  va_start(arg, format);

  char buffer[50];
  long i;

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
        i = va_arg(arg, long);
        if (i < 0) {
          i = -i;
          console_puts('-');
        }

        convert(i, 10, buffer, 50);
        console_write(buffer);
        break;
      case 'X':
        i = va_arg(arg, long);

        convert(i, 16, buffer, 50);
        console_write(buffer);
        break;
    }
  }

  va_end(arg);
}
