# SMSPlus GX — Retro-Go SD dynamic core

Standalone **SMS / Game Gear / SG-1000 / Colecovision** emulator core for
[Game & Watch Retro-Go SD](https://github.com/sylverb/game-and-watch-retro-go-sd).

One freestanding Cortex-M7 binary (`SmsPlusGX.bin`) is loaded from `/cores/` and
registers four launcher systems. It talks to the firmware **only** through
`gw_firmware_abi_t` (vendored under `sdk/`).

| System | SD ROM dir | Extension |
|--------|------------|-----------|
| Sega Master System | `/roms/sms/` | `.sms` |
| Sega Game Gear | `/roms/gg/` | `.gg` |
| Sega SG-1000 | `/roms/sg/` | `.sg` |
| Colecovision | `/roms/col/` | `.col` |

Colecovision: the install zip also ships `/bios/coleco/coleco.bin`
(`objcopy --only-section=.coleco_bios_data` from the linked ELF).

Engine: [SMSPlus GX](src/smsplus/) (vendored). Porting entry:
`src/main_smsplusgx.c`.

## Requirements

**Local build**

- `arm-none-eabi-gcc` (v10+, hard-float `fpv5-d16`)
- GNU Make
- Python 3 + Pillow (`pip install -r requirements.txt`) for logo packing

**Host SDL preview** (optional, Linux / macOS)

- Native C compiler (`cc` / clang / gcc)
- pkg-config
- SDL2 (`libsdl2-dev` / `brew install sdl2`) or SDL3 (`HOST_SDL=3`)

**Docker build** (no host toolchain)

- Docker
- Image [`sylverb/retro-go-sd-builder`](https://hub.docker.com/r/sylverb/retro-go-sd-builder)
  (default tag `v1.5`)

## Build

```bash
make
# or: make docker
```

The packed header version is taken from `git describe --tags --dirty`
(`CORE_VERSION`; override with `make CORE_VERSION=v1.2.3`). No tags →
`NOTAG` → header `0.0.0`. Release tags should be `vX.Y.Z`.

Produces `SmsPlusGX.bin` → copy to `/cores/SmsPlusGX.bin` on the SD card.

Useful Docker targets:

- `make docker` — build + pack in the builder image
- `make docker_pull` — refresh the image from Docker Hub
- `make docker_shell` — interactive shell in the same mount

## Host preview (SDL)

Compile the same sources into a desktop binary for faster iteration
(no G&W flash cycle). This does not replace the ARM pack for the device.

```bash
make host                       # SDL2 → ./sms_host
make host HOST_SDL=3            # SDL3 (needs sdl3.pc)
./sms_host /path/to/rom.sms     # optional ROM (or HOST_ROM=…)
```

On macOS, if `pkg-config sdl2` fails, point it at Homebrew:

```bash
export PKG_CONFIG_PATH="$(brew --prefix)/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
```

Controls: arrows = D-pad, `Z`/`X` = B/A, Enter = Start, Shift = Select.
`F1` = save state, `F2` = load state (files under `./host_saves/`).
Scale with `HOST_SCALE=2` (default).

## Features

- Save states (pause menu)
- Screenshots
- Audio at 48 kHz (mono DMA half-buffers)
- YM2413 FM (Mark III / Japanese SMS) via EMU2413
- No cheat files (SMS family)
- Hot Z80 / FM / PSG / VDP `.text` in ITCM; LUT / FM scratch in DTCM

## Layout

```
Makefile                 Build + multi-system pack + docker + host
sms_core.ld              RAM_EMU + ITCM hot segment
src/main_smsplusgx.c     Core entry / frame loop / blit / audio
src/smsplus/             SMSPlus GX engine
src/assets/              Pad + header logos (per system)
sdk/                     ABI bridge, headers, linker scripts, packers
host/                    SDL host preview (stubs, shim, Makefile.host)
scripts/                 Sync helper, release staging, addr2line helper
```

ITCM (~55 KiB): Z80, EMU2413, SN76489, sound mixer, memz80, VDP.  
DTCM (`dtc_malloc`): SMS/GG sprite lut **or** TMS tables, FM tables + OPLL
state, audio stream buffers.  
AHB: cart SRAM. RAM_EMU BSS: `glob_bp_lut`, Z80 flag tables, framebuffer.

Firmware seeds `ram_start` after load — do not re-seed it in the core.
Call `ram_init()` to rewind the bump if needed. See `CLAUDE.md` for the
full memory map (including optional LUT8 / `RAM_UC` bonus pool).

## Releases (GitHub tags `v*`)

Pushing a tag `vX.Y.Z` (with a matching `## [vX.Y.Z]` section in
`CHANGELOG.md`) creates a GitHub Release with **two** zip assets:

| Asset | Contents |
|-------|----------|
| `SmsPlusGX-vX.Y.Z.zip` | SD layout: `cores/SmsPlusGX.bin` + `bios/coleco/coleco.bin` |
| `SmsPlusGX-vX.Y.Z-debug.zip` | `*_core.elf`, linker `.map`, and a short README |

Unzip the install archive onto the SD card root. For a crash PC/LR:

```bash
unzip SmsPlusGX-v1.0.0-debug.zip
arm-none-eabi-addr2line -e sms_core.elf -f -C -a 0x<PC> 0x<LR>
```

Or: `python3 scripts/resolve_addr.py --elf …` — see the README inside the
debug zip.

## ABI compatibility

See `SDK_VERSION` for the firmware snapshot this tree was cut from. Refresh:

```bash
./scripts/sync_from_firmware.sh /path/to/game-and-watch-retro-go-sd
```

## License

Build glue is MIT (see `LICENSE`). `src/smsplus/` keeps its upstream license
(see `src/smsplus/LICENSE`). Vendored files under `sdk/include/` keep their
upstream licenses (firmware / HAL / FatFs / etc.).
