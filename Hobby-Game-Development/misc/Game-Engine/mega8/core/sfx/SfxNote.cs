namespace mega8.core.sfx;

public readonly struct Pico8SfxNote
{
    public int Pitch { get; }   // 0–63
    public int Instrument { get; }   // 0–15
    public int Volume { get; }   // 0–7
    public int Effect { get; }   // 0–7

    public Pico8SfxNote(int pitch, int instrument, int volume, int effect)
    {
        Pitch = pitch;
        Instrument = instrument;
        Volume = volume;
        Effect = effect;
    }
}
