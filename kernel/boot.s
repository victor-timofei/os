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
.code32
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

/* GDT varibles */
.set GDT_ZERO_ENTRY,         0x0
.set GDT_EXECUTABLE_FLAG,    1<<43
.set GDT_CODE_AND_DATA_FLAG, 1<<44
.set GDT_PRESENT_FLAG,       1<<47
.set GDT_64_BIT_FLAG,        1<<53
.set GDT_FLAGS,              GDT_EXECUTABLE_FLAG | GDT_CODE_AND_DATA_FLAG | GDT_PRESENT_FLAG | GDT_64_BIT_FLAG

.section .bss
/* We will be using hugepages, so we will need only 3 page levels. */
.align 4096
page_table_l4:
.skip 4096
page_table_l3:
.skip 4096
page_table_l2:
.skip 4096
page_table_l3_framebuffer:
.skip 4096
page_table_l2_framebuffer:
.skip 4096
stack_bottom:
.skip 4096 * 4
stack_top:

.section .rodata
.align 4
gdt64:
.quad GDT_ZERO_ENTRY
.set gdt64_code_segment, . - gdt64
.quad GDT_FLAGS
/*
gdt64_data_entry:
.set gdt64_data_segment, gdt64_data_entry - gdt64
.quad (1<<44) | (1<<46) | (1<<41)
*/
gdt64_pointer:
.word . - gdt64 - 1
.quad gdt64

/*
The linker script specifies _start as the entry point to the kernel and the
bootloader will jump to this position once the kernel has been loaded. It
doesn't make sense to return from this function as the bootloader is gone.
*/
.section .text
.code32
.global _start
.extern long_mode_start
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
        call setup_page_tables
        call setup_framebuffer_page_tables
        call enable_paging

        lgdt (gdt64_pointer)
        ljmp $gdt64_code_segment, $long_mode_start

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

setup_page_tables:
        movl $page_table_l3, %eax
        orl $0b11, %eax           /* flags are present and writable */
        movl %eax, page_table_l4 /* set page_table_l4 first entry to point to page_table_l3 */

        /* Same for next level */
        movl $page_table_l2, %eax
        orl $0b11, %eax
        movl %eax, page_table_l3

        /* Huge pages of size 2 MiBs */
        movl $0, %ecx
.loop:

        movl $0x200000, %eax
        mul %ecx

        /* present, writable, hugepage */
        orl $0b10000011, %eax
        movl %eax, page_table_l2(, %ecx, 8)

        inc %ecx
        cmp $512, %ecx
        jne .loop

        ret

setup_framebuffer_page_tables:
        /* Get the multiboot struct address */
        movl %ebx, %edx

        /*
        Offset to the framebuffer member. framebuffer[31:0] bits
        */
        add $88, %edx
        movl (%edx), %edx

        /* L4 */
        movl %edx, %ecx
        shr $30, %ecx
        and $0b111111111, %ecx

        and $0xC0000000, %edx /* We will start mapping from this address */

        movl $page_table_l2_framebuffer, %eax
        orl $0b11, %eax
        movl %eax, page_table_l3(, %ecx, 8)

        /* Huge pages of size 2 MiBs */
        movl $0, %ecx
.loop2:

        movl $0x200000, %eax
        imul %ecx, %eax
        orl %edx, %eax

        /* present, writable, hugepage */
        orl $0b10000011, %eax
        movl %eax, page_table_l2_framebuffer(, %ecx, 8)

        inc %ecx
        cmp $512, %ecx
        jne .loop2

        ret

enable_paging:
        /* pass page table location to CR3 */
        movl $page_table_l4, %eax
        movl %eax, %cr3

        /* Enable Physical Address Extension */
        movl %cr4, %eax
        orl $(1<<5), %eax
        mov %eax, %cr4

        /* Enable long mode */
        mov $0xC0000080, %ecx
        rdmsr
        orl $(1<<8), %eax
        wrmsr

        /* Enable paging */
        movl %cr0, %eax
        orl $(1<<31), %eax
        mov %eax, %cr0

        ret
