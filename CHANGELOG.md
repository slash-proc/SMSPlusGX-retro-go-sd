# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Release tags must
match a section heading exactly (for example `v1.0.0`).

When you cut a release:

1. Move items from `[Unreleased]` into a new `## [vX.Y.Z] - YYYY-MM-DD` section.
2. Commit the changelog update.
3. Push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

CI reads the matching section and uses it as the GitHub Release notes. Assets
attached to the release:

- `<binary>-<tag>.zip` — SD layout (`cores/` + packed `.bin`, plus
  `bios/coleco/coleco.bin` for Colecovision)
- `<binary>-<tag>-debug.zip` — ELF + linker map (use `arm-none-eabi-addr2line` for crash PC/LR → function/line)

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
