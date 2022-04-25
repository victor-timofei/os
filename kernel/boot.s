/* Declare constants for the multiboot header */
.set ALIGN,    1<<0                    /* align loaded modules on page boundaries */
.set MEMINFO,  1<<1                    /* provide memory map */
.set VIDEO,    1<<2                    /* enable graphics framebuffer */
.set FLAGS,    ALIGN | MEMINFO | VIDEO /* this is the Multiboot 'flag' field */
.set MAGIC,    0x1BADB002              /* 'magic number' lets bootloader find the header */
.set CHECKSUM, -(MAGIC + FLAGS)        /* checksum of above, to prove we are multiboot */

/*
These are not used, but are needed for padding since we enable video and we
are interested in the graphics field of the multiboot header.
*/
.set HEADER_ADDR,   0x0
.set LOAD_ADDR,     0x0
.set LOAD_END_ADDR, 0x0
.set BSS_END_ADDR,  0x0
.set ENTRY_ADDR,    0x0

/* Graphics field of the multiboot header */
.set MODE_TYPE, 0x0 /* Contains ‘0’ for linear graphics mode or ‘1’ for EGA-standard text mode */
.set WIDTH,     0x0 /* Contains the number of the columns */
.set HEIGHT,    0x0 /* Contains the number of the lines */
.set DEPTH,     0x0 /* Contains the number of bits per pixel in a graphics mode, and zero in a text mode */

/*
Declare a multiboot header that marks the program as a kernel. These are magic
values that are documented in the multiboot standard. The bootloader will
search for this signature in the first 8 KiB of the kernel file, aligned at a
32-bit boundary. The signature is in its own section so the header can be
forced to be within the first 8 KiB of the kernel file.
*/
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM
.long HEADER_ADDR
.long LOAD_ADDR
.long LOAD_END_ADDR
.long BSS_END_ADDR
.long ENTRY_ADDR
.long MODE_TYPE
.long WIDTH
.long HEIGHT
.long DEPTH

/*
The multiboot header layout is as follows:
Offset  Type    Field Name      Note
0       u32     magic           required
4       u32     flags           required
8       u32     checksum	required
12      u32     header_addr     if flags[16] is set
16      u32     load_addr       if flags[16] is set
20      u32     load_end_addr   if flags[16] is set
24      u32     bss_end_addr    if flags[16] is set
28      u32     entry_addr      if flags[16] is set
32      u32     mode_type       if flags[2] is set
36      u32     width           if flags[2] is set
40      u32     height          if flags[2] is set
44      u32     depth           if flags[2] is set
*/

/*
The multiboot standard does not define the value of the stack pointer register
(esp) and it is up to the kernel to provide a stack. This allocates room for a
small stack by creating a symbol at the bottom of it, the allocating 16384
bytes for it, and finally creating a symbol at the top. The stack grows
downwards on x86. The stack is in its own section so it can be marked nobits,
which means the kernel file is smaller because it does no contain an
uninitialized stack. The stack on x86 must be 16-byte aligned according to the
System V ABI standard and de-facto extensions. The compiler will assume the
stack is properly aligned and failure to align the stack will result in
undefined behavior.
*/
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

/*
The linker script specifies _start as the entry point to the kernel and the
bootloader will jump to this position once the kernel has been loaded. It
doesn't make sense to return from this function as the bootloader is gone.
*/
.section .text
.global _start
.type _start, @function
_start:
        /*
        The bootloader has loaded us into 32-bit protected mode on a x86
        machine. Interrupts are disabled. Paging is disabled. The processor
        state is as defined in the multiboot standard. The kernel has full
        control of the CPU. The kernel can only make use of hardware features
        and any code it provides as part of itself. There's no printf
        function, unless the kernel provides its own <stdio.h> header and a
        printf implementation. There are no security restrictions, no
        safeguard, no debugging mechanisms, only what the kernel provides
        itself. It has absolute and comlete power over the machine.
        */

        /*
        To set up a stack, we set the esp register to point to the top of the
        stack (as it grows downwards on x86 systems). This is necessarily done
        in assembly as languages such as C cannot function without a stack.
        */
        mov $stack_top, %esp

        /*
        This is a good place to initialize crucial processor state before the
        high-level kernel is entered. It's best to minimize the early
        environment where crucial features are offline. Note that the
        processor is not fully initialized yet: Features such as floating
        point instructions and instruction set extensions are not initialized
        yet. The GDT should be loaded here. Paging should be enabled here.
        C++ features such as global constructors and exceptions will require
        runtime support to work as well.
        */

        /*
        Enter the high-level kernel. The ABI requires the stack is 16-byte
        aligned at the time of the call instruction (which afterwards pushes
        the return pointer of size 4 bytes). The stack was originally 16-byte
        aligned above and we've pushed a multiple of 16 bytes to the stack
        since (pushed 0 bytes so far), so the alignment has thus been
        preserved and the call is well defined.
        */
        pushl %ebx /* pass the Multiboot Info struct addr to kernel_main */
        call kernel_main

        /*
        If the system has nothing more to do, put the computer into an
        infinite loop. To do that:
        1) Disable interrupts with cli (clear interrupt enable in eflags).
           They are already disabled by the bootloader, so this is not needed.
           Mind that you might later enable interrupts and return from
           kernel_main (which is sort of nonsensical to do).
        2) Wait for the next interrupt to arrive with hlt (halt instruction).
           Since they are disabled, this will lock up the computer.
        3) Jump to the hlt instruction if it ever wakes up due to a
           non-maskable interrupt occurring or due to system management mode.
        */
        cli
1:      hlt
        jmp 1b

/*
Set the size of the _start symbol to the current location '.' minus its start.
This is useful when debugging or when you implement call tracing.
*/
.size _start, . - _start
