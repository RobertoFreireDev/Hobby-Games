using System;
using System.Collections.Generic;

namespace mega8.core.sfx;

public sealed class SfxEngine : IDisposable
{
    // ── Audio constants ──────────────────────────────────────────────────────
    private const int SampleRate = 44100;
    private const int TicksPerSec = 120;
    private const int SamplesPerTick = SampleRate / TicksPerSec;
    private const int NumChannels = 4;

    // Buffer submitted per DynamicSFX callback
    private const int BufferTicks = 16;
    private const int BufferSamples = SamplesPerTick * BufferTicks;

    // ── State ────────────────────────────────────────────────────────────────
    private readonly ChannelState[] _channels;
    private readonly Dictionary<int, SfxData> _sfxBank = new();
    private readonly object _lock = new();

    // ── Constructor ──────────────────────────────────────────────────────────
    public SfxEngine()
    {
        _channels = new ChannelState[NumChannels];
        for (int i = 0; i < NumChannels; i++)
            _channels[i] = new ChannelState(i, BufferSamples, OnBufferNeeded, _sfxBank);
    }

    // ── SFX bank ─────────────────────────────────────────────────────────────

    /// <summary>Register a parsed SFX so the engine can play it by index.</summary>
    private void LoadSfx(int index, SfxData data)
    {
        if (index < 0 || index > 63)
            throw new ArgumentOutOfRangeException(nameof(index), "SFX index must be 0–63.");
        lock (_lock) _sfxBank[index] = data;
    }

    /// <summary>Parse and register a raw hex SFX string at <paramref name="index"/>.</summary>
    private void LoadSfx(int index, string hexSfx)
        => LoadSfx(index, SfxData.FromHex(hexSfx));


    public void LoadSfxs(string[] sfxData)
    {
        for (int i = 0; i < sfxData.Length; i++)
            LoadSfx(i, sfxData[i]);
    }

    // ── Public API ───────────────────────────────────────────────────────────

    /// <summary>
    /// Play SFX <paramref name="sfxIndex"/> exactly like PICO-8's sfx() call.
    /// </summary>
    /// <param name="sfxIndex">
    ///   0–63  = play that SFX.<br/>
    ///   -1    = stop all channels.<br/>
    ///   -2    = stop <paramref name="channel"/> only (extension).
    /// </param>
    /// <param name="channel">
    ///   -1  = auto-assign (default).<br/>
    ///   0–3 = explicit channel.
    /// </param>
    /// <param name="offset">Note index to start from (0–31).</param>
    /// <param name="length">Number of notes to play, or -1 for full SFX.</param>
    public void Sfx(int sfxIndex, int channel = -1, int offset = 0, int length = -1)
    {
        lock (_lock)
        {
            // sfx(-1) → stop everything
            if (sfxIndex == -1)
            {
                foreach (var ch in _channels) ch.Stop();
                return;
            }

            // sfx(-2, channel) → stop a specific channel
            if (sfxIndex == -2)
            {
                int target = channel < 0 ? 0 : Math.Clamp(channel, 0, NumChannels - 1);
                _channels[target].Stop();
                return;
            }

            // sfx(n, -1) → stop any channel currently playing sfx n
            if (channel == -1 && sfxIndex >= 0)
            {
                bool stoppedAny = false;
                foreach (var ch in _channels)
                {
                    if (ch.CurrentSfxIndex == sfxIndex)
                    {
                        ch.Stop();
                        stoppedAny = true;
                    }
                }
                if (!stoppedAny)
                    channel = FindFreeChannel();
            }
            else if (channel < 0)
            {
                channel = FindFreeChannel();
            }
            else
            {
                channel = Math.Clamp(channel, 0, NumChannels - 1);
            }

            if (!_sfxBank.TryGetValue(sfxIndex, out var sfxData))
                return;

            int clampedOffset = Math.Clamp(offset, 0, sfxData.Notes.Count - 1);
            int clampedLength = length < 0
                ? sfxData.Notes.Count - clampedOffset
                : Math.Min(length, sfxData.Notes.Count - clampedOffset);

            if (channel >= 0 && channel < NumChannels)
            {
                _channels[channel].Play(sfxIndex, sfxData, clampedOffset, clampedLength);
            }            
        }
    }

    // ── Buffer callback ──────────────────────────────────────────────────────

    private void OnBufferNeeded(ChannelState ch)
    {
        lock (_lock)
        {
            ch.FillBuffer();
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private int FindFreeChannel()
    {
        for (int i = 0; i < NumChannels; i++)
            if (!_channels[i].IsPlaying) return i;

        int best = 0;
        float bestProgress = -1f;
        for (int i = 0; i < NumChannels; i++)
        {
            float p = _channels[i].Progress;
            if (p > bestProgress) { bestProgress = p; best = i; }
        }
        return best;
    }

    // ── IDisposable ──────────────────────────────────────────────────────────

    public void Dispose()
    {
        foreach (var ch in _channels) ch.Dispose();
    }
}