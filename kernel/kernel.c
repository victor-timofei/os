#include "multiboot.h"
#include "console.h"
#include "kprintf.h"

#if defined (__linux__)
#error "You are not using a cross-compiler, you will most certainly run into trouble"
#endif

#if !defined (__x86_64__)
#error "The kernel needs to be compiled with a x86_64-elf compiler"
#endif

void kernel_main (multiboot_info_t *multiboot_struct_addr)
{
  console_init(multiboot_struct_addr);
  kprintf("Hello World");
}
