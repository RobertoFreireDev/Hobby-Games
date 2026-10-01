using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class SpriteCell : UIComponent
{
    public int CellSize;
    public int GridSize;
    public Sprite Sprite;

    public SpriteCell(Rectangle bounds) : base(GlobalManager.PixelTexture, bounds, 4)
    {
        CellSize = 2;
        GridSize = 32;
        Sprite = new Sprite(SpriteEditorManager.CellSize, SpriteEditorManager.GridSize);
    }

    public override void Update()
    {
        if (IsClicked())
        {
            SpriteEditorManager.Grid.SelectNewGrid(this);
        }
    }

    public override void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var pixelTexture = GlobalManager.PixelTexture;

        for (int x = 0; x < GridSize; x++)
        {
            for (int y = 0; y < GridSize; y++)
            {
                int drawX = GetBounds().X + x * CellSize;
                int drawY = GetBounds().Y + y * CellSize;
                spriteBatch.CustomDraw(pixelTexture, new Rectangle(drawX, drawY, CellSize, CellSize), ColorUtils.GetColor(Sprite.GridColors[x, y]));
            }
        }

        spriteBatch.DrawBorder(GetBounds(), 1, 1, Point.Zero);
    }
}
