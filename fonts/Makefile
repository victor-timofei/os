OBJECTS_GZ  := $(patsubst %.o, /usr/share/kbd/consolefonts/%.psfu.gz, $(OBJECTS))
OBJECTS_PSF := $(patsubst %.o, $(BUILD_DIR)/%.psfu, $(OBJECTS))
SYMS_PREFIX := consolefonts
OBJCOPY     := x86_64-elf-objcopy
OBJTARGET   := elf64-x86-64
BINARY_ARCH := i386:x86-64

.PHONY: all
all: $(BUILD_DIR)/$(OBJECTS)

$(BUILD_DIR)/%.o: $(OBJECTS_PSF)
	@$(OBJCOPY) \
		-O $(OBJTARGET) \
		-B $(BINARY_ARCH) \
		-I binary \
		$< $@
	@./gen_srd_file.sh \
		$<.srd \
		$< \
		$(SYMS_PREFIX)
	@$(OBJCOPY) \
		--redefine-syms $<.srd \
		$@
	@rm $<.srd

$(BUILD_DIR)/%.psfu: $(BUILD_DIR)/%.psfu.gz
	@gzip -d $@

$(BUILD_DIR)/%.psfu.gz: $(OBJECTS_GZ)
	@cp $< $(BUILD_DIR)
