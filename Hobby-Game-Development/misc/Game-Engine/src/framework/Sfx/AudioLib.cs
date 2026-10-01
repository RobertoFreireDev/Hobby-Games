using blackbox.Utils;
using Microsoft.Xna.Framework.Audio;
using System;
using System.Linq;

namespace blackbox.Sfx;

public static class AudioLib
{
    private static SfxChannel[] Channels = new SfxChannel[Constants.ChannelQty];
    private static DynamicSoundEffectInstance Sound;
    private const int SampleRate = 44100;
    private const float FadeInSeconds = 0.01f;
    private const float FadeOutSeconds = 0.01f;

    public static void CreateSound()
    {
        for (int i = 0; i < Channels.Length; i++)
            Channels[i] = new SfxChannel();

        Sound = new DynamicSoundEffectInstance(SampleRate, AudioChannels.Mono);
        Sound.BufferNeeded += OnBufferNeeded;

        // Pre-fill buffers to avoid starvation
        int bufferSize = SampleRate / 30 * 2;
        Sound.SubmitBuffer(new byte[bufferSize]);
        Sound.SubmitBuffer(new byte[bufferSize]);

        Sound.Play();
    }

    public static void Play(SfxData sfx)
    {
        var ch = Channels.FirstOrDefault(c => !c.Playing);
        if (ch == null)
            return;

        ch.CurrentSfx = sfx;
        ch.Position = 0;
        ch.Time = 0;
        ch.Playing = true;
        ch.Phase = 0;
        ch.CurrentSample = 0;

        // total samples for fades
        float secondsPerNote = sfx.Speed * Constants.SpeedSfx;
        ch.TotalSamples = (int)(sfx.Notes.Length * secondsPerNote * SampleRate);
    }

    private static void OnBufferNeeded(object sender, EventArgs e)
    {
        int samples = SampleRate / 30; // ~33 ms
        float[] mixBuffer = new float[samples];

        GenerateAudio(mixBuffer, samples);

        byte[] byteBuffer = new byte[samples * 2];
        int index = 0;

        for (int i = 0; i < samples; i++)
        {
            short sample = (short)(Math.Clamp(mixBuffer[i], -1f, 1f) * short.MaxValue);
            byteBuffer[index++] = (byte)(sample & 0xFF);
            byteBuffer[index++] = (byte)((sample >> 8) & 0xFF);
        }

        Sound.SubmitBuffer(byteBuffer);
    }

    private static void GenerateAudio(float[] buffer, int samples)
    {
        Array.Clear(buffer, 0, samples);

        float masterGain = 1f / Channels.Length;

        for (int chIndex = 0; chIndex < Channels.Length; chIndex++)
        {
            var ch = Channels[chIndex];
            if (!ch.Playing || ch.CurrentSfx == null)
                continue;

            var sfx = ch.CurrentSfx;
            float secondsPerNote = sfx.Speed * Constants.SpeedSfx;

            // cache state locally
            double time = ch.Time;
            double phase = ch.Phase;
            int position = ch.Position;
            int currentSample = ch.CurrentSample;
            bool playing = ch.Playing;

            for (int i = 0; i < samples; i++)
            {
                time += 1.0 / SampleRate;
                currentSample++;

                if (time >= secondsPerNote)
                {
                    time -= secondsPerNote;
                    position++;

                    if (position >= sfx.Notes.Length)
                    {
                        playing = false;
                        break;
                    }
                }

                var note = sfx.Notes[position];
                float freq = PitchToFrequency(note.Pitch);

                phase += freq / SampleRate;
                phase -= Math.Floor(phase);

                float sample = GenerateWave(note.Wave, phase, note.Volume);

                // Fade-in / fade-out
                float gain = 1f;
                int fadeInSamples = (int)(FadeInSeconds * SampleRate);
                int fadeOutSamples = (int)(FadeOutSeconds * SampleRate);

                if (currentSample < fadeInSamples)
                    gain = currentSample / (float)fadeInSamples;
                else if (currentSample > ch.TotalSamples - fadeOutSamples)
                    gain = (ch.TotalSamples - currentSample) / (float)fadeOutSamples;

                buffer[i] += sample * gain * masterGain;
            }

            // write back state ONCE
            ch.Time = time;
            ch.Phase = phase;
            ch.Position = position;
            ch.CurrentSample = currentSample;
            ch.Playing = playing;
        }

        // safety normalize
        float max = 0f;
        for (int i = 0; i < samples; i++)
            max = Math.Max(max, Math.Abs(buffer[i]));

        if (max > 1f)
        {
            float scale = 1f / max;
            for (int i = 0; i < samples; i++)
                buffer[i] *= scale;
        }
    }

    private static float PitchToFrequency(int pitch)
    {
        return 440f * (float)Math.Pow(2, (pitch - 69) / 12.0);
    }

    static int noiseCounter = 0;
    static int noiseRate = 8;          // adjust as needed
    static float noiseValue = 0f;
    static readonly Random rng = new Random();

    private static float GenerateWave(Waveform wave, double phase, float volume)
    {
        // phase is normalized [0..1)
        double p = phase * Math.PI * 2.0; // convert to radians
        double sample = 0.0;

        switch (wave)
        {
            case Waveform.Square:
                sample = Math.Sin(p) >= 0 ? 1.0 : -1.0;
                break;

            case Waveform.Triangle:
                // Proper bipolar triangle [-1..1]
                sample = 2.0 * Math.Abs(2.0 * phase - 1.0) - 1.0;
                break;

            case Waveform.Saw:
                sample = 2.0 * phase - 1.0;
                break;

            case Waveform.TiltedSaw:
                sample = phase < 0.5
                    ? (-1.0 + phase * 4.0)
                    : (1.0 - (phase - 0.5) * 2.0);
                break;

            case Waveform.Pulser:
                {
                    int step = (int)(phase * 32.0) % 32;
                    int duty = 6;
                    sample = step < duty ? 1.0 : -1.0;
                    break;
                }

            case Waveform.Organ:
                sample =
                    1.00 * Math.Sin(p) +
                    0.50 * Math.Sin(p * 2.0) +
                    0.30 * Math.Sin(p * 3.0) +
                    0.20 * Math.Sin(p * 4.0) +
                    0.10 * Math.Sin(p * 6.0);
                sample *= 0.25;
                break;

            case Waveform.Phaser:
                {
                    double lfo = 0.5 * Math.Sin(p * 0.5 + Math.PI / 2.0);
                    sample = Math.Sin(p + lfo * 3.0);
                    break;
                }

            case Waveform.Noise:
                noiseCounter++;
                if (noiseCounter >= noiseRate)
                {
                    noiseCounter = 0;
                    noiseValue = (float)(rng.NextDouble() * 2.0 - 1.0);
                }
                sample = noiseValue;
                break;
        }

        return (float)(sample * volume);
    }
}
