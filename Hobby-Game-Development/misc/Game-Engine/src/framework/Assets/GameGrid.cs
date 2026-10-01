using blackbox.Graphics;
using blackbox.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;

namespace blackbox.Assets;

public class GridData
{
    public int[,] Data;
    public int[,] Copy;
    public Texture2D Texture;
    public Rectangle[] TileRects;
    public int[] Flags;
    public int Columns;
    public int Rows;
    public int Size;
    public int Total;
    public int Margin = 1; // to avoid last column stretching issue
    private bool _enableUndoRedo = false;
    private int maxUndo = 50;

    private Stack<int[,]> undoStack = new Stack<int[,]>();
    private Stack<int[,]> redoStack = new Stack<int[,]>();

    private void SaveSnapshot()
    {
        if (!_enableUndoRedo)
        {
            return;
        }

        int[,] copy = new int[Data.GetLength(0), Data.GetLength(1)];
        Array.Copy(Data, copy, Data.Length);

        undoStack.Push(copy);
        redoStack.Clear();

        if (undoStack.Count > maxUndo)
        {
            var temp = undoStack.ToArray();       // note: ToArray returns reversed order
            Array.Reverse(temp);                  // oldest is now first
            undoStack = new Stack<int[,]>(temp.Skip(1));
        }
    }

    public void Undo()
    {
        if (undoStack.Count == 0 || !_enableUndoRedo) return;

        int[,] current = new int[Data.GetLength(0), Data.GetLength(1)];
        Array.Copy(Data, current, Data.Length);

        redoStack.Push(current);
        Data = undoStack.Pop();
        UpdateTexture2d();
    }

    public void Redo()
    {
        if (redoStack.Count == 0 || !_enableUndoRedo) return;

        int[,] current = new int[Data.GetLength(0), Data.GetLength(1)];
        Array.Copy(Data, current, Data.Length);

        undoStack.Push(current);
        Data = redoStack.Pop();
        UpdateTexture2d();
    }

    public void CopyRegion(int x, int y, int w, int h)
    {
        var (x1, y1, x2, y2) = Shapes.ClampToBounds(x, y, w, h, Columns * Size, Rows * Size);
        int copyWidth = x2 - x1;
        int copyHeight = y2 - y1;

        Copy = new int[copyHeight, copyWidth];

        for (int yy = 0; yy < copyHeight; yy++)
        {
            for (int xx = 0; xx < copyWidth; xx++)
            {
                Copy[yy, xx] = Data[y1 + yy, x1 + xx];
            }
        }
    }

    public void PasteRegion(int x, int y, int w, int h)
    {
        if (Copy == null) return;

        SaveSnapshot();

        var (x1, y1, x2, y2) = Shapes.ClampToBounds(x, y, Math.Min(Copy.GetLength(1), w), Math.Min(Copy.GetLength(0), h), Columns * Size, Rows * Size);

        for (int yy = 0; yy < y2 - y1; yy++)
        {
            for (int xx = 0; xx < x2 - x1; xx++)
            {
                Data[y1 + yy, x1 + xx] = Copy[yy, xx];
            }
        }

        UpdateTexture2d();
    }

    public void MoveGrid(int x, int y, int w, int h, int deltaX, int deltaY)
    {
        SaveSnapshot();

        var (x1, y1, x2, y2) = Shapes.ClampToBounds(x, y, w, h, Columns * Size, Rows * Size);
        int regionW = x2 - x1;
        int regionH = y2 - y1;
        int[,] temp = new int[regionH, regionW];

        // shift values into temp
        for (int row = 0; row < regionH; row++)
        {
            for (int col = 0; col < regionW; col++)
            {
                int newRow = (row + deltaY + regionH) % regionH;
                int newCol = (col + deltaX + regionW) % regionW;

                temp[newRow, newCol] = Data[y1 + row, x1 + col];
            }
        }

        // copy back to Data
        for (int row = 0; row < regionH; row++)
        {
            for (int col = 0; col < regionW; col++)
            {
                Data[y1 + row, x1 + col] = temp[row, col];
            }
        }

        UpdateTexture2d();
    }

    public void Create(int columns, int rows, int size, bool enableUndoRedo)
    {
        Columns = columns;
        Rows = rows;
        Size = size;
        Total = Columns * Rows;
        _enableUndoRedo = enableUndoRedo;
        TileRects = new Rectangle[Total];
        Flags = new int[Total];
        for (int i = 0; i < Total; i++)
        {
            int x = (i % Columns) * Size;
            int y = (i / Columns) * Size;
            TileRects[i] = new Rectangle(x, y, Size, Size);
        }
        Data = new int[Rows * Size + Margin, Columns * Size + Margin];
        ClearGrid(0, 0, Columns * Size, Rows * Size);
    }

    private void ClearGrid(int x, int y, int w, int h)
    {
        var (x1, y1, x2, y2) = Shapes.ClampToBounds(x, y, w, h, Columns * Size, Rows * Size);
        for (int yy = y1; yy < y2; yy++)
        {
            for (int xx = x1; xx < x2; xx++)
            {
                Data[yy, xx] = -1;
            }
        }

        UpdateTexture2d();
    }

    public void SetPixel(int x, int y, int colorIndex)
    {
        if (InvalidGridPos(x, y))
        {
            return;
        }
        SaveSnapshot();
        Data[y, x] = colorIndex;
        UpdateTexture2d();
    }

    public void PaintBucket(int startX, int startY, int x0, int y0, int w, int h, int newColorIndex)
    {
        if (InvalidGridPos(startX, startY))
        {
            return;
        }

        SaveSnapshot();
        int targetColor = Data[startY, startX];
        if (targetColor == newColorIndex)
        {
            return;
        } 

        Queue<(int x, int y)> queue = new Queue<(int x, int y)>();
        queue.Enqueue((startX, startY));

        while (queue.Count > 0)
        {
            var (x, y) = queue.Dequeue();

            if (x < x0 || x >= x0 + w || y < y0 || y >= y0 + h || Data[y, x] != targetColor)
            {
                continue;
            }

            Data[y, x] = newColorIndex;
            queue.Enqueue((x + 1, y));
            queue.Enqueue((x - 1, y));
            queue.Enqueue((x, y + 1));
            queue.Enqueue((x, y - 1));
        }

        UpdateTexture2d();
    }

    public void SetLine(int x0, int y0, int x1, int y1, int colorIndex)
    {
        if (InvalidGridPos(x0, y0) || InvalidGridPos(x1, y1))
        {
            return;
        }

        SaveSnapshot();
        int dx = Math.Abs(x1 - x0);
        int dy = Math.Abs(y1 - y0);
        int sx = x0 < x1 ? 1 : -1;
        int sy = y0 < y1 ? 1 : -1;
        int err = dx - dy;
        int count = 0;
        while (true)
        {
            count++;
            Data[y0,x0] = colorIndex;

            if (x0 == x1 && y0 == y1 || count > 500)
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

        UpdateTexture2d();
    }

    public void SetRect(int x0, int y0, int x1, int y1, int colorIndex)
    {
        if (InvalidGridPos(x0, y0) || InvalidGridPos(x1, y1))
        {
            return;
        }

        SaveSnapshot();
        var (rx0, ry0, rx1, ry1, w, h) = Shapes.AdjustRect(x0, y0, x1, y1);

        for (int x = rx0; x <= rx1; x++)
        {
            Data[ry0, x] = colorIndex;
        }

        for (int x = rx0; x <= rx1; x++)
        {
            Data[ry1, x] = colorIndex;
        }

        for (int y = ry0; y <= ry1; y++)
        {
            Data[y, rx0] = colorIndex;
        }

        for (int y = ry0; y <= ry1; y++)
        {
            Data[y, rx1] = colorIndex;
        }

        UpdateTexture2d();
        return;
    }

    public void SetRectFill(int x0, int y0, int x1, int y1, int colorIndex)
    {
        if (InvalidGridPos(x0, y0) || InvalidGridPos(x1, y1))
        {
            return;
        }

        SaveSnapshot();
        var (rx0, ry0, rx1, ry1, w, h) = Shapes.AdjustRect(x0, y0, x1, y1);

        for (int x = rx0; x <= rx1; x++)
        {
            for (int y = ry0; y <= ry1; y++)
            {
                Data[y, x] = colorIndex;
            }
        }
        UpdateTexture2d();
        return;
    }

    public void SetCirc(int x0, int y0, int x1, int y1, int colorIndex)
    {
        if (InvalidGridPos(x0, y0) || InvalidGridPos(x1, y1))
        {
            return;
        }

        SaveSnapshot();
        int rx0 = Math.Min(x0, x1);
        int ry0 = Math.Min(y0, y1);
        int rx1 = Math.Max(x0, x1);
        int ry1 = Math.Max(y0, y1);
        var bounds = new Rectangle(rx0, ry0, rx1 - rx0, ry1 - ry0);
        rx0 = bounds.Left;
        ry0 = bounds.Top;
        rx1 = bounds.Right;
        ry1 = bounds.Bottom;

        if (rx1 - rx0 <= 1 && ry1 - ry0 <= 1)
        {
            for (int x = rx0; x <= rx1; x++)
            {
                for (int y = ry0; y <= ry1; y++)
                {
                    Data[y, x] = colorIndex;
                }
            }
            UpdateTexture2d();
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

            if (InvalidGridPos(p.X, p.Y))
            {
                continue;
            }

            Data[p.Y, p.X] = colorIndex;
        }
        
        UpdateTexture2d();
    }

    public void SetCircFill(int x0, int y0, int x1, int y1, int colorIndex)
    {
        if (InvalidGridPos(x0, y0) || InvalidGridPos(x1, y1))
        {
            return;
        }

        SaveSnapshot();
        int rx0 = Math.Min(x0, x1);
        int ry0 = Math.Min(y0, y1);
        int rx1 = Math.Max(x0, x1);
        int ry1 = Math.Max(y0, y1);
        var bounds = new Rectangle(rx0, ry0, rx1 - rx0, ry1 - ry0);
        rx0 = bounds.Left;
        ry0 = bounds.Top;
        rx1 = bounds.Right;
        ry1 = bounds.Bottom;

        if (rx1 - rx0 <= 1 || ry1 - ry0 <= 1)
        {
            for (int x = rx0; x <= rx1; x++)
            {
                for (int y = ry0; y <= ry1; y++)
                {
                    Data[y, x] = colorIndex;
                }
            }
            UpdateTexture2d();
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

            for (int x = minX; x <= maxX; x++)
            {
                if (InvalidGridPos(x, y))
                {
                    continue;
                }

                Data[y, x] = colorIndex;
            }
        }

        UpdateTexture2d();
    }

    public bool InvalidGridPos(int x, int y)
    {
        return x < 0 || y < 0 || x >= Columns * Size || y >= Rows * Size;
    }

    public void UpdateTexture2d()
    {
        Texture = TextureUtils.IntArrayToTexture2D(Data);
    }

    public string GetGameGrid()
    {
        return ArrayUtils.IntArrayToString(Data);
    }

    public string GetBase64(int x, int y, int w, int h)
    {
        if (InvalidGridPos(x, y) || InvalidGridPos(x + w -1, y + h - 1))
        {
            return string.Empty;
        }

        return TextureUtils.TextureToBase64(TextureUtils.GetSubTexture(Texture, x, y, w, h));
    }

    public void SetGameGrid(string gamegrid)
    {
        ArrayUtils.StringToIntArray(Data, gamegrid);
        UpdateTexture2d();
    }

    public void SetFlags(string flags)
    {
        var data = new int[1, Total];
        ArrayUtils.StringToIntArray(data, flags);
        Flags = new int[Total];
        for (int i = 0; i < Total; i++)
        {
            Flags[i] = data[0, i];
        }
    }

    public int GetPixel(int x, int y)
    {
        if (InvalidGridPos(x, y))
        {
            return -1;
        }

        return Data[y, x];
    }

    public void DrawCustomGrid(
        int n, int x, int y, int scale, Color color, int w = 1, int h = 1,
        bool flipX = false, bool flipY = false)
    {
        var source = new Rectangle(
            (n % Columns) * Size,
            (n / Columns) * Size,
            w * Size,
            h * Size);
        var destination = new Rectangle(x, y,
            w * Size * scale,
            h * Size * scale);
        SpriteEffects effects = SpriteEffects.None;
        if (flipX) effects |= SpriteEffects.FlipHorizontally;
        if (flipY) effects |= SpriteEffects.FlipVertically;

        GFW.SpriteBatch.Draw(
            Texture,
            destination,
            source,
            color,
            effects
        );
    }

    internal void SetFlag(int index, int flag)
    {
        if (index < 0 || index >= Total)
        {
            return;
        }

        Flags[index] = flag;
    }

    internal int GetFlag(int index)
    {
        if (index < 0 || index >= Total)
        {
            return 0;
        }

        return Flags[index];
    }
}

public static class GameGrid
{
    public static GridData Data = new GridData();

    public static void Create(int columns, int rows, int size, bool enableUndoRedo)
    {
        Data.Create(columns, rows, size, enableUndoRedo);
    }

    public static void Undo()
    {
        Data.Undo();
    }

    public static void Redo()
    {
        Data.Redo();
    }

    public static void Copy(int x, int y, int w, int h)
    {
        Data.CopyRegion(x, y, w, h);
    }

    public static void Paste(int x, int y, int w, int h)
    {
        Data.PasteRegion(x, y, w, h);
    }

    public static void MoveGrid(int x, int y, int w, int h, int deltaX, int deltaY)
    {
        Data.MoveGrid(x, y, w, h, deltaX, deltaY);
    }

    public static void SetPixel(int x, int y, int colorIndex)
    {
        Data.SetPixel(x, y, colorIndex);
    }

    public static void PaintBucket(int sx, int sy, int x, int y, int w, int h, int colorIndex)
    {
        Data.PaintBucket(sx, sy, x, y, w, h, colorIndex);
    }

    public static void SetLine(int x0, int y0, int x1, int y1, int colorIndex)
    {
        Data.SetLine(x0, y0, x1, y1, colorIndex);
    }

    public static void SetRect(int x0, int y0, int x1, int y1, int colorIndex, bool fill)
    {
        if (fill)
        {
            Data.SetRectFill(x0, y0, x1, y1, colorIndex);
        }
        else
        {
            Data.SetRect(x0, y0, x1, y1, colorIndex);
        }
    }

    public static void SetCirc(int x0, int y0, int x1, int y1, int colorIndex, bool fill)
    {
        if (fill)
        {
            Data.SetCircFill(x0, y0, x1, y1, colorIndex);
        }
        else
        {
            Data.SetCirc(x0, y0, x1, y1, colorIndex);
        }
    }

    public static string GetGameGrid()
    {
        return Data.GetGameGrid();
    }


    public static string GetGameGridAsBase64(int x, int y, int w, int h)
    {
        return Data.GetBase64(x, y, w, h);
    }

    public static void SetGameGrid(string gamegrid)
    {
        if (string.IsNullOrWhiteSpace(gamegrid))
        {
            return;
        }
        Data.SetGameGrid(gamegrid);
    }

    public static int GetPixel(int x, int y)
    {
        return Data.GetPixel(x, y);
    }

    public static void SetFlag(int index, int flag)
    {
        Data.SetFlag(index, flag);
    }

    public static int GetFlag(int index)
    {
        return Data.GetFlag(index);
    }

    public static string GetFlags()
    {
        int[,] data = new int[1, Data.Flags.Length]; // 1 row, N columns

        for (int i = 0; i < Data.Flags.Length; i++)
        {
            data[0, i] = Data.Flags[i];
        }
        return ArrayUtils.IntArrayToString(data);
    }

    public static void SetFlags(string data)
    {
        if (string.IsNullOrWhiteSpace(data))
        {
            return;
        }
        Data.SetFlags(data);
    }

    public static void DrawCustomGrid(
        int index, int x, int y, int scale, Color color, int w = 1, int h = 1,
        bool flipX = false, bool flipY = false)
    {
        Data.DrawCustomGrid(index, x, y, scale, color, w, h, flipX, flipY);
    }
}