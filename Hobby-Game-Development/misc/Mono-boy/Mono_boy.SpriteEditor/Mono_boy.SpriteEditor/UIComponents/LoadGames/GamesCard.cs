using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;

namespace Mono_boy.SpriteEditor.UIComponents.LoadGames;

internal class GamesCard : IDisposable
{
    public List<GameOption> GameOptions = new List<GameOption>();

    public GamesCard(Rectangle bounds)
    {
        var gameList = Utils.Games.List;
        int count = 0;
        var heightOption = 30;              
        foreach (var game in gameList.ToList().OrderBy(g => g.Key))
        {
            var y = bounds.Y + (count + 1) * heightOption;
            GameOptions.Add(new GameOption(
                new TextField(new Vector2(bounds.X + 15, y + 2)
                , game.Key.ToString("D3")),
                new Rectangle(bounds.X + 10, y, 300, heightOption - 5),
                game.Key));
            count++;
        }

        foreach (var gameOption in GameOptions)
        {
            gameOption.Clicked += Button_Clicked;
        }
    }

    public void Update()
    {
        foreach (var game in GameOptions)
        {
            game.Update();
        }
    }

    public void Draw()
    {
        foreach (var game in GameOptions)
        {
            game.Draw();
        }
    }

    private void Button_Clicked(object sender, EventArgs e)
    {
        int? gameKey = ((GameOption)sender)?.GameIndex;

        if (gameKey is null)
        {
            return;
        }

        Games.UpdateCurrentGame((int)gameKey);
    }

    public void Dispose()
    {
        foreach (var gameOption in GameOptions)
        {
            gameOption.Clicked -= Button_Clicked;
        }
    }
}
