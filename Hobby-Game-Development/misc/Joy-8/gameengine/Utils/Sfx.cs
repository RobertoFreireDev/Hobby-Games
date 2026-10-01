using System;
using System.Collections.Generic;
using System.Linq;
using gameengine.Data;
using Microsoft.Xna.Framework.Audio;

namespace gameengine.Utils;

public class Sfx
{
    private SoundEffectInstance[] sounds = new SoundEffectInstance[128];
    private const int SampleRate = 8000;
    private const int Channels = 1;

    public void Add(int index, List<Note> noteSequence, int multiplier)
    {
        if (noteSequence.Count == 0) return;

        float speedMultiplier = MathF.Max(1, MathF.Min(multiplier, 30));
        int totalSamples = 0;
        List<NoteData> sequence = new List<NoteData>();

        for (int i = 0; i < noteSequence.Count; i++)
        {
            var note = noteSequence[i];
            var prevNote = (i > 0) ? noteSequence[i - 1] : note;
            var nextNote = (i < noteSequence.Count - 1) ? noteSequence[i + 1] : note;

            note.Wave = note.Freq == 0 ? Waveforms.Sine : note.Wave;
            note.Freq = note.Wave == Waveforms.Organ || note.Wave == Waveforms.Phaser ? note.Freq * 3 : note.Freq;

            float effectiveDuration = 1f / speedMultiplier;
            int numSamples = (int)(SampleRate * effectiveDuration);

            int period = (int) (SampleRate / note.Freq);
            numSamples = (numSamples / period) * period;
            totalSamples += numSamples;

            sequence.Add(new NoteData
            {
                Wave = note.Wave,
                Freq = note.Freq,
                Period = period,
                Duration = effectiveDuration,
                NumSamples = numSamples,
                Volume = note.Volume,
                Effect = note.Effect,
                PrevFreq = prevNote.Freq,
                NextFreq = nextNote.Freq
            });
        }

        short[] buffer = new short[totalSamples];

        int sampleIndex = 0;
        foreach (var note in sequence)
        {
            for (int i = 0; i < note.NumSamples; i++)
            {
                float t = i / (float)SampleRate;
                float sample = 0;
                float sampleVolume = note.Volume;
                float currentFreq = note.Freq;

                switch (note.Effect)
                {
                    case Effect.Slide:
                        currentFreq = note.PrevFreq + (note.Freq - note.PrevFreq) * (i / (float)note.NumSamples);
                        break;
                    case Effect.Vibrato:
                        currentFreq = note.Freq * (1 + 0.02f * MathF.Sin(20 * MathF.PI * t));
                        break;
                    case Effect.Drop:
                        currentFreq = note.Freq * (1 - (i / (float)note.NumSamples));
                        break;
                    case Effect.FadeIn:
                        sampleVolume = note.Volume * (i / (float)note.NumSamples);
                        break;
                    case Effect.FadeOut:
                        sampleVolume = note.Volume * (1 - (i / (float)note.NumSamples));
                        break;
                    case Effect.Arpeggio:
                        float arpCycle = (i / (float)(note.NumSamples / 3)) % 3;
                        if (arpCycle < 1) currentFreq = note.PrevFreq;
                        else if (arpCycle < 2) currentFreq = note.Freq;
                        else currentFreq = note.NextFreq;
                        break;
                }

                switch (note.Wave)
                {
                    case Waveforms.Sine:
                        sample = MathF.Abs(MathF.Sin(2 * MathF.PI * currentFreq * t));
                        float stepSize = 0.05f;
                        sample = MathF.Floor(sample / stepSize + 0.5f) * stepSize;
                        break;
                    case Waveforms.Square:
                        sample = (MathF.Sin(2 * MathF.PI * currentFreq * t) >= 0) ? 1 : 0;
                        break;
                    case Waveforms.Saw:
                        sample = 2 * (t * currentFreq - MathF.Floor(t * currentFreq + 0.5f));
                        break;
                    case Waveforms.Noise:
                        sample = (float)(new Random().NextDouble() * 2 - 1);
                        break;
                    case Waveforms.Pulse:
                        float duty = note.Duty ?? 0.3f;
                        float phase = (t * currentFreq) % 1;
                        sample = (phase < duty) ? 1 : -1;
                        break;
                    case Waveforms.Organ:
                        float fundamental = MathF.Sin(2 * MathF.PI * currentFreq * t);
                        float secondHarmonic = 0.5f * MathF.Sin(2 * MathF.PI * currentFreq * 2 * t);
                        float thirdHarmonic = 0.33f * MathF.Sin(2 * MathF.PI * currentFreq * 3 * t);
                        sample = (fundamental + secondHarmonic + thirdHarmonic) / (1 + 0.5f + 0.33f);
                        break;
                    case Waveforms.Phaser:
                        float phaserSpeed = note.PhaserSpeed ?? 0.5f;
                        float phaserDepth = note.PhaserDepth ?? 0.5f;
                        float lfo = MathF.Sin(2 * MathF.PI * phaserSpeed * t);
                        float phaseOffset = lfo * phaserDepth * MathF.PI;
                        sample = MathF.Sin(2 * MathF.PI * currentFreq * t + phaseOffset);
                        break;
                }

                buffer[sampleIndex] = (short)(sample * sampleVolume * 32767 * 0.5f);
                sampleIndex++;
            }
        }

        // Convert short array to byte array
        byte[] byteBuffer = new byte[buffer.Length * 2];
        Buffer.BlockCopy(buffer, 0, byteBuffer, 0, byteBuffer.Length);

        // Create a SoundEffect from the buffer
        SoundEffect soundEffect = new SoundEffect(byteBuffer, SampleRate, (Channels == 1) ? AudioChannels.Mono : AudioChannels.Stereo);

        // Create a SoundEffectInstance to allow playback control
        SoundEffectInstance soundInstance = soundEffect.CreateInstance();

        // Store the instance for later playback
        sounds[index] = soundInstance;
    }

    public void StopAll()
    {
        foreach (var sound in sounds)
        {
            if (sound != null && sound.State == SoundState.Playing)
            {
                sound.Stop();
            }
        }
    }

    public void Play(int index)
    {
        if (index < sounds.Length)
        {
            sounds[index].Play();
        }
    }

    public static bool PauseMusic()
    {
        if (SfxData.Track is not null && SfxData.Track.State == SoundState.Playing)
        {
            SfxData.Track.Pause();
            return true;
        }

        return false;
    }

    public void StopMusic()
    {
        if (SfxData.Track is not null)
        {
            SfxData.Track.Stop();
            SfxData.Playing = false;
        }
    }

    public static void ResumeMusic()
    {
        if (SfxData.Track is not null && SfxData.Track.State == SoundState.Paused)
        {
            SfxData.Track.Resume();
        }
    }

    public void PlayMusic(List<Track> tracks)
    {
        SfxData.Music.Clear();

        foreach (var track in tracks)
        {
            SfxData.Music.Add(new Track()
            {
                SoundIndex = track.SoundIndex,
                Back = track.Back,
                Forth = track.Forth,
                Stop = track.Stop,
            });
        }


        SfxData.CurrentIndex = 0;
        SfxData.Playing = true;
    }

    private void PlayNext()
    {
        if (SfxData.Music.Count > 0 && SfxData.Playing)
        {
            sounds[SfxData.Music[SfxData.CurrentIndex].SoundIndex].Play();
            SfxData.Track = sounds[SfxData.Music[SfxData.CurrentIndex].SoundIndex];
            if (SfxData.Music[SfxData.CurrentIndex].Stop)
            {
                SfxData.CurrentIndex = 0;
                SfxData.Playing = false;
                return;
            }
            
            if (SfxData.Music[SfxData.CurrentIndex].Back)
            {
                for (int i= SfxData.CurrentIndex - 1; i >= 0; i--)
                {
                    if (SfxData.Music[i].Forth)
                    {
                        SfxData.CurrentIndex = i;
                        break;
                    }

                    if (i == 0)
                    {
                        SfxData.CurrentIndex = 0;
                    }
                }
                return;
            }

            SfxData.CurrentIndex++;

            if (SfxData.CurrentIndex >= SfxData.Music.Count)
            {
                SfxData.CurrentIndex = 0;
                SfxData.Playing = false;
                return;
            }
        }
    }

    public void Update()
    {
        if (SfxData.Music.Count > 0 && SfxData.Playing && (SfxData.Track is null || SfxData.Track.State == SoundState.Stopped))
        {
            PlayNext();
        }
    }
}

public class Track
{
    public int SoundIndex;

    public bool Back;

    public bool Forth;

    public bool Stop;
}

public static class Waveforms
{
    public const string Square = "square";
    public const string Sine = "sine";
    public const string Saw = "saw";
    public const string Noise = "noise";
    public const string Pulse = "pulse";
    public const string Organ = "organ";
    public const string Phaser = "phaser";

    private static readonly string[] WaveformArray = { Square, Sine, Saw, Noise, Pulse, Organ, Phaser };

    public static string GetWaveform(int index)
    {
        if (index < 0 || index >= WaveformArray.Length)
        {
            return Square;
        }
        return WaveformArray[index];
    }
}

public static class Pentatonic
{
    public static readonly Dictionary<string, string[]> ScaleValues = new()
    {
        { "CMajor", new[] { "C", "D", "E", "G", "A" } },
        { "CsMajor", new[] { "Cs", "Ds", "F", "Gs", "As" } },
        { "DMajor", new[] { "D", "E", "Fs", "A", "B" } },
        { "DsMajor", new[] { "Ds", "F", "G", "As", "C" } },
        { "EMajor", new[] { "E", "Fs", "Gs", "B", "Cs" } },
        { "FMajor", new[] { "F", "G", "A", "C", "D" } },
        { "FsMajor", new[] { "Fs", "Gs", "As", "Cs", "Ds" } },
        { "GMajor", new[] { "G", "A", "B", "D", "E" } },
        { "GsMajor", new[] { "Gs", "As", "C", "Ds", "F" } },
        { "AMajor", new[] { "A", "B", "Cs", "E", "Fs" } },
        { "AsMajor", new[] { "As", "C", "D", "F", "G" } },
        { "BMajor", new[] { "B", "Cs", "Ds", "Fs", "Gs" } },
        { "CMinor", new[] { "C", "Ds", "F", "G", "As" } },
        { "CsMinor", new[] { "Cs", "E", "Fs", "A", "B" } },
        { "DMinor", new[] { "D", "F", "G", "A", "C" } },
        { "DsMinor", new[] { "Ds", "Fs", "Gs", "As", "Cs" } },
        { "EMinor", new[] { "E", "G", "A", "B", "D" } },
        { "FMinor", new[] { "F", "Gs", "As", "C", "Ds" } },
        { "FsMinor", new[] { "Fs", "A", "B", "Cs", "E" } },
        { "GMinor", new[] { "G", "As", "C", "D", "F" } },
        { "GsMinor", new[] { "Gs", "B", "Cs", "Ds", "Fs" } },
        { "AMinor", new[] { "A", "C", "D", "E", "G" } },
        { "AsMinor", new[] { "As", "Cs", "Ds", "F", "Gs" } },
        { "BMinor", new[] { "B", "D", "E", "Fs", "A" } }
    };

    public static readonly string[] Scales = { 
        "CMajor",
        "CsMajor", 
        "DMajor",
        "DsMajor",
        "EMajor",
        "FMajor",
        "FsMajor",
        "GMajor",
        "GsMajor",
        "AMajor",
        "AsMajor",
        "BMajor",
        "CMinor",
        "CsMinor",
        "DMinor",
        "DsMinor",
        "EMinor",
        "FMinor",
        "FsMinor",
        "GMinor",
        "GsMinor",
        "AMinor",
        "AsMinor",
        "BMinor"
    };

    public static string GetScale(int value)
    {
        if (value < 1 || value > Scales.Length)
        {
            return string.Empty;
        }

        return Scales[value - 1];
    }
}

public static class Pitches
{
    public static readonly Dictionary<string, int> Values = new()
    {
        // Octave 2
        { "C2", 65 }, { "Cs2", 69 }, { "D2", 73 }, { "Ds2", 78 }, { "E2", 82 }, { "F2", 87 },
        { "Fs2", 93 }, { "G2", 98 }, { "Gs2", 104 }, { "A2", 110 }, { "As2", 117 }, { "B2", 123 },

        // Octave 3
        { "C3", 131 }, { "Cs3", 139 }, { "D3", 147 }, { "Ds3", 156 }, { "E3", 165 }, { "F3", 175 },
        { "Fs3", 185 }, { "G3", 196 }, { "Gs3", 208 }, { "A3", 220 }, { "As3", 233 }, { "B3", 247 },

        // Octave 4
        { "C4", 262 }, { "Cs4", 277 }, { "D4", 294 }, { "Ds4", 311 }, { "E4", 330 }, { "F4", 349 },
        { "Fs4", 370 }, { "G4", 392 }, { "Gs4", 415 }, { "A4", 440 }, { "As4", 466 }, { "B4", 494 },

        // Octave 5
        { "C5", 523 }, { "Cs5", 554 }, { "D5", 587 }, { "Ds5", 622 }, { "E5", 659 }, { "F5", 698 },
        { "Fs5", 740 }, { "G5", 784 }, { "Gs5", 831 }, { "A5", 880 }, { "As5", 932 }, { "B5", 988 }
    };

    private static readonly string[] Notes = { "C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B" };
    public static readonly string[] NotesDisplay = { "", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" };

    public static int GetPitch(int index, int octave)
    {
        var defaultValue = 0;
        if (index < 1 || index > 12 || octave < 1 || octave > 5)
        {
            return defaultValue;
        }
        string note = Notes[index - 1] + octave;
        return Values.TryGetValue(note, out int pitch) ? pitch : defaultValue;
    }

    public static string GetNote(int index)
    {
        var defaultValue = "C";
        if (index < 1 || index > 12)
        {
            return defaultValue;
        }

        return Notes[index - 1];
    }

    public static int GetNote(string note)
    {
        return Notes.ToList().IndexOf(note);
    }
}

public class Note
{
    public string Wave { get; set; }
    public float Freq { get; set; }
    public float Volume { get; set; }
    public Effect Effect { get; set; }
    public float? Duty { get; set; }
    public float? PhaserSpeed { get; set; }
    public float? PhaserDepth { get; set; }
}

public class NoteData : Note
{
    public float Duration { get; set; }
    public int NumSamples { get; set; }
    public float PrevFreq { get; set; }
    public float NextFreq { get; set; }
    public int Period { get; set; }
}

public enum Effect
{
    None,
    Slide,
    Vibrato,
    Drop,
    FadeIn,
    FadeOut,
    Arpeggio
}
