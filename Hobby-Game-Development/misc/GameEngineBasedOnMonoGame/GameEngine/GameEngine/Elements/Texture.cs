using Microsoft.Xna.Framework;
using System;

namespace GameEngine.Elements;

public class Texture
{
    public string TextureKey;

    public int Pixels;

    public int Rows;

    public int Columns;

    public int Width;

    public int Height;

    public Texture(string textureKey, int pixels, int rows, int columns, int width, int height)
    {
        TextureKey = textureKey;
        Pixels = pixels;
        Rows = rows;
        Columns = columns;
        Width = width;
        Height = height;
    }

    public Rectangle GetRectangle(int number)
    {
        (int x, int y) = ConvertNumberToXY(number);
        return new Rectangle(x * Pixels, y * Pixels, Width, Height);
    }

    private (int x, int y) ConvertNumberToXY(int number)
    {
        var max = Rows * Columns;
        if (number < 1 || number > max)
            throw new ArgumentOutOfRangeException(nameof(number), $"Number must be between 1 and {max}.");

        int x = (number - 1) % Columns;
        int y = (number - 1) / Columns;

        return (x, y);
    }
}