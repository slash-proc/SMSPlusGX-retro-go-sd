# Changelog

## [v0.0.7] - 2026-09-13

### Changed

- Publish conservative runtime save and savestate support metadata for LFS sizing.

## [v0.0.6] - 2026-09-11

### Fixed

- The manifest declares `biosDir` again, so an installer puts the ColecoVision
  boot ROM where the core reads it. `col` is the ROM folder key and `coleco`
  the BIOS folder key -- `main_sms.c` loads `/bios/coleco/coleco.bin` -- and
  `gwrg.json` has said so since the field existed. The shared manifest
  generator accepted the value, validated it, and then dropped it from the
  system it emitted, so every release up to v0.0.5 published a manifest with no
  `biosDir` at all and an installer wrote `coleco.bin` to `/bios/col/`. Since
  v0.0.4 this project ships that ROM itself, which means the install put a file
  in the wrong folder rather than merely asking for one there.

## [v0.0.5] - 2026-09-09

### Fixed

- The version index no longer counts a BIOS this project ships as a file the
  user must supply. `needsUserFiles` said true while the manifest implied
  false, because the index was built before the shared script learned the
  difference.

## [v0.0.4] - 2026-09-08

### Changed

- The manifest's `kind` is now `core`, not `emulator`. A core that emulates
  nothing -- Doom -- showed that the old word named a subset rather than the
  set, so the spec took the general term and the SDK and the spec now agree.
  The previous release publishes the old value and no longer validates.

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

- Video sync issue causing some unneeded frame skip.

### Changed

- Nothing.

### Install

- Unzip the release archive onto the SD card root (`cores/SmsPlusGX.bin` and
  `bios/coleco/coleco.bin`).
- Place ROMs under `/roms/sms/`, `/roms/gg/`, `/roms/sg/`, `/roms/col/`.
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.
