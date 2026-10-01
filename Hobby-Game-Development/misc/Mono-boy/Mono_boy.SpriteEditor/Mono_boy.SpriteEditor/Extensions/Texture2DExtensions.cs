using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Models;
using Mono_boy.SpriteEditor.Utils;

namespace Mono_boy.SpriteEditor.Extensions;

internal static class Texture2DExtensions
{
    public static Tile ConvertToTexture2D(this int[,] intArray)
    {
        var graphicsDevice = GlobalManager.GraphicsDevice;
        int width = intArray.GetLength(0);
        int height = intArray.GetLength(1);
        Color[] colorData = new Color[width * height];
        var isEmpty = true;
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                if (intArray[x, y] != 0)
                {
                    isEmpty = false;
                }
                colorData[x + y * width] = ColorUtils.GetColor(intArray[x, y]);
            }
        }

        Texture2D texture = new Texture2D(graphicsDevice, width, height);
        texture.SetData(colorData);
        return new Tile()
        {
            Texture = texture,
            HasTile = !isEmpty
        };
    }

    public static Texture2D CreateRectangleWithHole(int width, int height, Rectangle holeRect, int color)
    {
        int[,] intArray = new int[width, height];

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                if (holeRect.Contains(x, y))
                {
                    intArray[x, y] = 0;
                }
                else
                {
                    intArray[x, y] = color;
                }
            }
        }

        return ConvertToTexture2D(intArray).Texture;
    }
}
