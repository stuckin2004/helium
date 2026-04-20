# Makefile for Helium
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

# Source discovery
C_SRCS   := $(shell find $(SOURCE_DIR) -name '*.c')
CXX_SRCS := $(shell find $(SOURCE_DIR) -name '*.cpp')
ASM_SRCS := $(shell find $(SOURCE_DIR) -name '*.S')

# Object files
C_OBJS   := $(patsubst $(SOURCE_DIR)/%.c,   $(BUILD_DIR)/%.c.o,   $(C_SRCS))
CXX_OBJS := $(patsubst $(SOURCE_DIR)/%.cpp, $(BUILD_DIR)/%.cpp.o, $(CXX_SRCS))
ASM_OBJS := $(patsubst $(SOURCE_DIR)/%.S,   $(BUILD_DIR)/%.S.o,   $(ASM_SRCS))
ALL_OBJS := $(C_OBJS) $(CXX_OBJS) $(ASM_OBJS)

# Dependency files for incremental building
DEPS := $(ALL_OBJS:.o=.d)

# Compiler flags, both C and C++!
COMMON_CFLAGS := \
	-Wall -Wextra -Wshadow -Wunused-function -Wunused-parameter \
	-Wno-pointer-to-int-cast -I$(INCLUDE_DIR) -nostdinc -mno-sse \
	-mno-red-zone -mno-sse2 -mno-mmx -mno-3dnow -MMD -MP \
	-ffreestanding -fno-stack-protector -fno-pic -fno-pie -m32 -O1 \
	-fno-omit-frame-pointer -fno-asynchronous-unwind-tables \
	-fno-common -fno-unwind-tables -fno-builtin \
	-fno-delete-null-pointer-checks \
	-Werror=implicit-function-declaration -Werror=return-type \
	-Werror=implicit-int -Werror=incompatible-pointer-types -g

CFLAGS := \
	-Wmissing-prototypes -Wmissing-declarations -std=c23

CXXFLAGS := \
	-fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit \
	-Wold-style-cast -std=c++23

ASFLAGS := -m32

# Linker flags
LDFLAGS := \
	-T $(LINKER_SRC) -m elf_i386
	--no-dynamic-linker -nostdlib

# Default target
.PHONY: all clean
