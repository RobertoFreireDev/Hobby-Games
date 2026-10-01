using gameengine.Data;
using gameengine.Scenes.Shared.UI;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;

namespace gameengine.Utils;

internal static class SpriteBatchExtensions
{
    public static void DrawImage(this SpriteBatch spriteBatch, string imageId, Rectangle bounds, int colorIndex, float transparency = 1f)
    {
        spriteBatch.CustomDraw(GameEngineData.Images[imageId], bounds, colorIndex, transparency);
    }

    public static void DrawButtonBorder(this SpriteBatch spriteBatch, UIComponentEnum type, int colorIndex)
    {
        spriteBatch.CustomDraw(GameEngineData.Images["border_button"], GameEngineData.UIComponentBounds[type], colorIndex);
    }

    private static Rectangle ScaleRectangle(Rectangle bounds)
    {
        var boxToDraw = GameEngineData.BoxToDraw;
        var scaleX = GameEngineData.ScaleX;
        var scaleY = GameEngineData.ScaleY;

        return new Rectangle(
            boxToDraw.X + (int)Math.Floor(bounds.X * scaleX),
            boxToDraw.Y + (int)Math.Floor(bounds.Y * scaleY),
            (int)Math.Ceiling(bounds.Width * scaleX),
            (int)Math.Ceiling(bounds.Height * scaleY));
    }

    public static void CustomDraw(this SpriteBatch spriteBatch, Texture2D texture, Rectangle bounds, int colorIndex, int paletteIndex)
    {
        spriteBatch.Draw(texture,ScaleRectangle(bounds),ColorUtils.GetColor(colorIndex, paletteIndex));
    }

    public static void CustomDraw(this SpriteBatch spriteBatch, Texture2D texture, Rectangle bounds, int colorIndex, float transparency = 1f)
    {
        spriteBatch.Draw(
            texture,
            ScaleRectangle(bounds),
            GetColor(colorIndex, transparency));
    }

    public static void CustomDraw(this SpriteBatch spriteBatch, Texture2D texture, Rectangle bounds, int colorIndex, float transparency, float scale = 1f, int rotate = 0, bool flipX = false, bool flipY = false)
    {
        var boxToDrawScale = Math.Min(GameEngineData.ScaleX, GameEngineData.ScaleY);
        var color = GetColor(colorIndex, transparency);
        Vector2 origin = new Vector2(texture.Width / 2f, texture.Height / 2f);
        float rotationInRadians = MathHelper.ToRadians(rotate);
        var flip = (flipX ? SpriteEffects.FlipHorizontally : SpriteEffects.None)
            | (flipY ? SpriteEffects.FlipVertically : SpriteEffects.None);

        spriteBatch.Draw(
            texture,
            ScaleVector(bounds) + origin,
            null,
            color,
            rotationInRadians,
            origin,
            scale * boxToDrawScale,
            flip,
            0);
    }

    private static Vector2 ScaleVector(Rectangle bounds)
    {
        var boxToDraw = GameEngineData.BoxToDraw;
        var boxToDrawScale = Math.Min(GameEngineData.ScaleX, GameEngineData.ScaleY);

        return new Vector2(
            boxToDraw.X + bounds.X * boxToDrawScale,
            boxToDraw.Y + bounds.Y * boxToDrawScale);
    }

    public static void BoxToDrawBlackBorders(this SpriteBatch spriteBatch, int borderWidth)
    {
        var bounds = GameEngineData.BoxToDraw;
        var texture = GameEngineData.PixelTexture;

        // Draw the top border
        spriteBatch.Draw(texture, new Rectangle(bounds.X, bounds.Y - borderWidth, bounds.Width, borderWidth), Color.Black);
        // Draw the bottom border
        spriteBatch.Draw(texture, new Rectangle(bounds.X, bounds.Y + bounds.Height, bounds.Width, borderWidth), Color.Black);
        // Draw the left border
        spriteBatch.Draw(texture, new Rectangle(bounds.X - borderWidth, bounds.Y, borderWidth, bounds.Height), Color.Black);
        // Draw the right border
        spriteBatch.Draw(texture, new Rectangle(bounds.X + bounds.Width, bounds.Y, borderWidth, bounds.Height), Color.Black);
    }

    public static void DrawText_MediumFont(this SpriteBatch spriteBatch, string text, Vector2 position, int colorIndex, float transparency = 1f, float scale = 1f, int offsetX = 0, float rotationAngle = 0f)
    {
        spriteBatch.DrawText(
            GameEngineData.MediumKeyBoardKeys,
            text,
            position,
            colorIndex,
            transparency,
            scale,
            offsetX,
            rotationAngle);
    }

    public static void DrawText_LargeFont(this SpriteBatch spriteBatch, string text, Vector2 position, int colorIndex, float transparency = 1f, float scale = 1f, int offsetX = 0, float rotationAngle = 0f)
    {
        spriteBatch.DrawText(
            GameEngineData.LargeKeyBoardKeys,
            text,
            position,
            colorIndex,
            transparency,
            scale,
            offsetX,
            rotationAngle);
    }

    private static void DrawText(this SpriteBatch spriteBatch, Dictionary<char, Texture2D> keyBoardKeys, string text, Vector2 position, int colorIndex, float transparency = 1f, float scale = 1f, int offsetX = 0, float rotationAngle = 0f)
    {
        var boxToDraw = GameEngineData.BoxToDraw;
        var boxToDrawScale = (GameEngineData.ScaleX + GameEngineData.ScaleY) / 2;

        foreach (char key in text)
        {
            var charTexture = keyBoardKeys.ContainsKey(key) ? keyBoardKeys[key] : keyBoardKeys[FontAtlasUtils.DefaultKey];

            Vector2 origin = new Vector2((int)(charTexture.Width / 2f), (int)(charTexture.Height / 2f));
            spriteBatch.Draw(
                charTexture,
                new Vector2(boxToDraw.X + (int)(position.X * boxToDrawScale), boxToDraw.Y + (int)(position.Y * boxToDrawScale)),
                null,
                GetColor(colorIndex, transparency),
                rotationAngle, // Rotation angle in radians
                origin,
                scale * boxToDrawScale,
                SpriteEffects.None,
                0f);

            // Adjust position based on rotation
            float sin = (float)Math.Sin(rotationAngle);
            float cos = (float)Math.Cos(rotationAngle);
            Vector2 rotatedOffset = new Vector2((charTexture.Width + offsetX) * scale * cos,
                                                (charTexture.Width + offsetX) * scale * sin);
            position += rotatedOffset;
        }
    }

    public static void DrawRectangle(this SpriteBatch spriteBatch, Rectangle bounds, int colorIndex, float transparency = 1f)
    {
        spriteBatch.Draw(GameEngineData.PixelTexture, ScaleRectangle(bounds), GetColor(colorIndex, transparency));
    }

    private static Color GetColor(int colorIndex, float transparency)
    {
        if (transparency < 0 || transparency > 1)
        {
            transparency = 1f;
        }
        return ColorUtils.GetColor(colorIndex) * (float)transparency;
    }
}
