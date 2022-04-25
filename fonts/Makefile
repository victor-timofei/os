OBJECTS_GZ  := $(patsubst %.o, /usr/share/kbd/consolefonts/%.psfu.gz, $(OBJECTS))
OBJECTS_PSF := $(patsubst %.o, $(BUILD_DIR)/%.psfu, $(OBJECTS))
SYMS_PREFIX := consolefonts

all: $(BUILD_DIR)/$(OBJECTS)

$(BUILD_DIR)/%.o: $(OBJECTS_PSF)
	@objcopy \
		-O elf32-i386 \
		-B i386 \
		-I binary \
		$< $@
	@./gen_srd_file.sh \
		$<.srd \
		$< \
		$(SYMS_PREFIX)
	@objcopy \
		--redefine-syms $<.srd \
		$@
	@rm $<.srd

$(BUILD_DIR)/%.psfu: $(BUILD_DIR)/%.psfu.gz
	@gzip -d $@

$(BUILD_DIR)/%.psfu.gz: $(OBJECTS_GZ)
	@cp $< $(BUILD_DIR)
