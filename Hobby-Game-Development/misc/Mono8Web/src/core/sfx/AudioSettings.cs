namespace mono8.core.sfx;

/// <summary>
/// Global audio configuration. The output sample rate must match the audio backend's:
/// desktop (MonoGame.DesktopGL) is happy at 44100, but KNI's BlazorGL backend requires
/// the value to match the browser's AudioContext rate (commonly 48000). The web head sets
/// this from the browser before the engine is constructed. All synthesis is relative to it,
/// so the audio stays correctly tuned and timed at any rate.
/// </summary>
public static class AudioSettings
{
    public static int SampleRate = 44100;
}
