/*
 * SMSPlus GX core linker script — RAM_EMU + ITCM hot segment.
 *
 * ITCM holds CPU-hot .text (Z80, YM2413/EMU2413, PSG, sound, memz80, VDP).
 * Entry / bridge / main stay in RAM_EMU (same rationale as PCE).
 *
 * Data that used to fight for RAM_EMU BSS is allocated at runtime with
 * dtc_malloc (DTCM bump) — see main_smsplusgx.c / emu2413.c / render.c.
 */

INCLUDE gnw_ram_emu.ld
INCLUDE gnw_itcm_core.ld

MEMORY
{
  RAM_EMU (xrw) : ORIGIN = __RAM_EMU_START__, LENGTH = __RAM_EMU_LENGTH__
  ITCM    (xrw) : ORIGIN = __ITCM_CORE_START__, LENGTH = __ITCM_CORE_LENGTH__
}

/* Object paths match BUILD_DIR=build/core (flat names under that dir). */

SECTIONS
{
  .core_entry __RAM_EMU_START__ :
  {
    KEEP(*(.core_entry))
    KEEP(*(.gw_core_bridge_probe))

    . = ALIGN(4);
    EXCLUDE_FILE(
      build/core/z80.o
      build/core/emu2413.o
      build/core/sn76489.o
      build/core/sms_sound.o
      build/core/fmintf.o
      build/core/memz80.o
      build/core/vdp.o
    ) *(.text*)
    *(.rodata*)
    *(.glue_7)
    *(.glue_7t)

    . = ALIGN(4);
    __CORE_INIT_ARRAY_START__ = .;
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array*))
    __CORE_INIT_ARRAY_END__ = .;
  } >RAM_EMU

  .data :
  {
    *(.data*)
  } >RAM_EMU

  __CORE_CODE_END__ = .;

  .bss (NOLOAD) :
  {
    . = ALIGN(8);
    *(.bss*)
    *(COMMON)
    . = ALIGN(8);
  } >RAM_EMU

  __CORE_BSS_END__ = .;

  ASSERT(__CORE_BSS_END__ <= __RAM_EMU_END__,
         "Error: SMS core RAM_EMU segment (code+data+bss) overflows RAM_EMU")

  .core_itcm __ITCM_CORE_START__ :
  {
    __CORE_ITCM_CODE_START__ = .;
    build/core/z80.o(.text*)
    build/core/emu2413.o(.text*)
    build/core/sn76489.o(.text*)
    build/core/sms_sound.o(.text*)
    build/core/fmintf.o(.text*)
    build/core/memz80.o(.text*)
    build/core/vdp.o(.text*)
    . = ALIGN(4);
    __CORE_ITCM_CODE_END__ = .;
  } >ITCM AT>RAM_EMU

  __CORE_ITCM_BSS_END__ = __CORE_ITCM_CODE_END__;

  ASSERT(__CORE_ITCM_BSS_END__ <= __ITCM_CORE_START__ + __ITCM_CORE_LENGTH__,
         "Error: SMS core ITCM segment overflows the 64K ITCM region")

  __exidx_start = .;
  __exidx_end = .;

  /DISCARD/ :
  {
    *(.fini_array*)
    *(.preinit_array*)
    *(.ARM.exidx*)
    *(.ARM.extab*)
    *(.comment)
    *(.ARM.attributes)
  }
}
