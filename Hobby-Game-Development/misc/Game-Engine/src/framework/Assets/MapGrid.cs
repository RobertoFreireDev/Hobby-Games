using blackbox.Graphics;
using blackbox.Utils;
using Microsoft.Xna.Framework;

namespace blackbox.Assets;

public class MapGridData
{
    public int[,] Data;
    public int Columns;
    public int Rows;
    public int Size;
    public int Total;

    public void Create(int columns, int rows, int size)
    {
        Columns = columns;
        Rows = rows;
        Size = size;
        Total = Columns * Rows;
        Data = new int[Rows, Columns];
    }

    public void SetMap(string grid)
    {
        ArrayUtils.StringToIntArray(Data, grid);
    }

    public string GetMap()
    {
        return ArrayUtils.IntArrayToString(Data);
    }

    public void SetTile(int x, int y, int tileIndex)
    {
        if (InvalidGridPos(x, y))
        {
            return;
        }
        Data[y, x] = tileIndex;
    }

    public int GetTile(int x, int y)
    {
        if (InvalidGridPos(x, y))
        {
            return 0;
        }

        return Data[y, x];
    }

    public void UpdateTiles(int x0, int y0, int x1, int y1, int tileIndex)
    {
        var (rx0, ry0, rx1, ry1, w, h) = Shapes.AdjustRect(x0, y0, x1, y1);
        (rx0, ry0, rx1, ry1) = Shapes.ClampToBounds(rx0, ry0, w, h, Columns * Size, Rows * Size);

        for (int x = rx0; x < rx1; x++)
        {
            for (int y = ry0; y < ry1; y++)
            {
                Data[y, x] = tileIndex;
            }
        }
    }

    public void DrawMap(
        GridData gridData, int mapX, int mapY,   // starting tile in map
        int px, int py,       // screen position to draw at
        int width, int height, // how many tiles wide/tall to draw
        Color color)
    {
        for (int y = 0; y < height; y++)
        {
            int mapYIndex = mapY + y;
            if (mapYIndex < 0 || mapYIndex >= Rows) continue;

            for (int x = 0; x < width; x++)
            {
                int mapXIndex = mapX + x;
                if (mapXIndex < 0 || mapXIndex >= Columns) continue;

                int tileIndex = Data[mapYIndex, mapXIndex];
                if (tileIndex <= 0) continue;

                Rectangle source = gridData.TileRects[tileIndex];
                Rectangle dest = new Rectangle(
                    px + x * Size,
                    py + y * Size,
                    Size,
                    Size);

                GFW.SpriteBatch.Draw(gridData.Texture, dest, source, color);
            }
        }
    }

    public bool InvalidGridPos(int x, int y)
    {
        return x < 0 || y < 0 || x >= Columns || y >= Rows;
    }
}

public static class MapGrid
{
    public static MapGridData Data = new MapGridData();

    public static void Create(int columns, int rows, int size)
    {
        Data.Create(columns, rows, size);
    }

    public static void SetMap(string grid)
    {
        Data.SetMap(grid);
    }

    public static string GetMap()
    {
        return Data.GetMap();
    }

    public static void SetTile(int x, int y, int tileIndex)
    {
        Data.SetTile(x, y, tileIndex);
    }

    public static int GetSpriteFromMap(int x, int y)
    {
        return Data.GetTile(x, y);
    }

    public static void UpdateTileInMap(int x0, int y0, int x1, int y1, int tileIndex)
    {
        Data.UpdateTiles(x0, y0, x1, y1, tileIndex);
    }

    public static void DrawMap(
        int mapX, int mapY,   // starting tile in map
        int px, int py,       // screen position to draw at
        int width, int height, // how many tiles wide/tall to draw
        Color color)
    {
        Data.DrawMap(GameGrid.Data, mapX, mapY, px, py, width, height, color);
    }
}
