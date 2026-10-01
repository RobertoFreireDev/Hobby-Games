using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;

namespace mega8.core.graphics;

public static class PixelledShapes
{
    public static Texture2D PixelTexture;

    public static void SetPixelTexture(GraphicsDevice gd)
    {
        PixelTexture = new Texture2D(gd, 1, 1);
        PixelTexture.SetData(new Color[] { Color.White });
    }

    public static void DrawPixel(int x, int y, Color color)
    {
        Mega8.SpriteBatch.Draw(PixelTexture, new Rectangle(x, y, 1, 1), color);
    }

    public static void DrawLine(int ox, int oy, int x1, int y1, Color color)
    {
        int x0 = 0;
        int y0 = 0;
        int dx = Math.Abs(x1 - x0);
        int dy = Math.Abs(y1 - y0);
        int sx = x0 < x1 ? 1 : -1;
        int sy = y0 < y1 ? 1 : -1;
        int err = dx - dy;
        int count = 0;

        while (true)
        {
            count++;
            Mega8.SpriteBatch.Draw(PixelTexture, new Rectangle(ox + x0, oy + y0, 1, 1), color);

            if (x0 == x1 && y0 == y1 || count > 2000)
                break;

            int e2 = 2 * err;
            if (e2 > -dy)
            {
                err -= dy;
                x0 += sx;
            }
            if (e2 < dx)
            {
                err += dx;
                y0 += sy;
            }
        }
    }
}