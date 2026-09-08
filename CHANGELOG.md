# Changelog

## [v0.0.4] - 2026-09-08

### Changed

- The ColecoVision boot ROM is now published by this project rather than asked
  of the user. It was always here: `src/smsplus/coleco_bios.h` compiles the
  8 KB ROM into a `.coleco_bios_data` section and `make coleco_bios` objcopies
  it back out, which is how the old install zip shipped `bios/coleco/coleco.bin`.
  The manifest entry carried no `url`, so an installer told the user to go and
  find a file the repository already contains. The release now attaches
  `coleco.bin` and `make_manifest.py --bios` fills in its `url`, `bytes` and
  `sha256` from the file itself, which makes it a mirrored, hash-checked
  artifact like every other published file and drops it from what the user has
  to supply.

## [v0.0.3] - 2026-09-08

### Added

- Published under the [GWRG distribution
  spec](https://github.com/slash-proc/gwrg-dist-spec): a `manifest.json`
  describing this core and the four systems it provides, an offline bundle, and
  a GitHub Pages mirror of `dist/` that a web installer can read without a
  human in the loop.
- `symbols[]` publishes the linked ELF so a crash address from a device can be
  resolved back to a function. It is named by the manifest and mirrored, but is
  not part of the install set and never reaches the card.
- `gwrg.json`, the hand-written half of the manifest: the short console name
  for each system and whether compressed ROMs work. Everything else -- the
  systems, their folders, extensions and browse mode, the firmware ABI, sizes
  and hashes -- is derived from the packed binary at release time, so the
  manifest and the firmware cannot disagree about which folder a system reads.
- Master System, Game Gear, SG-1000 and ColecoVision are declared as four
  systems from one binary, keyed by the `sms`, `gg`, `sg` and `col` folders the
  packed core names.
- ColecoVision declares `biosDir: coleco`, because its ROM folder is `col` but
  its boot ROM is read from `/bios/coleco/`. A consumer cannot derive one key
  from the other, and guessing `bios/col` would put the file somewhere nothing
  looks for it. The entry is marked optional: this core carries a copy of the
  boot ROM in its own binary and plays ColecoVision games without the file.

### Changed

- `scripts/make_manifest.py`, `build_dist.py`, `make_bundle.py` and
  `stage_release.py` are now the shared copies, byte-identical across every
  project. A script that has to be edited on the way in is a script that
  drifts.
- The Makefile answers `print-SIDECARS` and `print-RO_BIN`. The shared
  `stage_release.py` reads Makefile variables positionally, so a missing
  `print-` target does not degrade gracefully -- it fails the release outright.
  This core installs no file beside the packed binary, so both are empty.

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
