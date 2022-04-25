#include <stdint.h>

#ifndef MULTIBOOT_HEADER
#define MULTIBOOT_HEADER 1

struct multiboot_aout_symbol_table {
  uint32_t tabsize;
  uint32_t strsize;
  uint32_t addr;
  uint32_t reserved;
};
typedef struct multiboot_aout_symbol_table multiboot_aout_symbol_table_t;

struct multiboot_elf_section_header_table {
  uint32_t num;
  uint32_t size;
  uint32_t addr;
  uint32_t shndx;
};
typedef struct multiboot_elf_section_header_table multiboot_elf_section_header_table_t;

struct multiboot_info {
  uint32_t flags;

  /* present if flags[0] is set */
  uint32_t mem_lower;
  uint32_t mem_upper;

  /* present if flags[1] is set */
  uint32_t boot_device;

  /* present if flags[2] is set */
  uint32_t cmd_line;

  /* present if flags[3] is set */
  uint32_t mods_count;
  uint32_t mods_addr;

  /* present if flags[4] or flags[5] is set */
  union {
    multiboot_aout_symbol_table_t aout_sym;
    multiboot_elf_section_header_table_t elf_sec;
  } u;

  /* present if flags[6] is set */
  uint32_t mmap_length;
  uint32_t mmap_addr;

  /* present if flags[7] is set */
  uint32_t drives_length;
  uint32_t drives_addr;

  /* present if flags[8] is set */
  uint32_t config_table;

  /* present if flags[9] is set */
  uint32_t boot_loader_name;

  /* present if flags[10] is set */
  uint32_t apm_table;

  /* present if flags[11] is set */
  uint32_t vbe_control_info;
  uint32_t vbe_mode_info;
  uint16_t vbe_mode;
  uint16_t vbe_interface_seg;
  uint16_t vbe_interface_off;
  uint16_t vbe_interface_len;

  /* present if flags[12] is set */
  uint64_t framebuffer_addr;
  uint32_t framebuffer_pitch;
  uint32_t framebuffer_width;
  uint32_t framebuffer_height;
  uint8_t framebuffer_bpp;
  uint8_t framebuffer_type;
  uint32_t color_info1;
  uint16_t color_info2;
  union {
    struct {
      uint32_t framebuffer_palette_addr;
      uint16_t framebuffer_palette_num_colors;
    };
    struct {
      uint8_t framebuffer_red_field_position;
      uint8_t framebuffer_red_mask_size;
      uint8_t framebuffer_green_field_position;
      uint8_t framebuffer_green_mask_size;
      uint8_t framebuffer_blue_field_position;
      uint8_t framebuffer_blue_mask_size;
    };
  };
}__attribute__((packed));
typedef struct multiboot_info multiboot_info_t;

#endif
