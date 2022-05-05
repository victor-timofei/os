
SOURCES_S := boot.s boot64.s
OBJECTS_S := $(patsubst %.s, $(BUILD_DIR)/kernel/%.o, $(SOURCES_S))

SOURCES_C := kernel.c kprintf.c console.c
HEADERS_C := multiboot.h psf.h kprintf.h console.h
OBJECTS_C := $(patsubst %.c, $(BUILD_DIR)/kernel/%.o, $(SOURCES_C))

LINKER_LD := linker.ld

.PHONY: all
all: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: $(OBJECTS_S) $(OBJECTS_C) $(LINKER_LD)
	@x86_64-elf-ld \
		-n \
		-T $(LINKER_LD) \
		$(OBJECTS_C) \
		$(OBJECTS_S) \
		$(EXTRA_OBJS) \
		-o $@
	@echo "Built $@"

$(BUILD_DIR)/kernel/%.o: %.c $(SOURCES_C)
	@mkdir -p $(dir $@)
	@$(CROSS_CC) -c $< -o $@ $(CFLAGS)
	@echo "Built $@"

$(BUILD_DIR)/kernel/%.o: %.s $(SOURCES_S)
	@mkdir -p $(dir $@)
	@$(CROSS_AS) $< -o $@
	@echo "Built $@"
