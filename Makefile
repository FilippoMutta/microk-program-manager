include ../../Makefile.inc

MODDIR = .
MODNAME = manager

COMMON_CFLAGS = -ffreestanding             \
	 -fno-stack-protector          \
	 -fno-omit-frame-pointer    \
	 -fno-builtin-g             \
	 -I ../../mkmi/src/include    \
	 -I ../../microk-kernel/src/include    \
	 -Wall                      \
	 -Wextra                    \
	 -Werror                    \
	 -Wno-write-strings         \
	 -Weffc++                   \
	 -Og                        \
	 -fno-rtti                  \
	 -fno-exceptions            \
	 -fno-lto                   \
	 -fno-pie                   \
	 -fno-pic                   \
	 -fpermissive \
	 -ggdb

LDFLAGS = -static \
	  -Ttext 0x100000 \
	  -nostdlib               \
	  -m elf_$(ARCH)          \
	  -z max-page-size=0x1000

ifeq ($(ARCH), x86_64)
	CFLAGS = $(COMMON_CFLAGS) -mno-80387 \
         -mno-mmx                   \
         -mno-sse                   \
         -mno-sse2                  \
	 -mno-red-zone              \
	 -m64                       \
	 -mabi=sysv                 \
	 -mcmodel=small  \
	 -march=x86-64

	LDFLAGS += -m elf_x86_64

	ASMFLAGS = -f elf64
else ifeq ($(ARCH), aarch64)
	CFLAGS = $(COMMON_CFLAGS) -march=armv8-a \
         -mabi=lp64     \
	 -mcmodel=large

	LDFLAGS += -m aarch64elf
	ASMFLAGS = 
else
	$(error Unsupported ARCH: $(ARCH))
endif

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

CPPSRC = $(call rwildcard,$(MODDIR),*.cpp)
OBJS = $(patsubst $(MODDIR)/%.cpp, $(MODDIR)/%.o, $(CPPSRC))

.PHONY: clean module

$(MODDIR)/%.o: $(MODDIR)/%.cpp
	@ mkdir -p $(@D)
	@ echo !==== COMPILING MODULE $^ && \
	$(CPP) $(CFLAGS) -c $^ -o $@

module: $(OBJS)
	@ echo !==== LINKING
	$(LD) $(LDFLAGS) -o ../$(MODNAME).kmd $(OBJS) -L../../mkmi -lmkmi

clean:
	@rm $(OBJS)
