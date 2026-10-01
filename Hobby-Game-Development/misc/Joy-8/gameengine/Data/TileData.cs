using Microsoft.Xna.Framework;
using System.Collections.Generic;

namespace gameengine.Data;

internal static class TileData
{
    #region Tile
    public static int GridSize;// Size in square
    public static int CellSize;// Size in pixels to draw
    public static Point PositionToDrawTile = new Point(88, 0); // Don't update this

    // In quadrants of 8x8 pixels. offsetPosition 1,2 -> position 8, 16.
    public static Point CurrentSpritePosition = new Point(0, 0);
    public static Point BackgroundCurrentSpritePosition = new Point(-1, -1);

    public static int MinGridSize = 8;
    public static int MaxGridSize = 32;
    #endregion

    #region CopyPaste
    public static int[,] CopyGrid = new int[MaxGridSize, MaxGridSize];
    public static bool Copied = false;

    public static void Copy()
    {
        for (int i = 0; i < MaxGridSize; i++)
        {
            for (int j = 0; j < MaxGridSize; j++)
            {
                var xValue = CurrentSpritePosition.X * MinGridSize + i;
                var yValue = CurrentSpritePosition.Y * MinGridSize + j;
                CopyGrid[i, j] = GameData.TilesGrid[xValue, yValue];
            }
        }
        Copied = true;
    }

    public static void Paste()
    {
        (var gridSize, var cellSize) = GetSizes(Zoom);
        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                var xValue = CurrentSpritePosition.X * MinGridSize + i;
                var yValue = CurrentSpritePosition.Y * MinGridSize + j;
                GameData.TilesGrid[xValue, yValue] = CopyGrid[i, j];
            }
        }
    }
    #endregion

    #region StackHistory
    public static Stack<int[,]> _undoHistory = new Stack<int[,]>();
    public static Stack<int[,]> _redoHistory = new Stack<int[,]>();
    private static int LimitHistory = 30;

    public static void UpdateStackHistory()
    {
        if (IsEqualSprite(_undoHistory))
        {
            return;
        }

        var lastGridColors = CreateNewGridColors();
        AddToUndoHistory(lastGridColors);
    }

    private static void AddToUndoHistory(int[,] gridColors)
    {
        if (_undoHistory.Count > LimitHistory)
        {
            _undoHistory = new Stack<int[,]>(_undoHistory);
            _undoHistory.Pop(); // Remove the oldest item
            _undoHistory = new Stack<int[,]>(_undoHistory);
        }

        _undoHistory.Push(gridColors);
    }

    private static void AddToRedoHistory(int[,] gridColors)
    {
        if (_redoHistory.Count > LimitHistory)
        {
            _redoHistory = new Stack<int[,]>(_redoHistory); 
            _redoHistory.Pop(); // Remove the oldest item
            _redoHistory = new Stack<int[,]>(_redoHistory);
        }

        _redoHistory.Push(gridColors);
    }

    public static void CleanStackHistory()
    {
        // user clicks on a new page, new sprite, exit tilescene, etc
        _undoHistory = new Stack<int[,]>();
        _redoHistory = new Stack<int[,]>();
    }

    public static bool IsEqualSprite(Stack<int[,]> sprite)
    {
        (var gridSize, var cellSize) = GetSizes(MaxZoom);

        if (sprite.Count == 0)
        {
            return false;
        }

        var lastSprite = sprite.Peek();

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                var xValue = CurrentSpritePosition.X * MinGridSize + i;
                var yValue = CurrentSpritePosition.Y * MinGridSize + j;
                if (IsValidTilesGrid(xValue, yValue) && lastSprite[i, j] != GameData.TilesGrid[xValue, yValue])
                {
                    return false;
                }
            }
        }

        return true;
    }

    private static bool IsValidTilesGrid(int x, int y)
    {
        return x < GameData.TilesGrid.GetLength(0)
                && y < GameData.TilesGrid.GetLength(1);
    }

    public static int[,] CreateNewGridColors()
    {
        (var gridSize, var cellSize) = GetSizes(MaxZoom);
        var GridColors = new int[gridSize, gridSize];

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                var xValue = CurrentSpritePosition.X * MinGridSize + i;
                var yValue = CurrentSpritePosition.Y * MinGridSize + j;
                if (IsValidTilesGrid(xValue, yValue))
                {
                    GridColors[i, j] = GameData.TilesGrid[xValue, yValue];
                }
            }
        }

        return GridColors;
    }

    public static void ReplaceGridColors(int[,] newGridColors)
    {
        (var gridSize, var cellSize) = GetSizes(Zoom);

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                var xValue = CurrentSpritePosition.X * MinGridSize + i;
                var yValue = CurrentSpritePosition.Y * MinGridSize + j;
                if (IsValidTilesGrid(xValue, yValue))
                {
                    GameData.TilesGrid[xValue, yValue] = newGridColors[i, j];
                }                
            }
        }
    }

    public static void Undo()
    {
        if (_undoHistory.Count > 0)
        {
            if (IsEqualSprite(_undoHistory))
            {
                _undoHistory.Pop();
            }
        }

        if (_undoHistory.Count > 0)
        {
            AddToRedoHistory(CreateNewGridColors());
            ReplaceGridColors(_undoHistory.Pop());
        }
    }

    public static void Redo()
    {
        if (_redoHistory.Count > 0)
        {
            if (IsEqualSprite(_redoHistory))
            {
                _redoHistory.Pop();
            }
        }

        if (_redoHistory.Count > 0)
        {
            AddToUndoHistory(CreateNewGridColors());
            ReplaceGridColors(_redoHistory.Pop());
        }
    }
    #endregion

    #region EditImage
    public static void FlipH()
    {
        (var gridSize, var cellSize) = GetSizes(Zoom);
        int[,] flippedGrid = new int[gridSize, gridSize];

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                flippedGrid[i, j] = GameData.TilesGrid[
                    CurrentSpritePosition.X * MinGridSize + gridSize - 1 - i,
                    CurrentSpritePosition.Y * MinGridSize + j];
            }
        }

        ReplaceGridColors(flippedGrid);
    }

    public static void FlipV()
    {
        (var gridSize, var cellSize) = GetSizes(Zoom);
        int[,] flippedGrid = new int[gridSize, gridSize];

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                flippedGrid[i, j] = GameData.TilesGrid[
                    CurrentSpritePosition.X * MinGridSize + i,
                    CurrentSpritePosition.Y * MinGridSize + gridSize - 1 - j];
            }
        }

        ReplaceGridColors(flippedGrid);
    }

    public static void RotateLeft()
    {
        (var gridSize, var cellSize) = GetSizes(Zoom);
        int[,] rotatedGrid = new int[gridSize, gridSize];

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                rotatedGrid[i, j] = GameData.TilesGrid[
                    CurrentSpritePosition.X * MinGridSize + gridSize - 1 - j,
                    CurrentSpritePosition.Y * MinGridSize + i];
            }
        }

        ReplaceGridColors(rotatedGrid);
    }

    public static void RotateRight()
    {
        (var gridSize, var cellSize) = GetSizes(Zoom);
        int[,] rotatedGrid = new int[gridSize, gridSize];

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                rotatedGrid[i, j] = GameData.TilesGrid[
                    CurrentSpritePosition.X * MinGridSize + j,
                    CurrentSpritePosition.Y * MinGridSize + gridSize - 1 - i];
            }
        }

        ReplaceGridColors(rotatedGrid);
    }
    #endregion

    #region Map
    public static Point PositionToDrawMap { get; private set; } = new Point(384, 32);
    public static int MinTileSize { get; private set; } = 8;
    public static int Columns { get; private set; } = 8;
    public static int Rows { get; private set; } = 16;
    public static int Scale { get; private set; } = 2;

    public static void UpdatePage(int page)
    {
        SetMaxZoom();
        CleanStackHistory();
        var newCurrentSpritePositionX = CurrentSpritePosition.X % Columns + page * Columns;
        CurrentSpritePosition = new Point(newCurrentSpritePositionX, CurrentSpritePosition.Y);
        BackgroundCurrentSpritePosition = new Point(-1, -1);
    }

    public static int GetPage()
    {
        return CurrentSpritePosition.X / Columns;
    }

    public static int GetTileNumber()
    {
        return CurrentSpritePosition.X % Columns + CurrentSpritePosition.Y * Columns + GetPage() * Rows * Columns;
    }

    public static int GetBackgroundTileNumber()
    {
        return BackgroundCurrentSpritePosition.X % Columns + BackgroundCurrentSpritePosition.Y * Columns + GetPage() * Rows * Columns;
    }

    public static void UpdateCurrentSpritePosition(int x, int y)
    {
        SetMaxZoom();
        CleanStackHistory();
        CurrentSpritePosition = new Point(x, y);
        if (BackgroundCurrentSpritePosition.X == x && BackgroundCurrentSpritePosition.Y == y)
        {
            BackgroundCurrentSpritePosition = new Point(-1, -1);
        }
    }

    public static void ToogleBackgroundUpdateCurrentSpritePosition(int x, int y)
    {
        if ((CurrentSpritePosition.X == x && CurrentSpritePosition.Y == y)
            || BackgroundCurrentSpritePosition.X == x && BackgroundCurrentSpritePosition.Y == y)
        {
            BackgroundCurrentSpritePosition = new Point(-1, -1);
        }
        else
        {
            BackgroundCurrentSpritePosition = new Point(x, y);
        }
    }

    public static Rectangle GetMapBounds()
    {
        return new Rectangle(
            PositionToDrawMap.X,
            PositionToDrawMap.Y,
            Columns * MinTileSize,
            Rows * MinTileSize);
    }

    public static Rectangle GetSelectorBorder(int scale)
    {
        return new Rectangle(
            0,
            0,
            MinTileSize * Scale * scale,
            MinTileSize * Scale * scale);
    }
    #endregion

    #region Zoom
    public static int Zoom;

    public static int MaxZoom = 4;

    public static void SetMaxZoom()
    {
        Zoom = 1;
        (GridSize, CellSize) = GetSizes(Zoom);
    }

    public static void SetSizes()
    {
        (GridSize, CellSize) = GetSizes(Zoom);
    }

    public static (int gridSize, int cellSize) GetSizes(int zoom)
    {
        switch (zoom)
        {
            case 1:
                return (8, 36);
            case 2:
                return (16, 18);
            case 3:
                return (24, 12);
            case 4:
                return (32, 9);
        }

        return (8, 36); // Default value. But it shouldn't happen
    }

    public static bool IsValidZoomOut(Point spritePosition, int zoom)
    {
        switch (zoom)
        {
            case 1:
                return true; // this case will never happen. 1 is the minimum Zoom
            case 2:
                return spritePosition.X % Columns <= 6 &&
                    spritePosition.Y % Rows <= 14;
            case 3:
                return spritePosition.X % Columns <= 5 &&
                    spritePosition.Y % Rows <= 13;
            case 4:
                return spritePosition.X % Columns <= 4 &&
                    spritePosition.Y % Rows <= 12;
            case 5:
                return spritePosition.X % Columns <= 2 &&
                    spritePosition.Y % Rows <= 10;
            case 6:
                return spritePosition.X % Columns == 0 &&
                    spritePosition.Y % Rows <= 8;
        }
        return false;
    }
    #endregion
}