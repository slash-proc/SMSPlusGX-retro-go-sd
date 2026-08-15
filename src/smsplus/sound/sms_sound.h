/******************************************************************************
 *  Sega Master System / GameGear Emulator
 *  Copyright (C) 1998-2007  Charles MacDonald
 *
 *  additionnal code by Eke-Eke (SMS Plus GX)
 *
 *   Sound emulation.
 *
 ******************************************************************************/

#ifndef _SOUND_H_
#define _SOUND_H_

#define snd sms_snd
#define snd_t sms_snd_t

enum {
  STREAM_PSG_L, /* PSG left channel */
  STREAM_PSG_R, /* PSG right channel */
  STREAM_FM_MO, /* YM2413 melody channel */
  STREAM_FM_RO, /* YM2413 rhythm channel */
  STREAM_MAX    /* Total # of sound streams */
};

/* Sound emulation structure */
typedef struct
{
  void (*mixer_callback)(int16 **stream, int16 **output, int length);
  int16 *output[2];
  int16 *stream[STREAM_MAX];
  int fm_which;
  int enabled;
  int fps;
  int buffer_size;
  int sample_count;
  int sample_rate;
  int done_so_far;
  uint32 fm_clock;
  uint32 psg_clock;
} snd_t;


/* Global data */
extern snd_t snd;

/* Function prototypes */
void psg_write(int data);
void psg_stereo_w(int data);
int fmunit_detect_r(void);
void fmunit_detect_w(int data);
void fmunit_write(int offset, int data);
int sound_init(void);
void sound_shutdown(void);
void sms_sound_reset(void);
void sound_update(int line);
void sound_mixer_callback(int16 **stream, int16 **output, int length);

#endif /* _SOUND_H_ */
