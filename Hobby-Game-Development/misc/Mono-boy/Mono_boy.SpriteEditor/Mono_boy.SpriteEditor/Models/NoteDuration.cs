using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.SongEditor;
using System;

namespace Mono_boy.SpriteEditor.Models;

public class NoteDuration
{
    public Note Note;
    public double Frequency;
    public uint Duration;
    public double Period;
    private double[] _value;
    private int Iteration;
    private uint NumSamples;
    private uint NumMinSamples;

    public NoteDuration(Note note, uint duration)
    {
        Note = note;
        Duration = duration;
        Iteration = 0;
        const ushort fmtChannels = 2;  // 1 - Mono, 2 - Stereo
        const uint fmtSamplesPerSec = 44100; // Sample rate, e.g., CD=44100
        if (!Melody.NoteFrequencies.TryGetValue(Note, out double frequency))
        {
            throw new ArgumentException("Invalid note");
        }
        Frequency = frequency; 
        Period = 2.0 * Math.PI * Frequency / (fmtSamplesPerSec * fmtChannels);
        SetValue();
    }

    private void SetValue()
    {
        const ushort fmtChannels = 2;  // 1 - Mono, 2 - Stereo
        const uint fmtSamplesPerSec = 44100; // Sample rate, e.g., CD=44100
        int amplitude = 127; // For 8-bit audio
        NumMinSamples = fmtSamplesPerSec * fmtChannels * SongEditorManager.SongMinLength / (uint)SongEditorManager.TimeSong;
        NumSamples = fmtSamplesPerSec * fmtChannels * Duration / (uint)SongEditorManager.TimeSong;
        _value = new double[NumSamples];
        uint startFadeIndex = (uint)(NumSamples * 0.8);

        for (uint i = 0; i < NumSamples - 1; i += fmtChannels)
        {
            double amp = amplitude;
            if (i >= startFadeIndex)
            {
                amp *= (double)(NumSamples - i) / (NumSamples - startFadeIndex);
            }

            for (int channel = 0; channel < fmtChannels; channel++)
            {
                _value[i + channel] += amp*Math.Sin(i * Period);
            }
        }
    }

    public double GetValue(uint i)
    {
        return _value[i + Iteration * NumMinSamples];
    }

    public bool ShouldMove()
    {
        Iteration++;
        return Iteration * SongEditorManager.SongMinLength < Duration;
    }
}