BINUTILS_VERSION=2.38
GCC_VERSION=11.2.0
PREFIX=${PWD}/cross
CROSS_BIN=${PREFIX}/bin
TARGET=i686-elf
export PATH:=${CROSS_BIN}:$(PATH)

.PHONY: crossdev
crossdev: install-binutils install-gcc install-target-libgcc

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

