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

Colecovision needs a BIOS at `/bios/coleco/coleco.bin`.

Engine: [SMSPlus GX](src/smsplus/) (vendored). Porting entry:
`src/main_smsplusgx.c`.

## Requirements

**Local build**

- `arm-none-eabi-gcc` (v10+, hard-float `fpv5-d16`)
- GNU Make
- Python 3 + Pillow (`pip install -r requirements.txt`) for logo packing

**Docker build** (no host toolchain)

- Docker
- Image [`sylverb/retro-go-sd-builder`](https://hub.docker.com/r/sylverb/retro-go-sd-builder)
  (default tag `v1.5`)

## Build

```bash
make
# or: make docker
```

Produces `SmsPlusGX.bin` → copy to `/cores/SmsPlusGX.bin` on the SD card.

Useful Docker targets:

- `make docker` — build + pack in the builder image
- `make docker_pull` — refresh the image from Docker Hub
- `make docker_shell` — interactive shell in the same mount

## Features

- Save states (pause menu)
- Screenshots
- Audio at 48 kHz (mono DMA half-buffers)
- YM2413 FM (Mark III / Japanese SMS) via EMU2413
- No cheat files (SMS family)

## Layout

```
Makefile                 Build + multi-system pack + docker
sms_core.ld              RAM_EMU + ITCM hot segment
src/main_smsplusgx.c     Core entry / frame loop / blit / audio
src/smsplus/             SMSPlus GX engine
src/assets/              Pad + header logos (per system)
sdk/                     ABI bridge, headers, linker scripts, packers
```

ITCM (~55 KiB): Z80, EMU2413, SN76489, sound mixer, memz80, VDP.  
DTCM (`dtc_malloc`): SMS/GG sprite lut **or** TMS tables, FM tables + OPLL
state, audio stream buffers.  
AHB: cart SRAM. RAM_EMU BSS: `glob_bp_lut`, Z80 flag tables, framebuffer.

## ABI compatibility

See `SDK_VERSION` for the firmware snapshot this tree was cut from. Refresh:

```bash
./scripts/sync_from_firmware.sh /path/to/game-and-watch-retro-go-sd
```

## License

Build glue is MIT (see `LICENSE`). `src/smsplus/` keeps its upstream license
(see `src/smsplus/LICENSE`). Vendored files under `sdk/include/` keep their
upstream licenses (firmware / HAL / FatFs / etc.).
