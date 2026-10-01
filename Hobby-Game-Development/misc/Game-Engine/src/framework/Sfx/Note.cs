namespace blackbox.Sfx;

public struct Note
{
    public int Pitch;      // MIDI-like number (C4=48 etc.)
    public Waveform Wave;  // Waveform type
    public float Volume;   // 0-1
    public int Effect;     // Not implemented yet
}