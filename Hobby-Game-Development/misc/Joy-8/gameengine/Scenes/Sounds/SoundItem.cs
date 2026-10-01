using gameengine.Data;
using gameengine.Scenes.Shared.UI.Buttons.Bar;
using gameengine.Scenes.Shared.UI.Buttons.Slide;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using System.Collections.Generic;

namespace gameengine.Scenes.Sounds;

internal class SoundItem
{
    private SliderBar speedSlider = new SliderBar(new Vector2(414, 10), 40, 1, 30, "Spd:", 46);
    private PitchBar pitches = new PitchBar(new int[SfxData.Length], 20, 100, 13, 2, 5, 0, 12, "Pitch", Pitches.NotesDisplay);
    private Bars octaves = new Bars(new int[SfxData.Length], 20, 140, 13, 2, 5, 3, 5, "Octv");
    private Bars effects = new Bars(new int[SfxData.Length], 20, 185, 13, 2, 5, 0, 6, "Efx");
    private Bars waves = new Bars(new int[SfxData.Length], 20, 235, 13, 2, 5, 1, 7, "Wave");
    private Bars volumes = new Bars(new int[SfxData.Length], 20, 275, 13, 2, 5, 0, 5, "Vol");

    public SoundItem()
    {
    }

    public void Update()
    {
        speedSlider.Update();
        pitches.Update();
        octaves.Update();
        effects.Update();
        waves.Update();
        volumes.Update();
    }

    public void Draw()
    {
        speedSlider.Draw();
        pitches.Draw();
        octaves.Draw();
        effects.Draw();
        waves.Draw();
        volumes.Draw();
    }

    internal (List<Note>, int) GetAudio()
    {
        var sound = new List<Note>();
        for (int i = 0; i < SfxData.Length; i++)
        {
            sound.Add(new Note
            {
                Wave = Waveforms.GetWaveform(waves.Values[i] - 1),
                Freq = Pitches.GetPitch(pitches.Values[i], octaves.Values[i]),
                Volume = volumes.Values[i] * 0.2f,
                Effect = (Effect)effects.Values[i]
            });
        }

        return (sound, speedSlider.Value);
    }
}
