namespace blackbox.Utils;

public static class Constants
{
    public const int ResolutionX = 320;
    public const int ResolutionY = 180;

    public const string Mainfilename = "main";
    public const string MetadataFilename = "metadata";

    public const int MaxGameTextures = 64;
    public const int MaxGameSingleImageTextures = 1024;

    public const int CharsPerNote = 5;
    public const int SfxQty = 64;
    public const int MaxNotes = 24;
    public const int MinPitch = 36;
    public const int MaxPitch = 71;
    public const int MinWave = 0;
    public const int MaxWave = 8;
    public const int MinVolume = 0;
    public const int MaxVolume = 10;
    public const int MinSpeed = 1;
    public const int MaxSpeed = 32;
    public const int SpeedDigits = 2; // Look at MaxSpeed
    public const float SpeedSfx = 0.02f;
    public static int ChannelQty = 16;
}