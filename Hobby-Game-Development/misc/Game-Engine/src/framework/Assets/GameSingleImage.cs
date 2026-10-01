using blackbox.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace blackbox.Assets;

public static class GameSingleImage
{
    public static Texture2D[] GameImageData = new Texture2D[Constants.MaxGameSingleImageTextures];

    public static void LoadTexture(int index, string spriteBase64)
    {
        if (index < 0 || index >= Constants.MaxGameSingleImageTextures)
        {
            return;
        }

        GameImageData[index] = TextureUtils.Convert64ToTexture(spriteBase64);
    }

    public static void DrawCustomSprite(int index, int x, int y, Color color, bool flipX = false, bool flipY = false)
    {
        if (index < 0 || index >= Constants.MaxGameTextures || GameImageData[index] is null)
        {
            return;
        }

        SpriteEffects effects = SpriteEffects.None;
        if (flipX) effects |= SpriteEffects.FlipHorizontally;
        if (flipY) effects |= SpriteEffects.FlipVertically;

        GFW.SpriteBatch.Draw(
            GameImageData[index],
            new Vector2(x,y),
            color,
            effects
        );
    }
}