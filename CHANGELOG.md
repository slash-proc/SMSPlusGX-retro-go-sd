# Changelog

## [v0.0.2]

### Fixed

- Game Gear Micro Machines 1 & 2: keep the ROM-header console (GG) when the
  game DB would force SMS2 (wrong VDP/IO → purple screen / hardfault).
- Host `crc32_le` so Codemasters mapper lookup works under `make host`
  (SMS Micro Machines).
- SMS blit for 224/240-line viewports (centered letterbox instead of broken
  fixed 256×192 scaler).
- Black screen on 40K/48K SG-1000 Multivision dumps (e.g. 007 James Bond): map
  `$8000–$BFFF` to cartridge ROM when the image is larger than 32K.

### Changed

- Lazy YM2413: games detect FM via port `$F2` and enable synthesis on first
  register write; PSG-only titles skip `FM_Update` CPU cost.
- Match audio half-buffer length and LCD refresh to 50/60 Hz from the ROM
  header (PAL / NTSC).
- SMS scaling modes from the launcher: Off (1:1 centered), Fit (classic 5:6
  → ~307×230), Full (4:5 → 320×240). GG keeps integer 2× / 5:3 fill; Off uses
  1:1 centered.
- Skip frame present while an LCD swap is still pending (reduces RGB565 tear
  without blocking on VBLANK against `sound_sync`).

## [v0.0.1]

### Added

- SMSPlus GX dynamic core: SMS, Game Gear, SG-1000, and Colecovision in one
  packed `SmsPlusGX.bin` (four launcher systems).
- Vendored engine under `src/smsplus/` and porting entry `src/main_smsplusgx.c`.
- Per-system pad/header logos under `src/assets/`.
- YM2413 FM sound (EMU2413) for Master System / Mark III FM games (Japanese
  SMS built-in FM and compatible titles).
- Hot Z80 / FM / PSG / VDP code in ITCM; LUT / FM / audio scratch via
  `dtc_malloc` (DTCM).
- SDL host preview (`make host`) from the updated Retro-Go SD template.
- Tag-driven packed version (`CORE_VERSION` / `git describe`) and install +
  debug release zips.
- Coleco BIOS extracted from the linked ELF (`.coleco_bios_data` via
  `objcopy`) and included in the install zip as `bios/coleco/coleco.bin`.

### Changed

- Project identity: `CORE_NAME=sms`, entry `app_main_smsplusgx` (was Example
  template).
- Core-only project (`PROJECT_KIND=homebrew` is no longer supported here).
- Synced SDK / packers / CI / docs from `retro-go-sd-templates` (LUT8 / RAM_UC
  docs, bridge memops overrides, C++ heap helpers, release staging).

### Install

- Unzip the release archive onto the SD card root (`cores/SmsPlusGX.bin` and
  `bios/coleco/coleco.bin`).
- Place ROMs under `/roms/sms/`, `/roms/gg/`, `/roms/sg/`, `/roms/col/`.
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.

## [v1.0.0] - 2026-08-12

Initial template release (Example core / homebrew skeleton).
