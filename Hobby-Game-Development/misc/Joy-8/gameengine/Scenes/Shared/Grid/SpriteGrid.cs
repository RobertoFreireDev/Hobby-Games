using gameengine.Data;
using gameengine.Input;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;

namespace gameengine.Scenes.Shared.Grid;

internal class SpriteGrid
{
    private int _penSize = 1;
    private int[,] _chessGrid;
    private int _chessCellSize = 9;
    private int _chessGridSize = 32;

    public Sprite TemporaryGrid;
    public Point? LineStartPoint = null;

    public SpriteGrid()
    {
        (var gridSize, var cellSize) = TileData.GetSizes(TileData.MaxZoom);
        TemporaryGrid = new Sprite(cellSize, gridSize);
        TileData.SetMaxZoom();
    }

    public (Point, bool) ConvertMousePositionToGridCell()
    {
        var mousePosition = MouseInput.MousePosition();

        if (mousePosition.X - TileData.PositionToDrawTile.X < 0 || mousePosition.Y - TileData.PositionToDrawTile.Y < 0)
        {
            return (new Point(0, 0), false);
        }

        int x = (mousePosition.X - TileData.PositionToDrawTile.X) / TileData.CellSize;
        int y = (mousePosition.Y - TileData.PositionToDrawTile.Y) / TileData.CellSize;
        return (new Point(x, y), IsMouseInGrid(x,y));

        bool IsMouseInGrid(int x, int y)
        {
            return x >= 0 && x < TileData.GridSize && y >= 0 && y < TileData.GridSize;
        }
    }

    public void CreateChessGrid()
    {
        _chessGrid = new int[_chessGridSize, _chessGridSize];

        for (int row = 0; row < _chessGridSize; row++)
        {
            for (int col = 0; col < _chessGridSize; col++)
            {
                if ((row + col) % 2 == 0)
                    _chessGrid[row, col] = 1;
                else
                    _chessGrid[row, col] = 0;
            }
        }
    }

    public void DrawChessGrid()
    {
        var spriteBatch = FrameworkData.SpriteBatch;
        var ofx = TileData.PositionToDrawTile.X;
        var ofy = TileData.PositionToDrawTile.Y;
        for (int row = 0; row < _chessGridSize; row++)
        {
            for (int col = 0; col < _chessGridSize; col++)
            {
                var position = new Rectangle(
                    ofx + col * _chessCellSize,
                    ofy + row * _chessCellSize,
                    _chessCellSize,
                    _chessCellSize);

                if (_chessGrid[row, col] == 1)
                {
                    spriteBatch.DrawRectangle(position, _chessGrid[row, col], 0.4f);
                }
            }
        }

        spriteBatch.DrawRectangle(new Rectangle(0,0, TileData.PositionToDrawTile.X - 8, GameEngineData.BaseBox.Height), 1, 0.2f);
    }

    public void DrawSpriteGrid()
    {
        var spriteBatch = FrameworkData.SpriteBatch;
        var cellSize = TileData.CellSize;
        var gridSize = TileData.GridSize;
        var ofx = TileData.PositionToDrawTile.X;
        var ofy = TileData.PositionToDrawTile.Y;

        for (int x = 0; x < gridSize; x++)
        {
            for (int y = 0; y < gridSize; y++)
            {
                int drawX = ofx + x * cellSize;
                int drawY = ofy + y * cellSize;

                if (TileData.BackgroundCurrentSpritePosition.X >= 0)
                {
                    spriteBatch.DrawRectangle(new Rectangle(drawX, drawY, cellSize, cellSize), GetGameDataTilesGrid(TileData.BackgroundCurrentSpritePosition, x, y), 0.6f);
                }
                spriteBatch.DrawRectangle(new Rectangle(drawX, drawY, cellSize, cellSize), GetGameDataTilesGrid(TileData.CurrentSpritePosition, x, y));
                spriteBatch.DrawRectangle(new Rectangle(drawX, drawY, cellSize, cellSize), GetTemporaryGameDataTilesGrid(x, y));
            }
        }
    }

    public int GetGameDataTilesGrid(Point spritePosition, int x, int y)
    {
        if (!IsValidSpritePosition(spritePosition, x, y))
        {
            return 0;
        }

        return GameData.TilesGrid[spritePosition.X * TileData.MinGridSize + x, spritePosition.Y * TileData.MinGridSize + y];
    }

    public bool IsValidSpritePosition(Point spritePosition, int x, int y)
    {
        return spritePosition.X * TileData.MinGridSize + x < GameData.TilesGrid.GetLength(0)
                && spritePosition.Y * TileData.MinGridSize + y < GameData.TilesGrid.GetLength(1);
    }

    public int GetTemporaryGameDataTilesGrid(int x, int y)
    {
        return TemporaryGrid.GridColors[x, y];
    }

    public void UpdateGameDataTilesGrid(int x, int y, int value)
    {
        GameData.TilesGrid[
            TileData.CurrentSpritePosition.X * TileData.MinGridSize + x, 
            TileData.CurrentSpritePosition.Y * TileData.MinGridSize + y] = value;
    }

    public void UpdateGameDataTilesGridWithPen(int x, int y, int value, bool xSym = false, bool ySym = false)
    {
        var tileDim1 = GameData.TilesGrid.GetLength(0);
        var tileDim2 = GameData.TilesGrid.GetLength(1);
        var visibleArea = GetVisibleArea();

        for (int i = 0; i < _penSize; i++)
        {
            for (int j = 0; j < _penSize; j++)
            {
                var xValue = TileData.CurrentSpritePosition.X * TileData.MinGridSize + (x + i);
                var yValue = TileData.CurrentSpritePosition.Y * TileData.MinGridSize + (y + j);
                if (xValue < tileDim1 && yValue < tileDim2 && visibleArea.Contains(xValue, yValue))
                {
                    GameData.TilesGrid[xValue, yValue] = value;

                    if (xSym && ySym)
                    {
                        GameData.TilesGrid[visibleArea.Center.X * 2 - xValue - 1, visibleArea.Center.Y * 2 - yValue - 1] = value;
                    } 
                    else if (xSym)
                    {
                        GameData.TilesGrid[visibleArea.Center.X * 2 - xValue - 1, yValue] = value;
                    }
                    else if (ySym)
                    {
                        GameData.TilesGrid[xValue, visibleArea.Center.Y * 2 - yValue - 1] = value;
                    }
                }
            }
        }
    }

    public void MoveGrid(int deltaX, int deltaY)
    {
        (var gridSize, var cellSize) = TileData.GetSizes(TileData.Zoom);
        var copy = CopyVisibleArea();

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                var tileX = TileData.CurrentSpritePosition.X * TileData.MinGridSize;
                var tileY = TileData.CurrentSpritePosition.Y * TileData.MinGridSize;
                int newRow = tileX + (i + deltaX + gridSize) % gridSize;
                int newCol = tileY + (j + deltaY + gridSize) % gridSize;
                GameData.TilesGrid[newRow, newCol] = copy[i, j];
            }
        }
    }

    public int[,] CopyVisibleArea()
    {
        (var gridSize, var cellSize) = TileData.GetSizes(TileData.Zoom);
        int[,] copy = new int[gridSize, gridSize];

        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                var tileX = TileData.CurrentSpritePosition.X * TileData.MinGridSize;
                var tileY = TileData.CurrentSpritePosition.Y * TileData.MinGridSize;
                copy[i, j] = GameData.TilesGrid[tileX + i, tileY + j];
            }
        }

        return copy;
    }

    public void EraseAllArea()
    {
        (var gridSize, var cellSize) = TileData.GetSizes(TileData.Zoom);
        for (int i = 0; i < gridSize; i++)
        {
            for (int j = 0; j < gridSize; j++)
            {
                var xValue = TileData.CurrentSpritePosition.X * TileData.MinGridSize + i;
                var yValue = TileData.CurrentSpritePosition.Y * TileData.MinGridSize + j;
                GameData.TilesGrid[xValue, yValue] = 0;
            }
        }
    }

    public void UpdateTemporaryGameDataTilesGridWithPen(int x, int y, int value)
    {
        var tileDim1 = TemporaryGrid.GridColors.GetLength(0);
        var tileDim2 = TemporaryGrid.GridColors.GetLength(1);

        for (int i = 0; i < _penSize; i++)
        {
            for (int j = 0; j < _penSize; j++)
            {
                var xValue = (x + i);
                var yValue = (y + j);
                if (xValue < tileDim1 && yValue < tileDim2)
                {
                    TemporaryGrid.GridColors[xValue, yValue] = value;
                }
            }
        }
    }

    public Rectangle GetVisibleArea()
    {
        return new Rectangle(
                TileData.CurrentSpritePosition.X * TileData.MinGridSize,
                TileData.CurrentSpritePosition.Y * TileData.MinGridSize,
                TileData.GridSize,
                TileData.GridSize
            );
    }

    public void ZoomIn()
    {
        if (TileData.Zoom == 1)
        {
            return;
        }

        TileData.Zoom -= 1;
        TileData.CleanStackHistory();
        TileData.SetSizes();
    }

    public void ZoomOut()
    {
        if (TileData.Zoom == TileData.MaxZoom || !HaveGridForNextZoomOut())
        {
            return;
        }

        if (!TileData.IsValidZoomOut(TileData.CurrentSpritePosition, TileData.Zoom + 1))
        {
            return;
        }

        TileData.Zoom += 1;
        TileData.CleanStackHistory();
        TileData.SetSizes();

        bool HaveGridForNextZoomOut()
        {
            (var gridSize, var cellSize) = TileData.GetSizes(TileData.Zoom + 1);
            return IsValidSpritePosition(TileData.CurrentSpritePosition, gridSize -1, gridSize -1);
        }
    }

    public void PenSize(int penSize)
    {
        _penSize = penSize;
    }

    public void Fill(Point position, int selectedColor)
    {
        int targetColor = GetGameDataTilesGrid(TileData.CurrentSpritePosition, position.X, position.Y);
        if (targetColor == selectedColor) return;

        Queue<Point> pixels = new Queue<Point>();
        pixels.Enqueue(position);

        (var gridSize, var cellSize) = TileData.GetSizes(TileData.Zoom);

        while (pixels.Count > 0)
        {
            Point p = pixels.Dequeue();
            int x = p.X;
            int y = p.Y;

            if (x < 0 || x >= gridSize || y < 0 || y >= gridSize || GetGameDataTilesGrid(TileData.CurrentSpritePosition,x, y) != targetColor)
                continue;

            UpdateGameDataTilesGrid(x, y, selectedColor);

            pixels.Enqueue(new Point(x - 1, y));
            pixels.Enqueue(new Point(x + 1, y));
            pixels.Enqueue(new Point(x, y - 1));
            pixels.Enqueue(new Point(x, y + 1));
        }
    }

    public void ProcessLine(int x1, int y1, int color, bool temporary = false)
    {
        int x0 = LineStartPoint.Value.X;
        int y0 = LineStartPoint.Value.Y;
        int dx = Math.Abs(x1 - x0);
        int dy = Math.Abs(y1 - y0);
        int sx = x0 < x1 ? 1 : -1;
        int sy = y0 < y1 ? 1 : -1;
        int err = dx - dy;
        (var gridSize, var cellSize) = TileData.GetSizes(TileData.Zoom);
        while (true)
        {
            // Ensure the point is within bounds
            if (x0 >= 0 && x0 < gridSize && y0 >= 0 && y0 < gridSize)
            {
                if (temporary)
                {
                    UpdateTemporaryGameDataTilesGridWithPen(x0, y0, color);
                }
                else
                {
                    UpdateGameDataTilesGridWithPen(x0, y0, color);
                }
            }

            if (x0 == x1 && y0 == y1)
                break;

            int e2 = err * 2;
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