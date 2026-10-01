using gameengine.Scenes.Sounds;
using gameengine.Utils;
using Microsoft.Xna.Framework.Audio;
using System.Collections.Generic;

namespace gameengine.Data;

internal static class SfxData
{
    public static SoundItem[] Sounds = new SoundItem[128];
    public const int Length = 32;
    public static List<Track> Music = new List<Track>();
    public static bool Playing = false;
    public static int CurrentIndex = 0; 
    public static SoundEffectInstance Track;
}
