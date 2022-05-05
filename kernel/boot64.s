.global long_mode_start
.extern kernel_main

.section .text
.code64
long_mode_start:
  movw $0, %ax
  movw %ax, %ss
  movw %ax, %ds
  movw %ax, %es
  movw %ax, %fs
  movw %ax, %gs

  /* We should keep the pointer to mb, debug needed */
  mov %rbx, %rdi
  call kernel_main
  hlt
