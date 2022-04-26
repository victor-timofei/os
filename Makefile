BINUTILS_VERSION := 2.38
GCC_VERSION      := 11.2.0
PREFIX           := ${PWD}/cross
CROSS_BIN        := ${PREFIX}/bin
BUILD_DIR        := ./build
TARGET           := i686-elf
FONTS            := default8x16.o

BUILD_DIR_ABS := $(abspath $(BUILD_DIR))

FONT_OBJS := $(patsubst %.o,$(BUILD_DIR_ABS)/%.o, $(FONTS))

ISO_DIR := $(BUILD_DIR)/iso_dir

CROSS_AS         := ${TARGET}-as
CROSS_CC         := ${TARGET}-gcc
CROSS_LD         := ${TARGET}-ld
CFLAGS           := "-std=gnu99 -ffreestanding -O2 -Wall -Wextra -I$$PWD/kernel"
LDFLAGS          := "-ffreestanding -O2 -nostdlib -lgcc"

export PATH      := ${CROSS_BIN}:$(PATH)

.PHONY: all
all: $(BUILD_DIR)/kernel.bin $(BUILD_DIR)/$(FONTS)

.PHONY: run-qemu
run-qemu: $(BUILD_DIR)/kernel.iso
	@qemu-system-x86_64 -cdrom $<

$(BUILD_DIR)/kernel.iso: $(ISO_DIR)/boot/kernel.bin
	@grub-mkrescue -o $@ $(ISO_DIR)

$(ISO_DIR)/boot/kernel.bin: $(BUILD_DIR)/kernel.bin $(ISO_DIR)/boot/grub/grub.cfg
	@cp $< $@

$(ISO_DIR)/boot/grub/grub.cfg: $(ISO_DIR)/boot
	@cp -r grub $<

$(ISO_DIR)/boot: $(ISO_DIR)
	@mkdir -p $@

$(ISO_DIR):
	@mkdir -p $@

$(BUILD_DIR)/kernel.bin: $(BUILD_DIR) $(BUILD_DIR)/$(FONTS)
	@$(MAKE) -C kernel \
		BUILD_DIR=$(abspath $(BUILD_DIR)) \
		CROSS_AS=${CROSS_AS} \
		CROSS_CC=${CROSS_CC} \
		CROSS_LD=${CROSS_LD} \
		CFLAGS=${CFLAGS} \
		EXTRA_OBJS=${FONT_OBJS} \
		LDFLAGS=${LDFLAGS}

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/$(FONTS):
	@$(MAKE) -C fonts BUILD_DIR=$(abspath $(BUILD_DIR)) OBJECTS=$(FONTS)

.PHONY: crossdev
crossdev: install-binutils install-gcc install-target-libgcc clean-cross

.PHONY: install-binutils
install-binutils: build-binutils ${CROSS_BIN}
	@$(MAKE) -C binutils-${BINUTILS_VERSION}/build install

.PHONY: install-gcc
install-gcc: all-gcc ${CROSS_BIN}
	@$(MAKE) -C gcc-${GCC_VERSION}/build $@

.PHONY: install-target-libgcc
install-target-libgcc: all-target-libgcc ${CROSS_BIN}
	@$(MAKE) -C gcc-${GCC_VERSION}/build $@

${CROSS_BIN}:
	@mkdir -p $@

.PHONY: build-binutils
build-binutils: binutils-${BINUTILS_VERSION}/build/Makefile
	@dirname $< | \
		xargs \
		$(MAKE) -C

.PHONY: all-gcc
all-gcc: gcc-${GCC_VERSION}/build/Makefile install-binutils
	@dirname $< | \
		xargs -I {} \
		$(MAKE) -C {} $@

.PHONY: all-target-libgcc
all-target-libgcc: gcc-${GCC_VERSION}/build/Makefile install-binutils
	@dirname $< | \
		xargs -I {} \
		$(MAKE) -C {} $@

binutils-${BINUTILS_VERSION}/build/Makefile: binutils-${BINUTILS_VERSION}/build
	@cd $< && \
		../configure \
		--target="${TARGET}" \
		--prefix="${PREFIX}" \
		--with-sysroot \
		--disable-nls \
		--disable-werror

gcc-${GCC_VERSION}/build/Makefile: gcc-${GCC_VERSION}/build install-binutils
	@cd $< && \
		../configure \
		--target="${TARGET}" \
		--prefix="${PREFIX}" \
		--disable-nls \
		--enable-languages=c,c++ \
		--without-headers

binutils-${BINUTILS_VERSION}/build: binutils-${BINUTILS_VERSION}
	@mkdir -p $@

gcc-${GCC_VERSION}/build: gcc-${GCC_VERSION}
	@mkdir -p $@

binutils-${BINUTILS_VERSION}: binutils.tar.gz
	@tar xf $<

gcc-${GCC_VERSION}: gcc.tar.gz
	@tar xf $<

binutils.tar.gz:
	@curl -o $@ https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz

gcc.tar.gz:
	@curl -o $@ https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz

.PHONY: clean-cross
clean-cross:
	@rm -f gcc.tar.gz
	@rm -f binutils.tar.gz
	@rm -rf gcc-$(GCC_VERSION)
	@rm -rf binutils-$(BINUTILS_VERSION)

.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)

