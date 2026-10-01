using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;

namespace Mono_boy.SpriteEditor.Extensions;

public static class SpriteBatchExtensions
{
    public static void CustomDraw(this SpriteBatch spriteBatch, Texture2D texture, Rectangle bounds, Color color)
    {
        spriteBatch.Draw(texture, bounds, color);
    }

    public static void CustomDraw(this SpriteBatch spriteBatch, Texture2D texture, Vector2 position, Color color)
    {
        spriteBatch.Draw(texture, position, color);
    }

    public static void CustomDraw(this SpriteBatch spriteBatch, Texture2D texture, Vector2 position, Color color, int rotate = 0, bool flipX = false, bool flipY = false)
    {
        if (rotate == 0f && !flipX && !flipY)
        {
            spriteBatch.Draw(texture, position, color);
            return;
        }

        Vector2 origin = new Vector2(texture.Width / 2f, texture.Height / 2f); 
        float rotationInRadians = MathHelper.ToRadians(rotate);
        var flip = (flipX ? SpriteEffects.FlipHorizontally : SpriteEffects.None)
            | (flipY ? SpriteEffects.FlipVertically : SpriteEffects.None);

        spriteBatch.Draw(
            texture,
            position + origin,
            null,
            color,
            rotationInRadians,
            origin,
            1f,
            flip,
            0);
    }

    public static void DrawCardBorder(this SpriteBatch spriteBatch, Rectangle bounds)
    {
        spriteBatch.DrawBorder(bounds, 1, 1, Point.Zero);
    }

    public static void DrawBorder(this SpriteBatch spriteBatch, Rectangle bounds, int colorIndex, int size, Point offset)
    {
        var color = ColorUtils.GetColor(colorIndex);
        // Draw top border
        spriteBatch.Draw(GlobalManager.PixelTexture, new Rectangle(bounds.X + offset.X, bounds.Y + offset.Y, bounds.Width - 2*offset.X, size), color);
        // Draw bottom border
        spriteBatch.Draw(GlobalManager.PixelTexture, new Rectangle(bounds.X + offset.X, bounds.Y - offset.Y + bounds.Height - size, bounds.Width - 2 * offset.X, size), color);
        // Draw left border
        spriteBatch.Draw(GlobalManager.PixelTexture, new Rectangle(bounds.X + offset.X, bounds.Y + offset.Y, size, bounds.Height - 2 * offset.Y), color);
        // Draw right border
        spriteBatch.Draw(GlobalManager.PixelTexture, new Rectangle(bounds.X + bounds.Width - 1 - offset.X, bounds.Y + offset.Y, size, bounds.Height - 2 * offset.Y), color);
    }

    public static void DrawText(this SpriteBatch spriteBatch, string text, Vector2 Position, int color)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return;
        }
        var font = GlobalManager.DefaultFont;
        spriteBatch.DrawString(font, text, Position, ColorUtils.GetColor(color));
    }
}