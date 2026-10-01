using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace GameEngine.Elements.Managers;

public static class SpriteManager
{
    public static SpriteFont Font;

    public static SpriteBatch SpriteBatch;

    private static Texture2D _pixelTexture;

    public static void LoadSpriteBatch(string font)
    {
        Font = GlobalManager.Content.Load<SpriteFont>(font);
        SpriteBatch = new SpriteBatch(GlobalManager.GraphicsDevice);
        _pixelTexture = new Texture2D(GlobalManager.GraphicsDevice, 1, 1);
        _pixelTexture.SetData(new Color[] { Color.White });
    }

    public static void DrawLine(Vector2 start, Vector2 end, Color color, float thickness)
    {
        float distance = Vector2.Distance(start, end);
        float angle = (float)Math.Atan2(end.Y - start.Y, end.X - start.X);
        // Draw the line as a rectangle
        SpriteBatch.Draw(_pixelTexture, start, null, color, angle, Vector2.Zero, new Vector2(distance, thickness), SpriteEffects.None, 0);
    }

    public static void DrawPixel(Vector2 pointPosition, Color color)
    {
        SpriteBatch.Draw(_pixelTexture, pointPosition, color);
    }

    public static SpriteBatch GetSpriteBatchAndBeginWithLight()
    {
        var normalMapEffect = TextureManager.Effects["normalMap"];
        var spriteTexture = TextureManager.Texture2D["world"];
        var normalMapTexture = TextureManager.Texture2D["normalMap"];

        var lightDirection = new Vector3(-0.1f, 0.1f, 1.0f);
        lightDirection.Normalize();

        normalMapEffect.Parameters["TextureSampler"].SetValue(spriteTexture);
        normalMapEffect.Parameters["NormalMapSampler"].SetValue(normalMapTexture);
        normalMapEffect.Parameters["LightDirection"].SetValue(lightDirection);
        normalMapEffect.Parameters["LightColor"].SetValue(new Vector3(1.0f, 1.0f, 1.0f));

        var batch = SpriteManager.SpriteBatch;
        batch.Begin(blendState: BlendState.AlphaBlend, samplerState: SamplerState.PointClamp, effect: normalMapEffect);
        
        return batch;
    }
}