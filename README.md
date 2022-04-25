# OS

## GCC Cross-Compiler

### Build requirements

- Unix-like environment
- GCC
- Make
- Bison
- Flex
- GMP
- MPFR
- MPC
- Texinfo

### Install

```shell
make crossdev
```

### Load the environment
```shell
source .cross_env
```

## Kernel

### Build

```shell
make
```

### Run on qemu
```shell
make run-qemu
```
