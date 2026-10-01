using gameengine.Data;
using gameengine.Input;
using gameengine.Scenes.Shared.UI.Buttons.Slide;
using gameengine.Scenes.Sounds;
using gameengine.Utils;
using Microsoft.Xna.Framework;

namespace gameengine.Scenes;

internal class SfxScene : Scene
{
    private Sfx Sfx = new Sfx();
    private SliderBar sfxSlider = new SliderBar(new Vector2(10, 10), 200, 0, 127, "Sfx:", 55);
    private SliderBar pentSlider = new SliderBar(new Vector2(310, 10), 30, 0, 24, "", 65);
    public static string pent = string.Empty;
    private int lastSfx = 0;

    public SfxScene(SceneManager sceneManager) : base(sceneManager)
    {
        for (int i = 0; i < SfxData.Sounds.Length; i++)
        {
            SfxData.Sounds[i] = new SoundItem();
        }
    }

    public override void Update()
    {
        if (KeyboardInput.IsSpacedJustPressed())
        {
            Sfx.StopAll();
            var (sound, speed) = SfxData.Sounds[sfxSlider.Value].GetAudio();
            Sfx.Add(sfxSlider.Value, sound, speed);
            Sfx.Play(sfxSlider.Value);
        }

        Sfx.Update();
        sfxSlider.Update();
        pentSlider.Update();        
        pent = Pentatonic.GetScale(pentSlider.Value);
        if (lastSfx != sfxSlider.Value)
        {
            Sfx.StopAll();
        }
        SfxData.Sounds[sfxSlider.Value].Update();
        lastSfx = sfxSlider.Value;
    }

    public override void Draw()
    {
        sfxSlider.Draw();
        pentSlider.Draw();
        var spriteBatch = FrameworkData.SpriteBatch;
        spriteBatch.DrawText_MediumFont(pent, new Vector2(320, 10), 1, 0.4f, 2f, -1);
        SfxData.Sounds[sfxSlider.Value].Draw();
    }

    public override void Exit()
    {
        Sfx.StopMusic();
        Sfx.StopAll();
    }

    public override void Enter()
    {
    }
}