using Microsoft.Xna.Framework.Audio;
using System.Collections.Generic;
using System.IO;
using System;

namespace GameEngine.Elements.Managers;

public enum Note
{
    C, D, E, F, G, A, B
}

public enum Waveform
{
    Sine,
    Square,
    Triangle,
    Sawtooth,
    Pulse,
    Noise
}

public static class MusicManager
{
    public static Dictionary<string,Melody> Melodies = new Dictionary<string, Melody>();

    public static void AddMelody(string melodyKey, string melody, Waveform waveform)
    {
        Melodies.Add(melodyKey, new Melody(
            ConvertToMelody(melody), 
            waveform)
        );
    }

    public static void Play(string melodyKey)
    {
        Melodies[melodyKey].Play();
    }

    private static (Note, uint)[] ConvertToMelody(string input)
    {
        var noteMap = new Dictionary<char, Note>
        {
            {'C', Note.C},
            {'D', Note.D},
            {'E', Note.E},
            {'F', Note.F},
            {'G', Note.G},
            {'A', Note.A},
            {'B', Note.B}
        };

        var result = new List<(Note, uint)>();
        int i = 0;
        int length = input.Length;

        while (i < length)
        {
            char noteChar = input[i];
            if (!noteMap.TryGetValue(noteChar, out Note note))
            {
                throw new ArgumentException($"Invalid note character: {noteChar}");
            }

            i++;
            if (i >= length || !char.IsDigit(input[i]))
            {
                throw new ArgumentException("Duration must follow note character.");
            }

            int start = i;
            while (i < length && char.IsDigit(input[i]))
            {
                i++;
            }
            string durationStr = input.Substring(start, i - start);
            if (!uint.TryParse(durationStr, out uint duration))
            {
                throw new ArgumentException($"Invalid duration value: {durationStr}");
            }

            result.Add((note, duration));
        }

        return result.ToArray();
    }
}

public class Melody
{
    private SoundEffect sound;

    // Frequencies for musical notes
    private static readonly Dictionary<Note, double> NoteFrequencies = new Dictionary<Note, double>
    {
        { Note.C, 261.63 },
        { Note.D, 293.66 },
        { Note.E, 329.63 },
        { Note.F, 349.23 },
        { Note.G, 392.00 },
        { Note.A, 440.00 },
        { Note.B, 493.88 }
    };

    public Melody((Note, uint)[] melody, Waveform waveform)
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
        const ushort fmtBlockAlign = (ushort)(fmtChannels * (fmtBitsPerSample / 8)); // sample frame size, in bytes
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
            double period = (2.0 * Math.PI * freq) / (fmtSamplesPerSec * fmtChannels);
            double amp;

            for (uint i = 0; i < numSamples - 1; i+= fmtChannels)
            {
                amp = amplitude * (double)(numSamples - i) / numSamples;
                for (int channel = 0; channel < fmtChannels; channel++)
                {
                    byte sampleValue = waveform switch
                    {
                        Waveform.Sine => Convert.ToByte(Math.Min(255, Math.Max(0, amp * Math.Sin(i * period) + offset))),
                        Waveform.Square => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (Math.Sin(i * period) >= 0 ? 1 : -1) + offset))),
                        Waveform.Triangle => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (1 - Math.Abs(((i * period) / Math.PI) % 2 - 1)) + offset))),
                        Waveform.Sawtooth => Convert.ToByte(Math.Min(255, Math.Max(0, amp * ((i * period / Math.PI) % 2 - 1) + offset))),
                        Waveform.Pulse => Convert.ToByte(Math.Min(255, Math.Max(0, amp * ((i * period / Math.PI) % 1 < 0.2 ? 1 : -1) + offset))), // 20% duty cycle
                        Waveform.Noise => Convert.ToByte(Math.Min(255, Math.Max(0, amp * (new Random().NextDouble() * 2 - 1) + offset))),
                        _ => throw new ArgumentException("Invalid waveform")
                    };

                    dataByteArray[i + channel] = sampleValue;
                }
            }
            
            for (int i= lengthCopied; i <= lengthCopied + dataByteArray.Length - 1; i++)
            {
                completeDataByteArray[i] = dataByteArray[i - lengthCopied];
            }
            lengthCopied += dataByteArray.Length;
        }

        // Calculate chunk sizes
        uint dataChunkSize = (uint)completeDataByteArray.Length * (fmtBitsPerSample / 8);
        uint headerFileLength = 4 + (8 + fmtChunkSize) + (8 + dataChunkSize);

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