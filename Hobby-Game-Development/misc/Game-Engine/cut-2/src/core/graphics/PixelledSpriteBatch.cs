namespace cut2.core.graphics;

public class PixelledSpriteBatch
{
    private SpriteBatch _spriteBatch;

    public static Texture2D PixelTexture;

    public PixelledSpriteBatch(GraphicsDevice gd)
    {
        _spriteBatch = new SpriteBatch(gd);
        PixelTexture = new Texture2D(gd, 1, 1);
        PixelTexture.SetData(new Color[] { Color.White });
    }

    public void Begin(SpriteSortMode sort, BlendState blendState, SamplerState sampleState, Effect effect)
    {
        _spriteBatch.Begin(sort, blendState, sampleState, null, null, effect);
    }

    public void Begin(SamplerState sampleState)
    {
        _spriteBatch.Begin(samplerState: SamplerState.PointClamp);
    }

    public void Begin()
    {
        _spriteBatch.Begin(samplerState: SamplerState.PointClamp, transformMatrix: Camera2D.GetViewMatrix());
    }

    public void End()
    {
        _spriteBatch.End();
    }

    public void DrawPixel(int x, int y, int colorIndex)
    {
        _spriteBatch.Draw(PixelTexture, new Rectangle(x, y, 1, 1), ColorPalette.GetColor(colorIndex));
    }

    public void DrawRect(int x, int y, int width, int height, int colorIndex)
    {
        var color = ColorPalette.GetColor(colorIndex);
        var thickness = 1;
        // Top
        DrawRectFill(x, y, width, thickness, color);
        // Bottom
        DrawRectFill(x, y + height - thickness, width, thickness, color);
        // Left
        DrawRectFill(x, y + 1, thickness, height - 2, color);
        // Right
        DrawRectFill(x + width - thickness, y + 1, thickness, height - 2, color);
    }

    public void DrawRectFill(int x, int y, int width, int height, int colorIndex)
    {
        _spriteBatch.Draw(PixelTexture, new Rectangle(x, y, width, height), ColorPalette.GetColor(colorIndex));
    }

    public void DrawRectFill(int x, int y, int width, int height, Color color)
    {
        _spriteBatch.Draw(PixelTexture, new Rectangle(x, y, width, height), color);
    }

    public void Draw(Texture2D texture, Rectangle destination, Rectangle source, SpriteEffects effects)
    {
        _spriteBatch.Draw(texture, destination, source, Color.White, 0f, Vector2.Zero, effects, 0f);
    }

    public void Draw(RenderTarget2D sceneTarget, Rectangle boxToDraw, int colorIndex)
    {
        _spriteBatch.Draw(sceneTarget, boxToDraw, ColorPalette.GetColor(colorIndex));
    }

    public void Draw(Texture2D texture, Vector2 vector, int colorIndex)
    {
        _spriteBatch.Draw(texture, vector, null, ColorPalette.GetColor(colorIndex), 0f, new Vector2(0, 0), 1.0f, SpriteEffects.None, 0f);
    }
}