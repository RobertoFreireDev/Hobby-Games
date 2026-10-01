using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;

namespace blackbox.Graphics;

public static class Shapes
{
    public static void DrawPixel(int x, int y, Color color)
    {
        GFW.SpriteBatch.Draw(GFW.PixelTexture, new Rectangle(x, y, 1, 1), color);
    }

    public static void DrawLine(int ox, int oy, int x1, int y1, int scale, Color color)
    {
        int x0 = 0; 
        int y0 = 0;
        scale = Math.Max(scale, 1);
        int dx = Math.Abs(x1 - x0);
        int dy = Math.Abs(y1 - y0);
        int sx = x0 < x1 ? 1 : -1;
        int sy = y0 < y1 ? 1 : -1;
        int err = dx - dy;
        int count = 0;

        while (true)
        {
            count++;
            GFW.SpriteBatch.Draw(GFW.PixelTexture, new Rectangle(ox + x0*scale, oy + y0 * scale, scale, scale), color);

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

    public static void DrawCirc(int ox, int oy, int x0, int y0, int x1, int y1, Color color, int thickness = 1)
    {
        thickness = Math.Max(thickness, 1);
        var (rx0, ry0, rx1, ry1, w, h) = AdjustRect(x0, y0, x1, y1);

        if (rx1 - rx0 <= 1 && ry1 - ry0 <= 1)
        {
            GFW.SpriteBatch.Draw(GFW.PixelTexture, new Rectangle(ox + rx0 * thickness, oy + ry0 * thickness, w * thickness,h * thickness), color);
            return;
        }

        int xC = (int)Math.Ceiling((rx0 + rx1) / 2.0);
        int yC = (int)Math.Ceiling((ry0 + ry1) / 2.0);

        int evenX = (rx0 + rx1) % 2;
        int evenY = (ry0 + ry1) % 2;

        int rX = rx1 - xC;
        int rY = ry1 - yC;

        List<Point> pixels = new List<Point>();

        for (int x = rx0; x <= xC; x++)
        {
            double angle = Math.Acos((x - xC) / (double)rX);
            int y = (int)Math.Round(rY * Math.Sin(angle) + yC);

            pixels.Add(new Point(x - evenX, y));
            pixels.Add(new Point(x - evenX, 2 * yC - y - evenY));
            pixels.Add(new Point(2 * xC - x, y));
            pixels.Add(new Point(2 * xC - x, 2 * yC - y - evenY));
        }
        for (int y = ry0; y <= yC; y++)
        {
            double angle = Math.Asin((y - yC) / (double)rY);
            int x = (int)Math.Round(rX * Math.Cos(angle) + xC);

            pixels.Add(new Point(x, y - evenY));
            pixels.Add(new Point(2 * xC - x - evenX, y - evenY));
            pixels.Add(new Point(x, 2 * yC - y));
            pixels.Add(new Point(2 * xC - x - evenX, 2 * yC - y));
        }

        foreach (var p in pixels)
        {
            if (p.X < rx0 || p.X > rx1 || p.Y < ry0 || p.Y > ry1)
            {
                continue;
            }

            GFW.SpriteBatch.Draw(GFW.PixelTexture, new Rectangle(ox + p.X * thickness, oy + p.Y * thickness, thickness, thickness), color);
        }
    }

    public static void DrawCircFill(int ox, int oy, int x0, int y0, int x1, int y1, Color color, int thickness = 1)
    {
        thickness = Math.Max(thickness, 1);
        var (rx0, ry0, rx1, ry1, w, h) = AdjustRect(x0, y0, x1, y1);

        if (rx1 - rx0 <= 1 || ry1 - ry0 <= 1)
        {
            GFW.SpriteBatch.Draw(GFW.PixelTexture, new Rectangle(ox + rx0 * thickness, oy + ry0 * thickness, w * thickness, h * thickness), color);
            return;
        }

        int xC = (int)Math.Ceiling((rx0 + rx1) / 2.0);
        int yC = (int)Math.Ceiling((ry0 + ry1) / 2.0);

        int evenX = (rx0 + rx1) % 2;
        int evenY = (ry0 + ry1) % 2;

        int rX = rx1 - xC;
        int rY = ry1 - yC;

        // Dictionary keyed by y, value = list of x positions in that y line
        var linePixels = new Dictionary<int, List<int>>();

        // Helper to add points in linePixels dictionary
        void AddPixel(int x, int y)
        {
            if (!linePixels.TryGetValue(y, out var xs))
            {
                xs = new List<int>();
                linePixels[y] = xs;
            }
            xs.Add(x);
        }

        // Collect points on the circle border (top/bottom half and left/right half)
        for (int x = rx0; x <= xC; x++)
        {
            double angle = Math.Acos((x - xC) / (double)rX);
            int y = (int)Math.Round(rY * Math.Sin(angle) + yC);

            AddPixel(x - evenX, y);
            AddPixel(x - evenX, 2 * yC - y - evenY);
            AddPixel(2 * xC - x, y);
            AddPixel(2 * xC - x, 2 * yC - y - evenY);
        }
        for (int y = ry0; y <= yC; y++)
        {
            double angle = Math.Asin((y - yC) / (double)rY);
            int x = (int)Math.Round(rX * Math.Cos(angle) + xC);

            AddPixel(x, y - evenY);
            AddPixel(2 * xC - x - evenX, y - evenY);
            AddPixel(x, 2 * yC - y);
            AddPixel(2 * xC - x - evenX, 2 * yC - y);
        }

        // For each line, find min and max x, then draw a rectangle spanning from min x to max x at y with height 1
        foreach (var kvp in linePixels)
        {
            int y = kvp.Key;
            List<int> xs = kvp.Value;
            xs.Sort();

            int minX = xs[0];
            int maxX = xs[xs.Count - 1];
            int width = maxX - minX + 1;

            if (minX < rx0 || minX > rx1 || y < ry0 || y > ry1)
            {
                continue;
            }

            GFW.SpriteBatch.Draw(GFW.PixelTexture,
                new Rectangle(ox + minX * thickness, oy + y * thickness, width * thickness, thickness), 
                color);
        }
    }

    public static void DrawRectFill(int x, int y, int width, int height, Color color)
    {
        GFW.SpriteBatch.Draw(GFW.PixelTexture, new Rectangle(x, y, width, height), color);
    }

    public static void DrawRectBorder(int x, int y, int width, int height, Color color, int thickness = 1)
    {
        // Top
        DrawRectFill(x, y, width, thickness, color);
        // Bottom
        DrawRectFill(x, y + height - thickness, width, thickness, color);
        // Left
        DrawRectFill(x, y + 1, thickness, height - 2, color);
        // Right
        DrawRectFill(x + width - thickness, y + 1, thickness, height - 2, color);
    }

    public static (int rx0, int ry0, int rx1, int ry1, int w, int h) AdjustRect(int x0, int y0, int x1, int y1)
    {
        int rx0 = Math.Min(x0, x1);
        int ry0 = Math.Min(y0, y1);
        int rx1 = Math.Max(x0, x1);
        int ry1 = Math.Max(y0, y1);
        return (rx0, ry0, rx1, ry1, rx1 - rx0 + 1, ry1 - ry0 + 1);
    }

    public static (int x1, int y1, int x2, int y2) ClampToBounds(int x, int y, int w, int h, int c, int r)
    {
        return (
                Math.Max(0, x),
                Math.Max(0, y),
                Math.Min(c, x + w),
                Math.Min(r, y + h)
            );
    }
}