using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.ConfigEditor;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Manager;

internal class ConfigEditorManager : ISceneManager
{
    public List<ConfigCard> Cards = new List<ConfigCard>();

    public SceneEnum SceneType { get; set; }

    public NavButtonEnum NavButton { get; set; }    

    public ConfigEditorManager()
    {
        SceneType = SceneEnum.CONFIG;
        NavButton = NavButtonEnum.Config;
    }

    public void LoadContent()
    {
        Cards.Add(new ConfigCard(new Rectangle(4, 60, 300,300)));
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