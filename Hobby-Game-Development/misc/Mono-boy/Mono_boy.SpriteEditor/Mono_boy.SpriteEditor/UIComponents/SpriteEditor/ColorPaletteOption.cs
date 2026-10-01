using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class ColorPaletteOption : UIComponent
{
    public ColorPaletteOption(Rectangle bounds, int color) : base(GlobalManager.PixelTexture, bounds, color)
    {
    }

    public override void Update()
    {
        IsClicked();
    }

    public override void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.CustomDraw(Texture, Bounds, ColorUtils.GetColor(Color));

        if (Selected)
        {
            spriteBatch.DrawBorder(Bounds, 1, 1, new Point(-2, -2));
        }
    }
}
