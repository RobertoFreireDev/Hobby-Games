namespace blackbox.Sfx;

public class SfxChannel
{
    public SfxData CurrentSfx;
    public int Position;
    public double Phase; // continuous phase for waveform generation
    public double Time;
    public bool Playing;
    public int CurrentSample;    // position in samples from start of entire sfx
    public int TotalSamples;     // total samples in entire sfx (calculated once)
}