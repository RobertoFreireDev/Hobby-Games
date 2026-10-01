using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.UIComponents.SpriteEditor;
using System;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Manager;

internal class SpriteEditorManager : ISceneManager
{
    public static SpriteCells Sprites;
    public List<Card> Cards = new List<Card>();
    public static SpriteGrid Grid;
    public static int CellSize = 14;
    public static int GridSize = 32;

    public SceneEnum SceneType { get; set; }

    public NavButtonEnum NavButton { get; set; }


    public void LoadContent()
    {
        var width = GlobalManager.GraphicsDevice.Viewport.Width;
        CellSize = Math.Min((GlobalManager.GraphicsDevice.Viewport.Height - 150) / GridSize, (GlobalManager.GraphicsDevice.Viewport.Width - 300) / GridSize);
        SceneType = SceneEnum.SPRITE;
        NavButton = NavButtonEnum.Sprite;
        Cards.Add(new PaintButtonCard(new Rectangle(4, 100, 44, 274)));
        Cards.Add(new ColorPaletteCard(new Rectangle(50, 100, 82, 312)));
        Cards.Add(new EditCard(new Rectangle(4, 380, 44, 80)));
        Cards.Add(new SpriteCellButtonCard(new Rectangle(width - 300, 550, 256, 40)));
        Sprites = new SpriteCells(new Point(width - 300, 100));
        Grid = new SpriteGrid(Sprites.Sprites[1], new Point((width - CellSize * GridSize) / 2, 100), CellSize, GridSize);
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
        Grid.Update();
        Sprites.Update();
    }

    public void Draw()
    {
        foreach (var card in Cards)
        {
            card.Draw();
        }
        Grid.Draw();
        Sprites.Draw();
    }
}
