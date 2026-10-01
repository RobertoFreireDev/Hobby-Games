using gameengine.Data;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace gameengine.Utils;

internal static class TextureUtils
{
    public static Texture2D CreateRectangleTexture(Rectangle source, int n)
    {
        var graphicsDevice = FrameworkData.GraphicsDevice;
        int width = source.Width;
        int height = source.Height;
        Color[] pixelData = new Color[width * height];

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                if (x < n || x >= width - n || y < n || y >= height - n)
                {
                    pixelData[y * width + x] = Color.White;
                }
                else
                {
                    pixelData[y * width + x] = new Color(0, 0, 0, 0);
                }
            }
        }

        Texture2D texture = new Texture2D(graphicsDevice, width, height);
        texture.SetData(pixelData);
        return texture;
    }
}
