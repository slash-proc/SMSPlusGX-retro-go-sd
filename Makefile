# SMSPlus GX — Sega Master System / Game Gear / SG-1000 / Colecovision
# standalone dynamic core for Game & Watch Retro-Go SD.
#
#   make                  — build + pack → sms.bin
#   make docker           — same build inside Docker (no host toolchain)
#   make docker_shell     — interactive shell in the builder image
#
# Coleco BIOS is expected on the SD card at /bios/coleco/coleco.bin.
# Verbose compiler lines: make V=

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
# Pack — one binary, four launcher systems
#######################################
.PHONY: pack

pack: $(TARGET_BIN)
	$(V)$(ECHO) [ PACK CORE ] $(PACKED_BIN)
	$(V)python3 $(PACK_CORE) \
		--elf $(TARGET_ELF) --bin $(TARGET_BIN) \
		--system name="Sega Master System",dirname=sms,pad_logo=src/assets/pad_sms.bmp,header_logo=src/assets/header_sms.bmp,ext=sms,parse=rom \
		--system name="Sega Game Gear",dirname=gg,pad_logo=src/assets/pad_gg.bmp,header_logo=src/assets/header_gg.bmp,ext=gg,parse=rom \
		--system name="Sega SG-1000",dirname=sg,pad_logo=src/assets/pad_sg.bmp,header_logo=src/assets/header_sg.bmp,ext=sg,parse=rom \
		--system name="Colecovision",dirname=col,pad_logo=src/assets/pad_col.bmp,header_logo=src/assets/header_col.bmp,ext=col,parse=rom \
		--logo-invert \
		--core-name "SMSPlus GX" \
		--version 1.0.0 \
		--out $(PACKED_BIN)

all: pack

# Read-only helpers for CI / scripts (make print-PROJECT_KIND, etc.).
.PHONY: print-PROJECT_KIND print-PACKED_BIN print-CORE_NAME print-DOCKER_IMAGE
print-PROJECT_KIND:
	@echo $(PROJECT_KIND)
print-PACKED_BIN:
	@echo $(PACKED_BIN)
print-CORE_NAME:
	@echo $(CORE_NAME)
print-DOCKER_IMAGE:
	@echo $(DOCKER_IMAGE)

clean::
	$(V)rm -f $(PACKED_BIN)

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
