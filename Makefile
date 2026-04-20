# Makefile for Helium, quite complicated!
# (c) 2026 stuckin2004 - licensed under BSD-3-Clause

# Compilers (similarly important)
CXX := clang++
CC := clang

# Sources & directories
BUILD_DIR := dist
SOURCE_DIR := source
INCLUDE_DIR := $(SOURCE_DIR)/include
KERNEL_ELF := $(BUILD_DIR)/helium.elf
LINKER_SRC := $(SOURCE_DIR)/linker.ld

# Source discovery (important!)
# todo...

# Compiler flags, both C and C++!
CFLAGS := \
	-Wall -Wextra -Wshadow -Wunused-function -Wunused-parameter \
	-Wno-pointer-to-int-cast -I$(INCLUDE_DIR) -nostdinc -mno-sse \
	-mno-red-zone -mno-sse2 -mno-mmx -mno-3dnow -std=c23 -MMD -MP \
	-ffreestanding -fno-stack-protector -fno-pic -fno-pie -m32 -O1 \
	-fno-omit-frame-pointer -fno-asynchronous-unwind-tables \
	-fno-common -fno-unwind-tables -fno-builtin \
	-fno-delete-null-pointer-checks \
	-Werror=implicit-function-declaration -Werror=return-type \
	-Werror=implicit-int -Werror=incompatible-pointer-types -g

CXXFLAGS := \
