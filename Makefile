# SMSPlus GX — Sega Master System / Game Gear / SG-1000 / Colecovision
# standalone dynamic core for Game & Watch Retro-Go SD.
#
#   make                  — build + pack → SmsPlusGX.bin
#   make host             — Linux/macOS SDL binary (same sources)
#   make host HOST_SDL=3  — same with SDL3
#   make docker           — same build inside Docker (no host toolchain)
#   make docker_shell     — interactive shell in the builder image
#
# Coleco BIOS: objcopy .coleco_bios_data from the linked ELF → bios/coleco/coleco.bin
# (shipped in the install zip). Verbose compiler lines: make V=

#######################################
# Project identity
#######################################
PROJECT_KIND ?= core

CORE_NAME  := sms
CORE_ENTRY := app_main_smsplusgx

CORE_SMS := src/smsplus

CORE_C_SOURCES := \
$(CORE_SMS)/loadrom.c \
$(CORE_SMS)/render.c \
$(CORE_SMS)/sms.c \
$(CORE_SMS)/state.c \
$(CORE_SMS)/vdp.c \
$(CORE_SMS)/pio.c \
$(CORE_SMS)/tms.c \
$(CORE_SMS)/memz80.c \
$(CORE_SMS)/system.c \
$(CORE_SMS)/cpu/z80.c \
$(CORE_SMS)/sound/emu2413.c \
$(CORE_SMS)/sound/fmintf.c \
$(CORE_SMS)/sound/sn76489.c \
$(CORE_SMS)/sound/sms_sound.c \
src/main_smsplusgx.c

CORE_C_INCLUDES := \
-I$(CORE_SMS) \
-I$(CORE_SMS)/cpu \
-I$(CORE_SMS)/sound \
-Isrc

# Relative path so Docker bind-mounts work (do NOT use $(abspath) — it
# bakes the host path into Make prerequisites / .d files). Do not name
# this SDK_ROOT: that env var is commonly set by Android SDK installs.
GNW_CORE_SDK ?= sdk
# Separate build trees so switching PROJECT_KIND does not reuse stale .o.
BUILD_DIR ?= build/$(PROJECT_KIND)

# Hot Z80 / FM / PSG / VDP .text in ITCM (see sms_core.ld).
CORE_LDSCRIPT := sms_core.ld
CORE_EXTRA_SEGMENTS := itcm:core_itcm

#######################################
# SDK bridge overrides (optional)
#######################################
# The SDK bridge (gw_core_bridge.c) provides default implementations for
# memcpy/memset/memmove/__aeabi_mem* and malloc/calloc/free/realloc.
# Define these to exclude the SDK versions and supply your own:
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMCPY — exclude memcpy only.
#       Memmove stays routed through the SDK bridge (Doom/fastmem needs it).
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMSET — exclude memset only.
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMMOVE — exclude memmove too (requires your
#       core to provide memmove).
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MEMOPS — back-compat: exclude the full memops
#       block (memcpy/memset/memmove + all __aeabi_mem* helpers).
#
#   GW_CORE_BRIDGE_DISABLE_SDK_MALLOC — exclude the malloc/calloc/free/
#       realloc wrappers that forward to the firmware ABI heap. Use this when
#       the core links its own allocator or needs a custom malloc/free path.
#
# To enable, add the define(s) to CORE_C_DEFS below, e.g.:
#   CORE_C_DEFS += -DGW_CORE_BRIDGE_DISABLE_SDK_MEMCPY
#   CORE_C_DEFS += -DGW_CORE_BRIDGE_DISABLE_SDK_MEMSET
#   CORE_C_DEFS += -DGW_CORE_BRIDGE_DISABLE_SDK_MALLOC

#######################################
# Kind-specific compile defs + packing
#######################################
ifeq ($(PROJECT_KIND),core)
# Match release-firmware layout of retro_emulator_file_t: COVERFLOW fields
# sit before cheat_* — CHEAT_CODES alone with COVERFLOW=0 misaligns pointers.
# SMS family has no cheat files (leave --cheat-ext unset / empty).
CORE_C_DEFS := \
-DPROJECT_KIND_CORE=1 \
-DCOVERFLOW=1 \
-DCHEAT_CODES=0 \
-DTARGET_GNW

PACKED_BIN := SmsPlusGX.bin

else ifeq ($(PROJECT_KIND),homebrew)
$(error This project is a dynamic core only (PROJECT_KIND=core))
else
$(error PROJECT_KIND must be 'core' (got '$(PROJECT_KIND)'))
endif

include $(GNW_CORE_SDK)/Makefile

PACK_CORE := $(GNW_CORE_SDK)/tools/pack_core.py

#######################################
# Packed header version
#######################################
# gnw_core_meta_t only stores major.minor.patch (0..255).
# CORE_VERSION is the full git describe string passed to the packer; it
# extracts the leading vX.Y.Z (NOTAG / missing tags → 0.0.0).
# Override: make CORE_VERSION=v1.2.3
CORE_VERSION ?= $(shell git describe --tags --dirty 2>/dev/null || echo NOTAG)

#######################################
# Pack — one binary, four launcher systems
#######################################
.PHONY: pack coleco_bios

COLECO_BIOS_BIN := bios/coleco/coleco.bin

coleco_bios: $(COLECO_BIOS_BIN)

# Same as the old firmware tree: extract the dedicated ELF section.
$(COLECO_BIOS_BIN): $(TARGET_ELF)
	$(V)mkdir -p $(dir $@)
	$(V)$(ECHO) [ BIOS ] $@
	$(V)$(CP) -O binary --only-section=.coleco_bios_data $< $@

pack: $(TARGET_BIN) $(COLECO_BIOS_BIN)
	$(V)$(ECHO) [ PACK CORE ] $(PACKED_BIN) version=$(CORE_VERSION)
	$(V)python3 $(PACK_CORE) \
		--elf $(TARGET_ELF) --bin $(TARGET_BIN) \
		--system name="Sega Master System",dirname=sms,pad_logo=src/assets/pad_sms.bmp,header_logo=src/assets/header_sms.bmp,ext=sms,parse=rom \
		--system name="Sega Game Gear",dirname=gg,pad_logo=src/assets/pad_gg.bmp,header_logo=src/assets/header_gg.bmp,ext=gg,parse=rom \
		--system name="Sega SG-1000",dirname=sg,pad_logo=src/assets/pad_sg.bmp,header_logo=src/assets/header_sg.bmp,ext=sg,parse=rom \
		--system name="Colecovision",dirname=col,pad_logo=src/assets/pad_col.bmp,header_logo=src/assets/header_col.bmp,ext=col,parse=rom \
		--logo-invert \
		--core-name "SMSPlus GX" \
		--version "$(CORE_VERSION)" \
		--out $(PACKED_BIN)

all: pack

# Read-only helpers for CI / scripts (make print-PROJECT_KIND, etc.).
.PHONY: print-PROJECT_KIND print-PACKED_BIN print-SIDECARS print-RO_BIN print-CORE_NAME print-DOCKER_IMAGE \
	print-TARGET_ELF print-TARGET_MAP print-CORE_VERSION
print-PROJECT_KIND:
	@echo $(PROJECT_KIND)
print-PACKED_BIN:
	@echo $(PACKED_BIN)
# The shared stage_release.py asks every project for RO_BIN: the extra
# device file installed beside the packed binary. Empty here.
# Extra device files installed beside PACKED_BIN, space separated.
print-SIDECARS:
	@echo $(SIDECARS)
print-RO_BIN:
	@echo $(RO_BIN)
print-CORE_NAME:
	@echo $(CORE_NAME)
print-DOCKER_IMAGE:
	@echo $(DOCKER_IMAGE)
print-TARGET_ELF:
	@echo $(TARGET_ELF)
print-TARGET_MAP:
	@echo $(BUILD_DIR)/$(CORE_NAME)_core.map
print-CORE_VERSION:
	@echo $(CORE_VERSION)

clean::
	$(V)rm -f $(PACKED_BIN) $(COLECO_BIOS_BIN)

#######################################
# Docker (same image as firmware repo)
#######################################
.PHONY: docker docker_pull docker_shell

RELEASE_VERSION ?= v1.5
DOCKER_REPOSITORY ?= sylverb/retro-go-sd-builder
DOCKER_IMAGE ?= $(DOCKER_REPOSITORY):$(RELEASE_VERSION)

DOCKER_TTY_FLAG := $(shell if [ -t 0 ]; then echo -it; else echo; fi)
# Host UID so build/ artifacts are not root-owned on the bind mount.
DOCKER_USER := $(shell id -u):$(shell id -g)
DOCKER_RUN := docker run --rm $(DOCKER_TTY_FLAG) \
	--user $(DOCKER_USER) \
	-v "$(CURDIR):/opt/workdir" \
	-w /opt/workdir \
	$(DOCKER_IMAGE)

docker:
	$(V)$(ECHO) "[ DOCKER ]" $(DOCKER_IMAGE) "PROJECT_KIND=$(PROJECT_KIND)"
	$(V)$(DOCKER_RUN) make --no-print-directory -j$$(nproc) PROJECT_KIND=$(PROJECT_KIND)

docker_pull:
	$(V)$(ECHO) "[ PULL ]" $(DOCKER_IMAGE)
	$(V)docker pull $(DOCKER_IMAGE)

docker_shell:
	$(DOCKER_RUN) bash

#######################################
# Host SDL (Linux / macOS)
#######################################
include host/Makefile.host
