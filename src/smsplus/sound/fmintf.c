/*
  fmintf.c --
  Interface to EMU2413 (YM2413) emulator.
  MAME YM2413 path left disabled — EMU2413 is lighter on Cortex-M7.
  OPLL state lives in DTCM (dtc_calloc); reuse one instance across reinits.
*/
#include "shared.h"

static OPLL *opll;
FM_Context fm_context;

void FM_Init(void)
{
  if (snd.fm_which != SND_EMU2413)
    return;

  OPLL_init(snd.fm_clock, snd.sample_rate);
  if (opll == NULL)
  {
    opll = OPLL_new();
  }
  else
  {
    OPLL_reset(opll);
    OPLL_reset_patch(opll, 0);
  }
}

void FM_Shutdown(void)
{
  /* DTCM bump has no free — keep opll for the next FM_Init. */
}

void FM_Reset(void)
{
  if (snd.fm_which != SND_EMU2413 || !opll)
    return;

  OPLL_reset(opll);
  OPLL_reset_patch(opll, 0);
}

void FM_Update(int16 **buffer, int length)
{
  if (snd.fm_which != SND_EMU2413 || !opll)
    return;

  OPLL_update(opll, buffer, length);
}

void FM_Write(int offset, int data)
{
  if (offset & 1)
    fm_context.reg[fm_context.latch & 0x3F] = data;
  else
    fm_context.latch = data;

  if (snd.fm_which != SND_EMU2413 || !opll)
    return;

  OPLL_write(opll, offset & 1, data);
}

void FM_GetContext(uint8 *data)
{
  memcpy(data, &fm_context, sizeof(FM_Context));
}

void FM_SetContext(uint8 *data)
{
  int i;
  uint8 *reg = fm_context.reg;

  memcpy(&fm_context, data, sizeof(FM_Context));

  /* Lazy FM: re-enable synthesis when a save carries YM2413 register state. */
  if (!sms.use_fm && snd.fm_which == SND_EMU2413)
  {
    int i;
    for (i = 0; i < 0x40; i++)
    {
      if (fm_context.reg[i])
      {
        sms.use_fm = 1;
        break;
      }
    }
  }

  /* If we are loading a save state, we want to update the YM2413 context
     but not actually write to the current YM2413 emulator. */
  if (!snd.enabled || !sms.use_fm)
    return;

  FM_Write(0, 0x0E);
  FM_Write(1, reg[0x0E]);

  for (i = 0x00; i <= 0x07; i++)
  {
    FM_Write(0, i);
    FM_Write(1, reg[i]);
  }

  for (i = 0x10; i <= 0x18; i++)
  {
    FM_Write(0, i);
    FM_Write(1, reg[i]);
  }

  for (i = 0x20; i <= 0x28; i++)
  {
    FM_Write(0, i);
    FM_Write(1, reg[i]);
  }

  for (i = 0x30; i <= 0x38; i++)
  {
    FM_Write(0, i);
    FM_Write(1, reg[i]);
  }

  FM_Write(0, fm_context.latch);
}

int FM_GetContextSize(void)
{
  return sizeof(FM_Context);
}

uint8 *FM_GetContextPtr(void)
{
  return (uint8 *)&fm_context;
}
