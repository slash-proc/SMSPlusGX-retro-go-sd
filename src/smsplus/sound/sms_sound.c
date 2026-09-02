/******************************************************************************
 *  Sega Master System / GameGear Emulator
 *  Copyright (C) 1998-2007  Charles MacDonald
 *
 *  additionnal code by Eke-Eke (SMS Plus GX)
 *
 *   Sound emulation.
 *
 ******************************************************************************/

#include "shared.h"
#include "gw_malloc.h"

snd_t snd;
static int16 **fm_buffer;
static int16 **psg_buffer;
int smptab[313];
int smptab_len;


int sound_init(void)
{
  FM_Context fmbuf;
  SN76489_Context psgbuf;
  int restore_sound = 0;
  int i;

  snd.fm_which = option.fm;
  snd.fps = (sms.display == DISPLAY_NTSC) ? FPS_NTSC : FPS_PAL;
  snd.fm_clock = (sms.display == DISPLAY_NTSC) ? CLOCK_NTSC : CLOCK_PAL;
  snd.psg_clock = (sms.display == DISPLAY_NTSC) ? CLOCK_NTSC : CLOCK_PAL;
  snd.sample_rate = option.sndrate;
  snd.mixer_callback = NULL;

  /* Save register settings */
  if(snd.enabled)
  {
    restore_sound = 1;

    memcpy(&psgbuf, SN76489_GetContextPtr(0), SN76489_GetContextSize());
    FM_GetContext((uint8 *)&fmbuf);
  }

  /* If we are reinitializing, shut down sound emulation */
  if(snd.enabled)
  {
    sound_shutdown();
  }

  /* Disable sound until initialization is complete */
  snd.enabled = 0;

  /* Check if sample rate is invalid */
  if(snd.sample_rate < 8000 || snd.sample_rate > 48000)
  {
      abort();
  }

  /* Assign stream mixing callback if none provided */
  if(!snd.mixer_callback)
    snd.mixer_callback = sound_mixer_callback;

  /* Calculate number of samples generated per frame */
  snd.sample_count = (snd.sample_rate / snd.fps) + 1;
  printf("%s: sample_count=%d fps=%d (actual=%f)\n", __func__, snd.sample_count, snd.fps, (float)snd.sample_rate / (float)snd.fps);

  /* Calculate size of sample buffer */
  snd.buffer_size = snd.sample_count * 2;
  printf("%s: snd.buffer_size=%d\n", __func__, snd.buffer_size);

  /* Prepare incremental info */
  snd.done_so_far = 0;
  smptab_len = (sms.display == DISPLAY_NTSC) ? 262 : 313;

  for(i = 0; i < smptab_len; i++)
  {
    double calc = (snd.sample_count * i);
    calc = calc / (double)smptab_len;
    smptab[i] = (int)calc;
  }

  /* Allocate emulated sound streams (DTCM) — reuse across reinits */
  for(i = 0; i < STREAM_MAX; i++)
  {
    if (!snd.stream[i])
    {
      snd.stream[i] = dtc_calloc(snd.buffer_size, 1);
      if(!snd.stream[i]) abort();
    }
    else
      memset(snd.stream[i], 0, snd.buffer_size);
  }

  /* Allocate sound output streams (DTCM) */
  if (!snd.output[0])
  {
    snd.output[0] = dtc_calloc(snd.buffer_size, 1);
    snd.output[1] = dtc_calloc(snd.buffer_size, 1);
    if(!snd.output[0] || !snd.output[1]) abort();
  }
  else
  {
    memset(snd.output[0], 0, snd.buffer_size);
    memset(snd.output[1], 0, snd.buffer_size);
  }

  /* Set up buffer pointers */
  fm_buffer = (int16 **)&snd.stream[STREAM_FM_MO];
  psg_buffer = (int16 **)&snd.stream[STREAM_PSG_L];

  /* Set up SN76489 emulation */
  SN76489_Init(0, snd.psg_clock, snd.sample_rate);
  SN76489_Config(0, MUTE_ALLON, BOOST_OFF /*BOOST_ON*/, VOL_FULL, (sms.console < CONSOLE_SMS) ? FB_SC3000 : FB_SEGAVDP);

  /* Set up YM2413 emulation (no-op when option.fm == SND_NONE) */
  FM_Init();

  /* Restore register settings */
  if(restore_sound)
  {
    memcpy(SN76489_GetContextPtr(0), &psgbuf, SN76489_GetContextSize());
    FM_SetContext((uint8 *)&fmbuf);
  }

  /* Inform other functions that we can use sound */
  snd.enabled = 1;

  return 1;
}


void sound_shutdown(void)
{
  if(!snd.enabled)
    return;

  /* DTCM bump has no free — keep stream/output pointers for reuse. */

  /* Shut down SN76489 emulation */
  SN76489_Shutdown();

  /* Shut down YM2413 emulation */
  FM_Shutdown();

  snd.enabled = 0;
}


void sms_sound_reset(void)
{
  if(!snd.enabled)
    return;

  /* Reset SN76489 emulator */
  SN76489_Reset(0);

  /* Reset YM2413 emulator */
  FM_Reset();
}


void sound_update(int line)
{
  int16 *psg[2];
  int16 *fm[2];

  if(!snd.enabled)
    return;

  /* Finish buffers at end of frame */
  if(line == smptab_len - 1)
  {
    psg[0] = psg_buffer[0] + snd.done_so_far;
    psg[1] = psg_buffer[1] + snd.done_so_far;
    fm[0]  = fm_buffer[0] + snd.done_so_far;
    fm[1]  = fm_buffer[1] + snd.done_so_far;

    /* Generate SN76489 sample data */
    SN76489_Update(0, psg, snd.sample_count - snd.done_so_far);

    /* Generate YM2413 sample data */
    if (sms.use_fm)
      FM_Update(fm, snd.sample_count - snd.done_so_far);

    /* Mix streams into output buffer */
    snd.mixer_callback(snd.stream, snd.output, snd.sample_count);

    /* Reset */
    snd.done_so_far = 0;
  }
  else
  {
    int tinybit;

    tinybit = smptab[line] - snd.done_so_far;

    /* Do a tiny bit */
    psg[0] = psg_buffer[0] + snd.done_so_far;
    psg[1] = psg_buffer[1] + snd.done_so_far;
    fm[0]  = fm_buffer[0] + snd.done_so_far;
    fm[1]  = fm_buffer[1] + snd.done_so_far;

    /* Generate SN76489 sample data */
    SN76489_Update(0, psg, tinybit);

    /* Generate YM2413 sample data */
    if (sms.use_fm)
      FM_Update(fm, tinybit);

    /* Sum total */
    snd.done_so_far += tinybit;
  }
}

/* Generic FM+PSG stereo mixer callback */
void sound_mixer_callback(int16 **stream, int16 **output, int length)
{
  int i;
  for(i = 0; i < length; i++)
  {
    int32 temp = (int32)fm_buffer[0][i] + (int32)fm_buffer[1][i];
    temp /= 2;
    int32 l = ((int32)psg_buffer[0][i] + temp) * 275 / 100;
    int32 r = ((int32)psg_buffer[1][i] + temp) * 275 / 100;
    if (l > 32767) l = 32767;
    else if (l < -32768) l = -32768;
    if (r > 32767) r = 32767;
    else if (r < -32768) r = -32768;
    output[0][i] = (int16)l;
    output[1][i] = (int16)r;
  }
}


/*--------------------------------------------------------------------------*/
/* Sound chip access handlers                                               */
/*--------------------------------------------------------------------------*/

void psg_stereo_w(int data)
{
  if(!snd.enabled) return;
  SN76489_GGStereoWrite(0, data);
}

void stream_update(int which, int position)
{
}


void psg_write(int data)
{
  if(!snd.enabled) return;
  SN76489_Write(0, data);
}

/*--------------------------------------------------------------------------*/
/* Mark III FM Unit / Master System (J) built-in FM handlers                */
/*--------------------------------------------------------------------------*/

int fmunit_detect_r(void)
{
  return sms.fm_detect;
}

void fmunit_detect_w(int data)
{
  if (!snd.enabled)
    return;
  sms.fm_detect = data;
}

void fmunit_write(int offset, int data)
{
  if (!snd.enabled)
    return;
  if (!sms.use_fm)
    sms.use_fm = 1;
  FM_Write(offset, data);
}
