using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;
using System.Collections.Generic;
using System.Linq;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class SpriteCells
{
    public List<SpriteCell> Sprites = new List<SpriteCell>();
    public Pagination Pagination;

    public SpriteCells(Point position)
    {
        Pagination = new Pagination(7, 4, 0, 18);
        for (int page = 0; page < Pagination.Pages; page++)
        {
            for (int r = 0; r < Pagination.Row; r++)
            {
                for (int c = 0; c < Pagination.Column; c++)
                {
                    var newSprite = new SpriteCell(new Rectangle(position.X + c * (64), position.Y + r * (64), 64, 64));
                    Sprites.Add(newSprite);
                }
            }
        }

        var sprites = Games.GetCurrentGame().DataList;

        for (int i = 0; i < sprites.Count; i++)
        {
            Sprites[i].Sprite.GridColors = sprites[i];
        }
    }

    public void Update()
    {
        var spritesPerPage = Pagination.Row * Pagination.Column;
        foreach (var sprite in Sprites
            .Skip(Pagination.CurrentPage * spritesPerPage)
            .Take(spritesPerPage))
        {
            sprite.Update();
        }
    }

    public void Draw()
    {
        var index = 0;
        var spritesPerPage = Pagination.Row * Pagination.Column;
        foreach (var sprite in Sprites
            .Skip(Pagination.CurrentPage * spritesPerPage)
            .Take(spritesPerPage))
        {
            if (Pagination.CurrentPage == 0 && index == 0)
            {
                // don't draw eraser sprite;
                index++;
                continue;
            }
            sprite.Draw();
            index++;
        }
    }
}
