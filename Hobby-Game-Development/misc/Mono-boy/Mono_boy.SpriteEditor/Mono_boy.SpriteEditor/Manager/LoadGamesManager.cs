using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.LoadGames;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Manager;

internal class LoadGamesManager : ISceneManager
{
    public List<GamesCard> Cards;

    public SceneEnum SceneType { get; set; }

    public NavButtonEnum NavButton { get; set; }


    public LoadGamesManager()
    {
        SceneType = SceneEnum.LOADGAME;
        NavButton = NavButtonEnum.Load;
    }

    public void LoadContent()
    {
        Cards = new List<GamesCard>();
        Cards.Add(new GamesCard(new Rectangle(4, 60, 300, 300)));
    }

    public void Reload()
    {
        LoadContent();
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