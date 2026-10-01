using gameengine.Data;
using gameengine.Scenes.Shared.UI;
using gameengine.Utils;
using Microsoft.Xna.Framework;

namespace gameengine.Scenes.ColorPalette;

internal class ColorPaletteOption : UIComponent
{
    public int Index;
    private bool _enableBorder = false;

    public ColorPaletteOption(int index, UIComponentEnum componentOption) 
        : base(null, componentOption, 1)
    {
        Index = index;
    }

    public override void AdditionalDraw()
    {
        var spriteBatch = FrameworkData.SpriteBatch;
        var bounds = GameEngineData.UIComponentBounds[_type];

        DrawPalette(Index, bounds);

        if (_enableBorder)
        {
            spriteBatch.DrawImage("colorpaletteborder", bounds, 2);
        }

        void DrawPalette(int paletteIndex, Rectangle bounds)
        {
            var size = 15;
            var ofx = 1;
            var ofy = 2;

            for (int i = 0; i < 16; i++)
            {
                var rect = new Rectangle(
                    (int)bounds.X + ofx + i * (size),
                    (int)bounds.Y + ofy,
                    size,
                    size
                );

                spriteBatch.CustomDraw(GameEngineData.PixelTexture, rect, i + 1, paletteIndex);
            }
        }
    }

    public override void Update()
    {
        if (IsMouseOver())
        {
            _enableBorder = true;
            IsClicked();
        }
        else
        {
            _enableBorder = false;
        }
    }
}
