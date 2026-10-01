using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.IO;

namespace blackbox.Utils;

public static class TextureUtils
{
    public static IEnumerable<Texture2D> GetTexturesOneAtATime(
        Texture2D texture,
        int columns,
        int width,
        int height)
    {
        int rows = texture.Height / height;

        for (int y = 0; y < rows; y++)
        {
            for (int x = 0; x < columns; x++)
            {
                var subTexture = new Texture2D(texture.GraphicsDevice, width, height);

                Color[] data = new Color[width * height];
                texture.GetData(0, new Rectangle(x * width, y * height, width, height), data, 0, data.Length);
                subTexture.SetData(data);

                yield return subTexture;
            }
        }
    }

    public static Texture2D GetSubTexture(Texture2D texture, int x, int y, int w, int h)
    {
        Color[] data = new Color[w * h];
        texture.GetData(0, new Rectangle(x, y, w, h), data, 0, data.Length);
        Texture2D subTexture = new Texture2D(texture.GraphicsDevice, w, h);
        subTexture.SetData(data);
        return subTexture;
    }

    public static List<Texture2D> GetTextures(
        Texture2D texture,
        int columns,
        int width,
        int height)
    {
        var textures = new List<Texture2D>();

        int rows = texture.Height / height;

        for (int y = 0; y < rows; y++)
        {
            for (int x = 0; x < columns; x++)
            {
                var subTexture = new Texture2D(texture.GraphicsDevice, width, height);

                Color[] data = new Color[width * height];
                texture.GetData(0, new Rectangle(x * width, y * height, width, height), data, 0, data.Length);
                subTexture.SetData(data);
                textures.Add(subTexture);
            }
        }
        return textures;
    }

    public static Texture2D Convert64ToTexture(string imageBase64)
    {
        byte[] imageBytes = Convert.FromBase64String(imageBase64);
        using var ms = new MemoryStream(imageBytes);
        return Texture2D.FromStream(GraphUtils.GraphicsDevice, ms);
    }

    public static string TextureToBase64(Texture2D texture)
    {
        using (var ms = new MemoryStream())
        {
            texture.SaveAsPng(ms, texture.Width, texture.Height);
            byte[] imageBytes = ms.ToArray();
            return Convert.ToBase64String(imageBytes);
        }
    }

    public static Texture2D IntArrayToTexture2D(int[,] pixels)
    {
        int width = pixels.GetLength(1);
        int height = pixels.GetLength(0);

        Texture2D texture = new Texture2D(GraphUtils.GraphicsDevice, width, height);
        Color[] data = new Color[width * height];

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                int index = y * width + x;
                data[index] = ColorUtils.GetColor(pixels[y, x]);
            }
        }

        texture.SetData(data);
        return texture;
    }
}