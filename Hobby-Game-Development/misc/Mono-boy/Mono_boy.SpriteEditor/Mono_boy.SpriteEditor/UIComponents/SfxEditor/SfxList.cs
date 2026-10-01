using Microsoft.Xna.Framework.Audio;
using System.Collections.Generic;
using System.IO;
using System;
using System.Linq;

namespace Mono_boy.SpriteEditor.UIComponents.SongEditor;

// var melody = "C4#10C420C4#10B415G430G45F45E45D410C420C5#10C520C5#10B515G530G55F55E55D510C520";
// Sfx.AddOrUpdateMelody("Square", melody, Waveform.Square); 
// Sfx.Play("Square");
public static class SfxList
{
    public static Dictionary<string, SfxSound> Melodies = new Dictionary<string, SfxSound>();

    public static Dictionary<string, Note> NoteMap = new Dictionary<string, Note>
    {
        {"", Note.Empty },
        {"C4", Note.C4},
        {"C4#", Note.CSharp4},
        {"D4", Note.D4},
        {"D4#", Note.DSharp4},
        {"E4", Note.E4},
        {"F4", Note.F4},
        {"F4#", Note.FSharp4},
        {"G4", Note.G4},
        {"G4#", Note.GSharp4},
        {"A4", Note.A4},
        {"A4#", Note.ASharp4},
        {"B4", Note.B4},
        {"C5", Note.C5},
        {"C5#", Note.CSharp5},
        {"D5", Note.D5},
        {"D5#", Note.DSharp5},
        {"E5", Note.E5},
        {"F5", Note.F5},
        {"F5#", Note.FSharp5},
        {"G5", Note.G5},
        {"G5#", Note.GSharp5},
        {"A5", Note.A5},
        {"A5#", Note.ASharp5},
        {"B5", Note.B5}
    };

    public static void AddOrUpdateMelody(string melodyKey, (Note, uint)[] melody, Waveform waveform)
    {
        melody = RemoveTrailingZeros(melody);
        melody = AddDurationForEmpty(melody);
        var newMelody = new SfxSound(melody, waveform);

        if (Melodies.ContainsKey(melodyKey))
        {
            Melodies[melodyKey] = newMelody;
        }
        else
        {
            Melodies.Add(melodyKey, newMelody);
        }
    }

    private static (Note, uint)[] RemoveTrailingZeros((Note, uint)[] melody)
    {
        int lastNonZeroIndex = melody.Length - 1;

        // Find the index of the last non-zero Item2 value
        while (lastNonZeroIndex >= 0 && melody[lastNonZeroIndex].Item2 == 0)
        {
            lastNonZeroIndex--;
        }

        // Return a new array excluding the trailing zeros
        return melody.Take(lastNonZeroIndex + 1).ToArray();
    }

    private static (Note, uint)[] AddDurationForEmpty((Note, uint)[] melody)
    {
        var newMelody = melody.Select(m =>
        {
            if (m.Item2 == 0)
            {
                m.Item1 = Note.Empty;
                m.Item2 = 20;
            }
            return m;
        });
        return newMelody.ToArray();
    }

    public static void Play(string melodyKey)
    {
        Melodies[melodyKey].Play();
    }

    public static (Note, uint)[] ConvertToMelody(string input)
    {
        var result = new List<(Note, uint)>();
        int i = 0;
        int length = input.Length;

        while (i < length)
        {
            string noteKey = input.Substring(i, 2);
            if (i + 1 < length && input[i + 2] == '#') // Check for sharp notes
            {
                noteKey = input.Substring(i, 3);
                i++;
            }
            i += 2;
            if (!NoteMap.TryGetValue(noteKey, out Note note))
            {
                result.ToArray();
            }

            if (i >= length || !char.IsDigit(input[i]))
            {
                result.ToArray();
            }

            int start = i;
            while (i < length && char.IsDigit(input[i]))
            {
                i++;
            }
            string durationStr = input.Substring(start, i - start);
            if (!uint.TryParse(durationStr, out uint duration))
            {
                result.ToArray();
            }

            result.Add((note, duration));
        }

        return result.ToArray();
    }
}

public class SfxSound
{
    private SoundEffect sound;

    private static readonly Dictionary<Note, double> NoteFrequencies = new Dictionary<Note, double>
    {
        { Note.Empty, 0.0 },      // C4
        { Note.C4, 261.63 },      // C4
        { Note.CSharp4, 277.18 }, // C#4
        { Note.D4, 293.66 },      // D4
        { Note.DSharp4, 311.13 }, // D#4
        { Note.E4, 329.63 },      // E4
        { Note.F4, 349.23 },      // F4
        { Note.FSharp4, 369.99 }, // F#4
        { Note.G4, 392.00 },      // G4
        { Note.GSharp4, 415.30 }, // G#4
        { Note.A4, 440.00 },      // A4
        { Note.ASharp4, 466.16 }, // A#4
        { Note.B4, 493.88 },      // B4
        { Note.C5, 523.25 },      // C5
        { Note.CSharp5, 554.37 }, // C#5
        { Note.D5, 587.33 },      // D5
        { Note.DSharp5, 622.25 }, // D#5
        { Note.E5, 659.25 },      // E5
        { Note.F5, 698.46 },      // F5
        { Note.FSharp5, 739.99 }, // F#5
        { Note.G5, 783.99 },      // G5
        { Note.GSharp5, 830.61 }, // G#5
        { Note.A5, 880.00 },      // A5
        { Note.ASharp5, 932.33 }, // A#5
        { Note.B5, 987.77 }       // B5
    };

    public SfxSound((Note, uint)[] melody, Waveform waveform)
    {
        // Create memory stream and write data
        var audioStream = new MemoryStream();
        var writer = new BinaryWriter(audioStream);

        // Constants for WAV file format
        const string headerGroupID = "RIFF";
        const string headerRiffType = "WAVE";
        const string fmtChunkID = "fmt ";
        const uint fmtChunkSize = 16;
        const ushort fmtFormatTag = 1; // PCM
        const ushort fmtChannels = 2;  // 1 - Mono 2 - stereo
        const uint fmtSamplesPerSec = 44100; // sample rate, e.g. CD=44100
        const ushort fmtBitsPerSample = 8;  // bits per sample
        const ushort fmtBlockAlign = fmtChannels * (fmtBitsPerSample / 8); // sample frame size, in bytes
        const uint fmtAvgBytesPerSec = fmtSamplesPerSec * fmtBlockAlign;
        const string dataChunkID = "data";
        const int minTime = 100;

        uint totalDuration = 0;
        foreach (var note in melody)
        {
            totalDuration += note.Item2;
        }

        var totalNumSamples = fmtSamplesPerSec * totalDuration / minTime;
        var completeDataByteArray = new byte[totalNumSamples * 2];
        var lengthCopied = 0;

        foreach (var (note, durationNote) in melody)
        {
            if (!NoteFrequencies.TryGetValue(note, out double freq))
            {
                throw new ArgumentException("Invalid note");
            }

            uint numSamples = fmtSamplesPerSec * fmtChannels * durationNote / minTime;
            byte[] dataByteArray = new byte[numSamples];

            // Generate sine wave data
            int amplitude = 127, offset = 128; // for 8-audio
            double period = 2.0 * Math.PI * freq / (fmtSamplesPerSec * fmtChannels);
            double amp;

            for (uint i = 0; i < numSamples - 1; i += fmtChannels)
            {
                amp = amplitude * (double)(numSamples - i) / numSamples;
                for (int channel = 0; channel < fmtChannels; channel++)
                {
                    if (note is Note.Empty)
                    {
                        dataByteArray[i + channel] = 128;
                        continue;
                    }
                    byte sampleValue = waveform switch
                    {
                        Waveform.Sine => Convert.ToByte(Math.Min(255, Math.Max(0, amp * Math.Sin(i * period) + offset))),
                        Waveform.Square => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (Math.Sin(i * period) >= 0 ? 1 : -1) + offset))),
                        Waveform.Triangle => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (1 - Math.Abs(i * period / Math.PI % 2 - 1)) + offset))),
                        Waveform.Sawtooth => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (i * period / Math.PI % 2 - 1) + offset))),
                        Waveform.Pulse => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (i * period / Math.PI % 1 < 0.2 ? 1 : -1) + offset))), // 20% duty cycle
                        Waveform.Noise => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (new Random().NextDouble() * 2 - 1) + offset))),
                        Waveform.TiltedSaw => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (i * period / Math.PI % 2 - 1) * 0.5 + offset))),
                        Waveform.Organ => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (0.5 * Math.Sin(i * period) + 0.5 * Math.Sin(2 * i * period)) + offset))),
                        Waveform.Phaser => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (Math.Sin(i * period) * Math.Sin(2 * Math.PI * i / 500) + offset)))),
                        _ => throw new ArgumentException("Invalid waveform")
                    };

                    dataByteArray[i + channel] = sampleValue;
                }
            }

            for (int i = lengthCopied; i <= lengthCopied + dataByteArray.Length - 1; i++)
            {
                completeDataByteArray[i] = dataByteArray[i - lengthCopied];
            }
            lengthCopied += dataByteArray.Length;
        }

        // Calculate chunk sizes
        uint dataChunkSize = (uint)completeDataByteArray.Length * (fmtBitsPerSample / 8);
        uint headerFileLength = 4 + (8 + fmtChunkSize) + 8 + dataChunkSize;

        writer.Write(headerGroupID.ToCharArray());
        writer.Write(headerFileLength);
        writer.Write(headerRiffType.ToCharArray());

        writer.Write(fmtChunkID.ToCharArray());
        writer.Write(fmtChunkSize);
        writer.Write(fmtFormatTag);
        writer.Write(fmtChannels);
        writer.Write(fmtSamplesPerSec);
        writer.Write(fmtAvgBytesPerSec);
        writer.Write(fmtBlockAlign);
        writer.Write(fmtBitsPerSample);

        writer.Write(dataChunkID.ToCharArray());
        writer.Write(dataChunkSize);
        writer.Write(completeDataByteArray);

        audioStream.Seek(0, SeekOrigin.Begin);
        sound = SoundEffect.FromStream(audioStream);
    }

    public void Play()
    {
        sound.Play();
    }
}