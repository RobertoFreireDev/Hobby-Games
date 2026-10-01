using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace mega8.core.graphics;

public class PixelledSpriteBatch
{
    private SpriteBatch _spriteBatch;

    public PixelledSpriteBatch(SpriteBatch spriteBatch)
    {
        _spriteBatch = spriteBatch;
    }

    public void Begin(SpriteSortMode sort, BlendState blendState, SamplerState sampleState, Effect effect)
    {
        _spriteBatch.Begin(sort, blendState, sampleState, null, null, effect);
    }

    public void Begin()
    {
        _spriteBatch.Begin(samplerState: SamplerState.PointClamp, transformMatrix: Camera2D.GetViewMatrix());
    }

    public void End()
    {
        _spriteBatch.End();
    }

    public void Draw(Texture2D texture, Rectangle destination, Rectangle source, Color color, SpriteEffects effects)
    {
        _spriteBatch.Draw(texture, destination, source, color, 0f, Vector2.Zero, effects, 0f);
    }

    public void Draw(Texture2D texture, Rectangle dest, Rectangle source, Color color)
    {
        _spriteBatch.Draw(texture, dest, source, color);
    }

    public void Draw(RenderTarget2D sceneTarget, Rectangle boxToDraw, Color white)
    {
        _spriteBatch.Draw(sceneTarget, boxToDraw, white);
    }

    public void Draw(Texture2D pixelTexture, Rectangle rectangle, Color color)
    {
        _spriteBatch.Draw(pixelTexture, rectangle, color);
    }

    public void Draw(Texture2D texture, Vector2 vector, Color color)
    {
        _spriteBatch.Draw(texture, vector, null, color, 0f, new Vector2(0, 0), 1.0f, SpriteEffects.None, 0f);
    }

    public void Draw(Texture2D texture, Vector2 vector, Color color, SpriteEffects effects)
    {
        _spriteBatch.Draw(texture, vector, null, color, 0f, new Vector2(0, 0), 1.0f, effects, 0f);
    }
}