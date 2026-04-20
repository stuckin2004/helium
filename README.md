# Helium

Helium is an experimental OS targeting x86 hardware, written in C and C++. \
This is just a hobby project for now, so it's not very stable!

### The Kernel

The kernel is monolithic and targets 32-bit x86, developed in a two-stage approach: early boot (memory management, interrupts, VGA) is handled in C, with C++ taking over for higher-level kernel subsystems. The kernel aims to be POSIX-like with a Linux-compatible ABI, making application porting more straightforward down the line.

### Building

Requires an x86_64 host with `clang`, `clang++`, and `lld` available. No cross-compiler weirdness needed. Clang handles cross-compilation to i686 natively. Though if you're cross compiling from another host architecture like `arm64` or something niche, you may need to do some extra setup.

```sh
make
```

> [!NOTE]
> Highly unstable and pre-everything. Useful as a reference or learning project!
