using Microsoft.Xna.Framework.Audio;
using System.Collections.Generic;
using System.IO;
using System;
using System.Linq;
using Mono_boy.SpriteEditor.Models;
using Mono_boy.SpriteEditor.Manager;

namespace Mono_boy.SpriteEditor.UIComponents.SongEditor;

public enum Note
{
    Empty,
    A0, ASharp0, B0,
    C1, CSharp1, D1, DSharp1, E1, F1, FSharp1, G1, GSharp1, A1, ASharp1, B1,
    C2, CSharp2, D2, DSharp2, E2, F2, FSharp2, G2, GSharp2, A2, ASharp2, B2,
    C3, CSharp3, D3, DSharp3, E3, F3, FSharp3, G3, GSharp3, A3, ASharp3, B3,
    C4, CSharp4, D4, DSharp4, E4, F4, FSharp4, G4, GSharp4, A4, ASharp4, B4,
    C5, CSharp5, D5, DSharp5, E5, F5, FSharp5, G5, GSharp5, A5, ASharp5, B5,
    C6, CSharp6, D6, DSharp6, E6, F6, FSharp6, G6, GSharp6, A6, ASharp6, B6,
    C7, CSharp7, D7, DSharp7, E7, F7, FSharp7, G7, GSharp7, A7, ASharp7, B7,
    C8
}

public enum Waveform
{
    Sine,
    Square,
    Triangle,
    Sawtooth,
    Pulse,
    Noise,
    TiltedSaw,
    Organ,
    Phaser
}

public static class Sfx
{
    public static Dictionary<string, Melody> Melodies = new Dictionary<string, Melody>();

    public static Dictionary<string, Note> NoteMap = new Dictionary<string, Note>
    {
        {"", Note.Empty},
        {"A0", Note.A0},
        {"A0#", Note.ASharp0},
        {"B0", Note.B0},
        {"C1", Note.C1}, {"C1#", Note.CSharp1},
        {"D1", Note.D1}, {"D1#", Note.DSharp1},
        {"E1", Note.E1},
        {"F1", Note.F1}, {"F1#", Note.FSharp1},
        {"G1", Note.G1}, {"G1#", Note.GSharp1},
        {"A1", Note.A1}, {"A1#", Note.ASharp1},
        {"B1", Note.B1},
        {"C2", Note.C2}, {"C2#", Note.CSharp2},
        {"D2", Note.D2}, {"D2#", Note.DSharp2},
        {"E2", Note.E2},
        {"F2", Note.F2}, {"F2#", Note.FSharp2},
        {"G2", Note.G2}, {"G2#", Note.GSharp2},
        {"A2", Note.A2}, {"A2#", Note.ASharp2},
        {"B2", Note.B2},
        {"C3", Note.C3}, {"C3#", Note.CSharp3},
        {"D3", Note.D3}, {"D3#", Note.DSharp3},
        {"E3", Note.E3},
        {"F3", Note.F3}, {"F3#", Note.FSharp3},
        {"G3", Note.G3}, {"G3#", Note.GSharp3},
        {"A3", Note.A3}, {"A3#", Note.ASharp3},
        {"B3", Note.B3},
        {"C4", Note.C4}, {"C4#", Note.CSharp4},
        {"D4", Note.D4}, {"D4#", Note.DSharp4},
        {"E4", Note.E4},
        {"F4", Note.F4}, {"F4#", Note.FSharp4},
        {"G4", Note.G4}, {"G4#", Note.GSharp4},
        {"A4", Note.A4}, {"A4#", Note.ASharp4},
        {"B4", Note.B4},
        {"C5", Note.C5}, {"C5#", Note.CSharp5},
        {"D5", Note.D5}, {"D5#", Note.DSharp5},
        {"E5", Note.E5},
        {"F5", Note.F5}, {"F5#", Note.FSharp5},
        {"G5", Note.G5}, {"G5#", Note.GSharp5},
        {"A5", Note.A5}, {"A5#", Note.ASharp5},
        {"B5", Note.B5},
        {"C6", Note.C6}, {"C6#", Note.CSharp6},
        {"D6", Note.D6}, {"D6#", Note.DSharp6},
        {"E6", Note.E6},
        {"F6", Note.F6}, {"F6#", Note.FSharp6},
        {"G6", Note.G6}, {"G6#", Note.GSharp6},
        {"A6", Note.A6}, {"A6#", Note.ASharp6},
        {"B6", Note.B6},
        {"C7", Note.C7}, {"C7#", Note.CSharp7},
        {"D7", Note.D7}, {"D7#", Note.DSharp7},
        {"E7", Note.E7},
        {"F7", Note.F7}, {"F7#", Note.FSharp7},
        {"G7", Note.G7}, {"G7#", Note.GSharp7},
        {"A7", Note.A7}, {"A7#", Note.ASharp7},
        {"B7", Note.B7},
        {"C8", Note.C8}
    };

    public static List<List<NoteDuration>> CreateMelody(int[,] song, uint songMinLength, int songLength, int notesNumber, int startNote)
    {
        var melody = new List<List<NoteDuration>>();
        for (int ti = 0; ti < songLength; ti++)
        {
            var notesAtSameTime = new List<NoteDuration>();

            for (int i = 0; i < notesNumber; i++)
            {
                var duration = (uint)song[ti, i];
                if (duration > 0)
                {
                    notesAtSameTime.Add(new NoteDuration((Note)(i + 1 + startNote), duration * songMinLength));
                }
            }

            melody.Add(notesAtSameTime);
        }

        return melody;
    }

    public static void AddOrUpdateMelody(string melodyKey, List<List<NoteDuration>> melody)
    {
        melody = RemoveTrailingZeros(melody);
        var newMelody = new Melody(melody);

        if (Melodies.ContainsKey(melodyKey))
        {
            Melodies[melodyKey] = newMelody;
        }
        else
        {
            Melodies.Add(melodyKey, newMelody);
        }
    }

    private static List<List<NoteDuration>> RemoveTrailingZeros(List<List<NoteDuration>> melody)
    {
        int lastNonZeroIndex = melody.Count - 1;

        while (lastNonZeroIndex >= 0 && melody[lastNonZeroIndex].All(note => note.Note == 0))
        {
            lastNonZeroIndex--;
        }

        return melody.Take(lastNonZeroIndex + 1).ToList();
    }

    public static bool IsPlaying(string melodyKey)
    {
        if (Melodies.ContainsKey(melodyKey))
        {
            return Melodies[melodyKey].IsPlaying();
        }

        return false;
    }

    public static bool IsStopped(string melodyKey)
    {
        if (Melodies.ContainsKey(melodyKey))
        {
            return Melodies[melodyKey].IsStopped();
        }

        return false;
    }

    public static void Play(string melodyKey)
    {
        if (Melodies.ContainsKey(melodyKey))
        {
            Melodies[melodyKey].Play();
        }
    }

    public static void Stop(string melodyKey)
    {
        if (Melodies.ContainsKey(melodyKey))
        {
            Melodies[melodyKey].Stop();
        }
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

public class Melody
{
    private SoundEffectInstance _sound;

    public static readonly Dictionary<Note, double> NoteFrequencies = new Dictionary<Note, double>
    {
        { Note.Empty, 0.0 },
        { Note.A0, 27.50 }, { Note.ASharp0, 29.14 }, { Note.B0, 30.87 },
        { Note.C1, 32.70 }, { Note.CSharp1, 34.65 },
        { Note.D1, 36.71 }, { Note.DSharp1, 38.89 },
        { Note.E1, 41.20 },
        { Note.F1, 43.65 }, { Note.FSharp1, 46.25 },
        { Note.G1, 49.00 }, { Note.GSharp1, 51.91 },
        { Note.A1, 55.00 }, { Note.ASharp1, 58.27 },
        { Note.B1, 61.74 },
        { Note.C2, 65.41 }, { Note.CSharp2, 69.30 },
        { Note.D2, 73.42 }, { Note.DSharp2, 77.78 },
        { Note.E2, 82.41 },
        { Note.F2, 87.31 }, { Note.FSharp2, 92.50 },
        { Note.G2, 98.00 }, { Note.GSharp2, 103.83 },
        { Note.A2, 110.00 }, { Note.ASharp2, 116.54 },
        { Note.B2, 123.47 },
        { Note.C3, 130.81 }, { Note.CSharp3, 138.59 },
        { Note.D3, 146.83 }, { Note.DSharp3, 155.56 },
        { Note.E3, 164.81 },
        { Note.F3, 174.61 }, { Note.FSharp3, 185.00 },
        { Note.G3, 196.00 }, { Note.GSharp3, 207.65 },
        { Note.A3, 220.00 }, { Note.ASharp3, 233.08 },
        { Note.B3, 246.94 },
        { Note.C4, 261.63 }, { Note.CSharp4, 277.18 },
        { Note.D4, 293.66 }, { Note.DSharp4, 311.13 },
        { Note.E4, 329.63 },
        { Note.F4, 349.23 }, { Note.FSharp4, 369.99 },
        { Note.G4, 392.00 }, { Note.GSharp4, 415.30 },
        { Note.A4, 440.00 }, { Note.ASharp4, 466.16 },
        { Note.B4, 493.88 },
        { Note.C5, 523.25 }, { Note.CSharp5, 554.37 },
        { Note.D5, 587.33 }, { Note.DSharp5, 622.25 },
        { Note.E5, 659.25 },
        { Note.F5, 698.46 }, { Note.FSharp5, 739.99 },
        { Note.G5, 783.99 }, { Note.GSharp5, 830.61 },
        { Note.A5, 880.00 }, { Note.ASharp5, 932.33 },
        { Note.B5, 987.77 },
        { Note.C6, 1046.50 }, { Note.CSharp6, 1108.73 },
        { Note.D6, 1174.66 }, { Note.DSharp6, 1244.51 },
        { Note.E6, 1318.51 },
        { Note.F6, 1396.91 }, { Note.FSharp6, 1479.98 },
        { Note.G6, 1567.98 }, { Note.GSharp6, 1661.22 },
        { Note.A6, 1760.00 }, { Note.ASharp6, 1864.66 },
        { Note.B6, 1975.53 },
        { Note.C7, 2093.00 }, { Note.CSharp7, 2217.46 },
        { Note.D7, 2349.32 }, { Note.DSharp7, 2489.02 },
        { Note.E7, 2637.02 },
        { Note.F7, 2793.83 }, { Note.FSharp7, 2959.96 },
        { Note.G7, 3135.96 }, { Note.GSharp7, 3322.44 },
        { Note.A7, 3520.00 }, { Note.ASharp7, 3729.31 },
        { Note.B7, 3951.07 },
        { Note.C8, 4186.01 }
    };


    public Melody(List<List<NoteDuration>> melody)
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
        const ushort fmtChannels = 2;  // 1 - Mono, 2 - Stereo
        const uint fmtSamplesPerSec = 44100; // Sample rate, e.g., CD=44100
        const ushort fmtBitsPerSample = 8;  // Bits per sample
        const ushort fmtBlockAlign = fmtChannels * (fmtBitsPerSample / 8); // Frame size in bytes
        const uint fmtAvgBytesPerSec = fmtSamplesPerSec * fmtBlockAlign;
        const string dataChunkID = "data";

        uint totalDuration = 0;
        var durationNote = SongEditorManager.SongMinLength;
        foreach (var noteList in melody)
        {
            totalDuration += durationNote;
        }

        var totalNumSamples = fmtSamplesPerSec * totalDuration / (uint)SongEditorManager.TimeSong;
        var completeDataByteArray = new List<byte>();
        var lengthCopied = 0;

        for (int t = 0; t < melody.Count; t++)
        {
            uint numSamples = fmtSamplesPerSec * fmtChannels * durationNote / (uint)SongEditorManager.TimeSong;
            byte[] dataByteArray = new byte[numSamples];

            int offset = 128; // For 8-bit audio
            for (uint i = 0; i < numSamples - 1; i += fmtChannels)
            {
                for (int channel = 0; channel < fmtChannels; channel++)
                {
                    byte sampleValue = 0;

                    if (melody[t].Count == 0)
                    {
                        sampleValue = 128;
                    }
                    else
                    {
                        var count = 0;
                        double tempSum = 0;

                        foreach (var note in melody[t])
                        {
                            tempSum += note.GetValue(i); count++;
                        }

                        tempSum /= count;
                        sampleValue = Convert.ToByte(Math.Min(255, Math.Max(0, tempSum + offset)));
                    }

                    dataByteArray[i + channel] = sampleValue;
                }
            }

            for (int i = lengthCopied; i <= lengthCopied + dataByteArray.Length - 1; i++)
            {
                completeDataByteArray.Add(dataByteArray[i - lengthCopied]);
            }
            lengthCopied += dataByteArray.Length;

            var hasAddedNewLine = false;
            for (int a = 0; a < melody[t].Count; a++)
            {
                if (melody[t][a].ShouldMove())
                {
                    if (!hasAddedNewLine)
                    {
                        hasAddedNewLine = true;
                        melody.Add(new List<NoteDuration>());
                    }
                    melody[t + 1].Add(melody[t][a]);
                }
            }
        }

        // Calculate chunk sizes
        uint dataChunkSize = (uint)completeDataByteArray.Count * (fmtBitsPerSample / 8);
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
        writer.Write(completeDataByteArray.ToArray());

        audioStream.Seek(0, SeekOrigin.Begin);
        var sound = SoundEffect.FromStream(audioStream);
        _sound = sound.CreateInstance();
    }

    public void Play()
    {
        _sound.Play();
    }

    public void Stop()
    {
        _sound.Stop();
    }

    public bool IsPlaying()
    {
        return _sound.State == SoundState.Playing;
    }

    public bool IsStopped()
    {
        return _sound.State == SoundState.Stopped;
    }
}