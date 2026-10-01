using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class SpriteGrid
{
    public static SpriteCell Grid;
    public static Sprite CopyGrid;
    public Sprite TemporaryGrid;
    public static Rectangle CopyRectangleSelection;
    public static Rectangle? RectangleSelection;
    public Point Position;
    private List<int[,]> LastGridColors;
    private Point? lineStartPoint = null;
    private const int MaxHistorySize = 30;
    private TextField CurrentSpriteNumber;
    private double moveDelay = 0.2;
    private double moveTimer = 0;

    public SpriteGrid(SpriteCell currentSprite, Point position, int cellSize, int gridSize)
    {
        Position = position;
        Grid = currentSprite;
        LastGridColors = new List<int[,]>();
        AddToHistory(Grid.Sprite.GridColors);
        CopyGrid = new Sprite(cellSize, gridSize);
        TemporaryGrid = new Sprite(cellSize, gridSize);
        CurrentSpriteNumber = new TextField(new Vector2(position.X, 80), SpriteEditorManager.Sprites.Sprites.FindIndex(s => s == currentSprite).ToString("D3"));
    }

    public void SelectNewGrid(SpriteCell newGrid)
    {
        var index = SpriteEditorManager.Sprites.Sprites.FindIndex(s => s == newGrid);
        if (index == 0)
        {
            // don't select eraser sprite;
            return;
        }
        Grid = newGrid;
        LastGridColors = new List<int[,]>();
        AddToHistory(Grid.Sprite.GridColors);
        CurrentSpriteNumber.UpdateText(index.ToString("D3"));
    }

    public void Update()
    {
        if (InputStateManager.IsControlZReleased())
        {
            if (LastGridColors.Count > 0)
            {
                GetFromHistory();
            }
        }

        MoveSprite();
        ProcessGrid();
    }

    private void MoveSprite()
    {
        moveTimer += GlobalManager.DeltaTime;

        if (moveTimer < moveDelay)
        {
            return;
        }

        var up = InputStateManager.IsUpPressed();
        var down = InputStateManager.IsDownPressed();
        var left = InputStateManager.IsLeftPressed();
        var right = InputStateManager.IsRightPressed();

        if (up)
        {
            Grid.Sprite.MoveGrid(0, -1);
        }
        else if (down)
        {
            Grid.Sprite.MoveGrid(0, 1);
        }
        else if (left)
        {
            Grid.Sprite.MoveGrid(-1, 0);
        }
        else if (right)
        {
            Grid.Sprite.MoveGrid(1, 0);
        }

        if (up || down || left || right)
        {
            AddToHistory(Grid.Sprite.GridColors);
        }

        moveTimer = 0;
    }

    public static int[,] CopyColorArray(int[,] original, Rectangle rect)
    {
        int rectX = rect.X;
        int rectY = rect.Y;
        int rectWidth = rect.Width;
        int rectHeight = rect.Height;
        int rows = original.GetLength(0);
        int cols = original.GetLength(1);
        int[,] copy = new int[rows, cols];

        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                if (j >= rectY && j <= rectY + rectHeight && i >= rectX && i <= rectX + rectWidth)
                {
                    copy[i, j] = original[i, j];  // Inside the rectangle, copy the value
                }
                else
                {
                    copy[i, j] = 0;  // Outside the rectangle, set to 0
                }
            }
        }

        return copy;
    }

    public static void ReplaceColorArray(int[,] original, int[,] grid, Rectangle rect)
    {
        int rectX = rect.X;
        int rectY = rect.Y;
        int rectWidth = rect.Width;
        int rectHeight = rect.Height;
        int rows = original.GetLength(0);
        int cols = original.GetLength(1);

        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                if (j >= rectY && j <= rectY + rectHeight
                    && i >= rectX && i <= rectX + rectWidth
                    && original[i, j] != 0)
                {
                    grid[i, j] = original[i, j];  // Inside the rectangle, copy the value
                }
            }
        }
    }

    public static void DeleteColorArray(int[,] grid, Rectangle rect)
    {
        int rectX = rect.X;
        int rectY = rect.Y;
        int rectWidth = rect.Width;
        int rectHeight = rect.Height;
        int rows = grid.GetLength(0);
        int cols = grid.GetLength(1);

        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                if (j >= rectY && j <= rectY + rectHeight
                    && i >= rectX && i <= rectX + rectWidth)
                {
                    grid[i, j] = 0;  // Inside the rectangle, delete
                }
            }
        }
    }

    private void AddToHistory(int[,] gridColors)
    {
        if (LastGridColors.Count > 0 && IsEqualColorArray(gridColors, LastGridColors.Last()))
        {
            return;
        }
        var copy = Sprite.CopyColorArray(gridColors);
        if (LastGridColors.Count >= MaxHistorySize)
        {
            LastGridColors.RemoveAt(0);
        }
        LastGridColors.Add(copy);
    }

    private void GetFromHistory()
    {
        if (LastGridColors.Count <= 1)
        {
            return;
        }
        var lastGridState = LastGridColors[LastGridColors.Count - 2];
        Grid.Sprite.GridColors = Sprite.CopyColorArray(lastGridState);
        LastGridColors.RemoveAt(LastGridColors.Count - 1);
    }

    public void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var pixelTexture = GlobalManager.PixelTexture;

        var ofx = Position.X;
        var ofy = Position.Y;
        var cellSize = Grid.Sprite.CellSize;
        var gridSize = Grid.Sprite.GridSize;

        spriteBatch.DrawBorder(new Rectangle(ofx, ofy, gridSize * cellSize, gridSize * cellSize), 1, 1, new Point(-2, -2));
        spriteBatch.DrawBorder(new Rectangle(ofx, ofy, gridSize * cellSize, gridSize * cellSize), 1, 1, Point.Zero);

        for (int x = 0; x < gridSize; x++)
        {
            for (int y = 0; y < gridSize; y++)
            {
                int drawX = ofx + x * cellSize;
                int drawY = ofy + y * cellSize;
                // Draw vertical lines
                spriteBatch.CustomDraw(pixelTexture, new Rectangle(drawX, ofy, 1, gridSize * cellSize), ColorUtils.GetColor(1));
                // Draw horizontal lines
                spriteBatch.CustomDraw(pixelTexture, new Rectangle(ofx, drawY, gridSize * cellSize, 1), ColorUtils.GetColor(1));
            }
        }

        for (int x = 0; x < gridSize; x++)
        {
            for (int y = 0; y < gridSize; y++)
            {
                int drawX = ofx + x * cellSize;
                int drawY = ofy + y * cellSize;
                var colorPixel = ColorUtils.GetColor(Grid.Sprite.GridColors[x, y]);
                if (RectangleSelection is not null
                    && x >= RectangleSelection?.Left
                    && x <= RectangleSelection?.Right
                    && y >= RectangleSelection?.Top
                    && y <= RectangleSelection?.Bottom)
                {
                    colorPixel = colorPixel * 0.5f;
                }
                spriteBatch.CustomDraw(pixelTexture, new Rectangle(drawX, drawY, cellSize, cellSize), colorPixel);
                spriteBatch.CustomDraw(pixelTexture, new Rectangle(drawX, drawY, cellSize, cellSize), ColorUtils.GetColor(TemporaryGrid.GridColors[x, y]));
            }
        }

        if (RectangleSelection is not null)
        {
            var rect = (Rectangle)RectangleSelection;
            spriteBatch.DrawBorder(new Rectangle(ofx + rect.X * cellSize, ofy + rect.Y * cellSize, (rect.Width + 1) * cellSize, (rect.Height + 1) * cellSize), 1, 2, Point.Zero);
        }

        CurrentSpriteNumber.Draw();
    }

    private void ProcessGrid()
    {
        var paintMode = PaintButtonCard.PaintMode;
        var selectedColor = ColorPaletteCard.SelectedColor;

        if (paintMode is null)
        {
            return;
        }

        var gridPoint = ConvertMousePositionToGridCell();
        int x = gridPoint.X;
        int y = gridPoint.Y;
        var isOnGrid = x >= 0 && x < Grid.Sprite.GridSize && y >= 0 && y < Grid.Sprite.GridSize;

        if (InputStateManager.IsDelJustPressed())
        {
            DeleteColorArray(Grid.Sprite.GridColors, CopyRectangleSelection);
            AddToHistory(Grid.Sprite.GridColors);
        }

        if (PaintButtonCard.PaintMode != PaintModeEnum.SelectionRectangle)
        {
            CopyRectangleSelection = new Rectangle(0, 0, 32, 32);
            RectangleSelection = null;
        }

        var isMousePressedOnGrid = InputStateManager.IsMouseLeftButtonPressed() && isOnGrid;
        var isMouseJustPressedOnGrid = InputStateManager.IsMouseLeftButtonJustPressed() && isOnGrid;
        var isMouseReleasedOnGrid = InputStateManager.IsMouseLeftButtonReleased() && isOnGrid;

        switch (paintMode)
        {
            case PaintModeEnum.Bucket:
                if (isMousePressedOnGrid)
                {
                    Fill();
                }
                break;
            case PaintModeEnum.Pencil:
                if (isMousePressedOnGrid)
                {
                    Grid.Sprite.GridColors[x, y] = selectedColor;
                }
                break;
            case PaintModeEnum.Eraser:
                if (isMousePressedOnGrid)
                {
                    Grid.Sprite.GridColors[x, y] = 0;
                }
                break;
            case PaintModeEnum.Line:
                TemporaryGrid.ResetGridColors();
                if (isMouseJustPressedOnGrid)
                {
                    // Start Line Drawing
                    lineStartPoint = new Point(x, y);
                }
                else if (InputStateManager.IsMouseLeftButtonReleased())
                {
                    // Paint Line
                    if (lineStartPoint.HasValue)
                    {
                        ProcessLine(Grid.Sprite.GridColors, lineStartPoint.Value.X, lineStartPoint.Value.Y, x, y, selectedColor);
                        lineStartPoint = null;
                    }
                }
                else if (InputStateManager.IsMouseRightButtonPressed())
                {
                    // End Line Drawing
                    lineStartPoint = null;
                }

                if (lineStartPoint.HasValue)
                {
                    ProcessLine(TemporaryGrid.GridColors, lineStartPoint.Value.X, lineStartPoint.Value.Y, x, y, selectedColor);
                }
                break;
            case PaintModeEnum.Rectangle:
                TemporaryGrid.ResetGridColors();
                if (isMouseJustPressedOnGrid)
                {
                    // Start Rectangle Drawing
                    lineStartPoint = new Point(x, y);
                }
                else if (InputStateManager.IsMouseLeftButtonReleased())
                {
                    // Draw Rectangle
                    if (lineStartPoint.HasValue)
                    {
                        DrawRectangle(Grid.Sprite.GridColors, lineStartPoint.Value.X, lineStartPoint.Value.Y, x, y, selectedColor);
                        lineStartPoint = null;
                    }
                }
                else if (InputStateManager.IsMouseRightButtonPressed())
                {
                    // End Rectangle Drawing
                    lineStartPoint = null;
                }

                if (lineStartPoint.HasValue)
                {
                    DrawRectangle(TemporaryGrid.GridColors, lineStartPoint.Value.X, lineStartPoint.Value.Y, x, y, selectedColor);
                }
                break;
            case PaintModeEnum.Circle:
                TemporaryGrid.ResetGridColors();
                if (isMouseJustPressedOnGrid)
                {
                    // Start Circle Drawing
                    lineStartPoint = new Point(x, y);
                }
                else if (InputStateManager.IsMouseLeftButtonReleased())
                {
                    // Draw Circle
                    if (lineStartPoint.HasValue)
                    {
                        DrawCircle(Grid.Sprite.GridColors, lineStartPoint.Value.X, lineStartPoint.Value.Y, x, y, selectedColor);
                        lineStartPoint = null;
                    }
                }
                else if (InputStateManager.IsMouseRightButtonPressed())
                {
                    // End Circle Drawing
                    lineStartPoint = null;
                }

                if (lineStartPoint.HasValue)
                {
                    DrawCircle(TemporaryGrid.GridColors, lineStartPoint.Value.X, lineStartPoint.Value.Y, x, y, selectedColor);
                }
                break;
            case PaintModeEnum.SelectionRectangle:
                TemporaryGrid.ResetGridColors();
                if (isMouseJustPressedOnGrid)
                {
                    CopyRectangleSelection = new Rectangle(0, 0, 32, 32);
                    RectangleSelection = null;
                    lineStartPoint = new Point(x, y);
                }
                else if (InputStateManager.IsMouseLeftButtonReleased())
                {
                    // Draw Rectangle
                    if (lineStartPoint.HasValue)
                    {
                        int minX = Math.Min(lineStartPoint.Value.X, x);
                        int maxX = Math.Max(lineStartPoint.Value.X, x);
                        int minY = Math.Min(lineStartPoint.Value.Y, y);
                        int maxY = Math.Max(lineStartPoint.Value.Y, y);

                        if (maxX - minX > 1 && maxY - minY > 1)
                        {
                            CopyRectangleSelection = new Rectangle(minX, minY, maxX - minX, maxY - minY);
                            RectangleSelection = new Rectangle(minX, minY, maxX - minX, maxY - minY);
                        }
                        lineStartPoint = null;
                    }
                }
                else if (InputStateManager.IsMouseRightButtonPressed())
                {
                    // End Rectangle Drawing
                    lineStartPoint = null;
                    RectangleSelection = null;
                    CopyRectangleSelection = new Rectangle(0, 0, 32, 32);
                }

                if (lineStartPoint.HasValue)
                {
                    DrawRectangle(TemporaryGrid.GridColors, lineStartPoint.Value.X, lineStartPoint.Value.Y, x, y, selectedColor);
                }
                break;
        }

        if (isMouseReleasedOnGrid)
        {
            AddToHistory(Grid.Sprite.GridColors);
        }
    }

    public static bool IsEqualColorArray(int[,] original, int[,] toCompare)
    {
        int rows = original.GetLength(0);
        int cols = original.GetLength(1);

        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                if (toCompare[i, j] != original[i, j])
                {
                    return false;
                }
            }
        }

        return true;
    }

    private void DrawCircle(int[,] grid, int x0, int y0, int x1, int y1, int color)
    {
        var coords = GetOrderedRectangleCoordinates(x0, y0, x1, y1);

        var pixels = new List<Tuple<int, int>>();
        var xC = (coords.x0 + coords.x1) / 2.0;
        var yC = (coords.y0 + coords.y1) / 2.0;
        var rX = coords.x1 - xC;
        var rY = coords.y1 - yC;

        for (int x = coords.x0; x <= xC; x++)
        {
            var angle = rX == 0 ? 0 : Math.Acos((x - xC) / rX);
            var y = Math.Round(rY * Math.Sin(angle) + yC);
            pixels.Add(Tuple.Create(x, (int)y));
            pixels.Add(Tuple.Create(x, (int)(2 * yC - y)));
            pixels.Add(Tuple.Create((int)(2 * xC - x), (int)y));
            pixels.Add(Tuple.Create((int)(2 * xC - x), (int)(2 * yC - y)));
        }
        for (int y = coords.y0; y <= yC; y++)
        {
            double angle = rY == 0 ? 0 : Math.Asin((y - yC) / rY);
            var x = Math.Round(rX * Math.Cos(angle) + xC);
            pixels.Add(Tuple.Create((int)x, y));
            pixels.Add(Tuple.Create((int)(2 * xC - x), y));
            pixels.Add(Tuple.Create((int)x, (int)(2 * yC - y)));
            pixels.Add(Tuple.Create((int)(2 * xC - x), (int)(2 * yC - y)));
        }

        foreach (var item in pixels)
        {
            if (item.Item1 >= 0 && item.Item1 < Grid.Sprite.GridSize && item.Item2 >= 0 && item.Item2 < Grid.Sprite.GridSize)
            {
                grid[item.Item1, item.Item2] = color;
            }
        }
    }

    private void DrawRectangle(int[,] grid, int x0, int y0, int x1, int y1, int color)
    {
        // Ensure the points are in the correct order
        int left = Math.Min(x0, x1);
        int right = Math.Max(x0, x1);
        int top = Math.Min(y0, y1);
        int bottom = Math.Max(y0, y1);

        // Draw top and bottom borders
        for (int x = left; x <= right; x++)
        {
            if (x >= 0 && x < Grid.Sprite.GridSize)
            {
                if (top >= 0 && top < Grid.Sprite.GridSize)
                    grid[x, top] = color;
                if (bottom >= 0 && bottom < Grid.Sprite.GridSize)
                    grid[x, bottom] = color;
            }
        }

        // Draw left and right borders
        for (int y = top; y <= bottom; y++)
        {
            if (y >= 0 && y < Grid.Sprite.GridSize)
            {
                if (left >= 0 && left < Grid.Sprite.GridSize)
                    grid[left, y] = color;
                if (right >= 0 && right < Grid.Sprite.GridSize)
                    grid[right, y] = color;
            }
        }
    }

    private (int x0, int y0, int x1, int y1) GetOrderedRectangleCoordinates(int x0, int y0, int x1, int y1)
    {
        int minX = Math.Min(x0, x1);
        int minY = Math.Min(y0, y1);
        int maxX = Math.Max(x0, x1);
        int maxY = Math.Max(y0, y1);

        return (minX, minY, maxX, maxY);
    }

    private void Fill()
    {
        var selectedColor = ColorPaletteCard.SelectedColor;
        var gridPoint = ConvertMousePositionToGridCell();
        int targetColor = Grid.Sprite.GridColors[gridPoint.X, gridPoint.Y];
        if (targetColor == selectedColor) return;

        Queue<Point> pixels = new Queue<Point>();
        pixels.Enqueue(gridPoint);

        while (pixels.Count > 0)
        {
            Point p = pixels.Dequeue();
            int x = p.X;
            int y = p.Y;

            if (x < 0 || x >= Grid.Sprite.GridSize || y < 0 || y >= Grid.Sprite.GridSize || Grid.Sprite.GridColors[x, y] != targetColor)
                continue;

            Grid.Sprite.GridColors[x, y] = selectedColor;

            pixels.Enqueue(new Point(x - 1, y));
            pixels.Enqueue(new Point(x + 1, y));
            pixels.Enqueue(new Point(x, y - 1));
            pixels.Enqueue(new Point(x, y + 1));
        }
    }

    private void ProcessLine(int[,] grid, int x0, int y0, int x1, int y1, int color)
    {
        int dx = Math.Abs(x1 - x0);
        int dy = Math.Abs(y1 - y0);
        int sx = x0 < x1 ? 1 : -1;
        int sy = y0 < y1 ? 1 : -1;
        int err = dx - dy;

        while (true)
        {
            // Ensure the point is within bounds
            if (x0 >= 0 && x0 < Grid.Sprite.GridSize && y0 >= 0 && y0 < Grid.Sprite.GridSize)
            {
                grid[x0, y0] = color;
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

    private Point ConvertMousePositionToGridCell()
    {
        var mousePosition = InputStateManager.MousePosition();
        int x = (mousePosition.X - Position.X) / Grid.Sprite.CellSize;
        int y = (mousePosition.Y - Position.Y) / Grid.Sprite.CellSize;
        return new Point(x, y);
    }
}
