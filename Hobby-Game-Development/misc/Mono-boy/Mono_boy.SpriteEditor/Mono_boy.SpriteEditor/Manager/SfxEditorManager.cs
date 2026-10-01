using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Manager;

internal class SfxEditorManager : ISceneManager
{
    public List<Card> Cards = new List<Card>();

    public SceneEnum SceneType { get; set; }

    public NavButtonEnum NavButton { get; set; }

    public SfxEditorManager()
    {
        SceneType = SceneEnum.SFX;
        NavButton = NavButtonEnum.Sfx;
    }

    public void LoadContent()
    {
    }

    public void Reload()
    {

    }

    public void Update()
    {
        foreach (var card in Cards)
        {
            card.Update();
        }
    }

    public void Draw()
    {
        foreach (var card in Cards)
        {
            card.Draw();
        }
    }
}