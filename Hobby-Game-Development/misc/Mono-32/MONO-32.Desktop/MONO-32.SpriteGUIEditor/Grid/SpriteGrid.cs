using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MONO_32.Engine.Input;
using MONO_32.SpriteGUIEditor;
using MONO_32.SpriteGUIEditor.Buttons;
using System.Collections.Generic;

namespace Grid;

internal class SpriteGrid
{
    public int CellSize;
    public int GridSize;
    public List<Button> Buttons = new List<Button>();
    public Color[,] GridColors;

    private List<Color[,]> LastGridColors = new List<Color[,]>();
    private const int MaxHistorySize = 30;

    public SpriteGrid(int cellSize, int gridSize)
    {
        CellSize = cellSize;
        GridSize = gridSize;
        GridColors = new Color[GridSize, GridSize];
        for (int x = 0; x < GridSize; x++)
        {
            for (int y = 0; y < GridSize; y++)
            {
                GridColors[x, y] = new Color(0, 0, 0, 0); // invisible
            }
        }
    }

    public void UpdateMouseLeftClicked(Point mousePosition, int scaleFactor)
    {
        ProcessGrid(mousePosition, scaleFactor);
    }


    public void Update()
    {
        if (InputUtils.IsControlZReleased())
        {
            if (LastGridColors.Count > 0)
            {
                GetFromHistory();
            }
        }

        var up = InputUtils.IsKeyPressed(Keys.Up);
        var down = InputUtils.IsKeyPressed(Keys.Down);
        var left = InputUtils.IsKeyPressed(Keys.Left);
        var right = InputUtils.IsKeyPressed(Keys.Right);

        if (up)
        {
            MoveGrid(0, -1);
        }
        else if (down)
        {
            MoveGrid(0, 1);
        }
        else if (left)
        {
            MoveGrid(-1, 0);
        }
        else if (right)
        {
            MoveGrid(1, 0);
        }
    }

    public void Draw(SpriteBatch spriteBatch, int scaleFactor, Point translation)
    {
        int scaledCellSize = CellSize / scaleFactor;
        spriteBatch.Begin();

        // Draw selected color
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(UIVariables.OffsetX + UIVariables.TextInputFieldWidth + 2*UIVariables.ButtonSize, UIVariables.OffsetY, UIVariables.ButtonSize, UIVariables.ButtonSize), UIVariables.SelectedColor);

        // Get offset values
        var (ofx, ofy) = getOffsetValues();

        for (int x = 0; x < GridSize; x++)
        {
            for (int y = 0; y < GridSize; y++)
            {
                // Calculate the position with scaling and translation
                int drawX = ofx + x * scaledCellSize + translation.X;
                int drawY = ofy + y * scaledCellSize + translation.Y;

                // Draw the cell with scaling and translation
                spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(drawX, drawY, scaledCellSize, scaledCellSize), GridColors[x, y]);
            }
        }
        spriteBatch.End();
    }

    public void DrawGrid(SpriteBatch spriteBatch, int scaleFactor, Point translation, Color gridColor)
    {
        int scaledCellSize = CellSize / scaleFactor;
        spriteBatch.Begin();
        var (ofx, ofy) = getOffsetValues();

        // Calculate the position with scaling and translation
        ofx = ofx + translation.X;
        ofy = ofy + translation.Y;

        // Draw the outer rectangle
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(ofx, ofy, GridSize * scaledCellSize, 1), gridColor); // Top
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(ofx, ofy, 1, GridSize * scaledCellSize), gridColor); // Left
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(ofx, ofy + GridSize * scaledCellSize - 1, GridSize * scaledCellSize, 1), gridColor); // Bottom
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(ofx + GridSize * scaledCellSize - 1, ofy, 1, GridSize * scaledCellSize), gridColor); // Right
        for (int x = 0; x < GridSize; x++)
        {
            for (int y = 0; y < GridSize; y++)
            {
                // Draw vertical lines
                spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(ofx + x * scaledCellSize, ofy, 1, GridSize * scaledCellSize), gridColor);
                // Draw horizontal lines
                spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(ofx, ofy + y * scaledCellSize, GridSize * scaledCellSize, 1), gridColor);
            }
        }
        spriteBatch.End();
    }

    public Rectangle GetGridRectangle(int scaleFactor, Point translation)
    {
        int scaledCellSize = CellSize / scaleFactor;
        var (ofx, ofy) = getOffsetValues();
        ofx = ofx + translation.X;
        ofy = ofy + translation.Y;
        return new Rectangle(ofx, ofy, GridSize * scaledCellSize, GridSize * scaledCellSize);
    }

    public void DrawButtons(SpriteBatch spriteBatch, Point translation)
    {
        spriteBatch.Begin();

        for (int i = 0; i < Buttons.Count; i++)
        {
            var color = Color.Black;
            var rectangle = GetButtonRectangle(i, translation);
            spriteBatch.Draw(Buttons[i].Texture, rectangle, color);
        }

        spriteBatch.End();
    }

    public Rectangle GetButtonRectangle(int i, Point translation)
    {
        var (ofx, ofy) = getOffsetValues();

        int drawX = ofx + i * Buttons[i].Rectangle.Width + translation.X;
        int drawY = ofy + translation.Y;

        return new Rectangle(drawX, drawY, Buttons[i].Rectangle.Width, Buttons[i].Rectangle.Height);
    }

    public void Fill(Point mousePosition, int scaleFactor)
    {
        var gridPoint = ConvertMousePositionToGridCell(mousePosition, scaleFactor);
        Color targetColor = GridColors[gridPoint.X, gridPoint.Y];
        if (targetColor == UIVariables.SelectedColor) return;

        Queue<Point> pixels = new Queue<Point>();
        pixels.Enqueue(gridPoint);

        while (pixels.Count > 0)
        {
            Point p = pixels.Dequeue();
            int x = p.X;
            int y = p.Y;

            if (x < 0 || x >= GridSize || y < 0 || y >= GridSize || GridColors[x, y] != targetColor)
                continue;

            GridColors[x, y] = UIVariables.SelectedColor;

            pixels.Enqueue(new Point(x - 1, y));
            pixels.Enqueue(new Point(x + 1, y));
            pixels.Enqueue(new Point(x, y - 1));
            pixels.Enqueue(new Point(x, y + 1));
        }
    }

    public Texture2D ConvertToTexture2D(GraphicsDevice graphicsDevice)
    {
        var exportTexture = new Texture2D(graphicsDevice, GridSize, GridSize);
        Color[] colorData = new Color[GridSize * GridSize];
        for (int x = 0; x < GridSize; x++)
        {
            for (int y = 0; y < GridSize; y++)
            {
                colorData[x + y * GridSize] = GridColors[x, y];
            }
        }
        exportTexture.SetData(colorData);

        return exportTexture;
    }

    public static Color[,] CopyColorArray(Color[,] original)
    {
        int rows = original.GetLength(0);
        int cols = original.GetLength(1);
        Color[,] copy = new Color[rows, cols];

        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                copy[i, j] = original[i, j];
            }
        }

        return copy;
    }
    private (int, int) getOffsetValues()
    {
        var ofx = UIVariables.Edition.Right + UIVariables.Margin;
        var ofy = UIVariables.Edition.Top + UIVariables.Margin;
        return (ofx, ofy);
    }

    private void AddToHistory(Color[,] gridColors)
    {
        if (LastGridColors.Count >= MaxHistorySize)
        {
            // Remove the oldest state if the list is full
            LastGridColors.RemoveAt(0);
        }

        // Add the new state to the history
        LastGridColors.Add(gridColors);
    }

    private void GetFromHistory()
    {
        var lastGridState = LastGridColors[LastGridColors.Count - 1];
        GridColors = CopyColorArray(lastGridState);
        LastGridColors.RemoveAt(LastGridColors.Count - 1);
    }

    private void MoveGrid(int deltaX, int deltaY)
    {
        var newGridColors = new Color[GridSize, GridSize];

        for (int row = 0; row < GridSize; row++)
        {
            for (int col = 0; col < GridSize; col++)
            {
                int newRow = (row + deltaX + GridSize) % GridSize;
                int newCol = (col + deltaY + GridSize) % GridSize;

                newGridColors[newRow, newCol] = GridColors[row, col];
            }
        }

        GridColors = newGridColors;
    }

    private void ProcessGrid(Point mousePosition, int scaleFactor)
    {
        var gridPoint = ConvertMousePositionToGridCell(mousePosition, scaleFactor);
        int x = gridPoint.X;
        int y = gridPoint.Y;

        if (x >= 0 && x < GridSize && y >= 0 && y < GridSize)
        {
            if (InputUtils.IsMouseLeftButtonJustPressed())
            {
                AddToHistory(CopyColorArray(GridColors));
            }

            switch (UIVariables.PaintMode)
            {
                case MONO_32.SpriteGUIEditor.Enums.PaintModeEnum.Bucket:
                    Fill(mousePosition, scaleFactor);
                    break;
                case MONO_32.SpriteGUIEditor.Enums.PaintModeEnum.Pencil:
                    GridColors[x, y] = UIVariables.SelectedColor;
                    break;
                case MONO_32.SpriteGUIEditor.Enums.PaintModeEnum.Eraser:
                    GridColors[x, y] = new Color(0, 0, 0, 0);
                    break;
            }
        }
    }

    private Point ConvertMousePositionToGridCell(Point mousePosition, int scaleFactor)
    {
        int scaledCellSize = CellSize / scaleFactor;
        var (ofx, ofy) = getOffsetValues();
        // Convert mouse position to grid cell
        int x = mousePosition.X - ofx >= 0 ? (mousePosition.X - ofx) / scaledCellSize : -1;
        int y = mousePosition.Y - ofy >= 0 ? (mousePosition.Y - ofy) / scaledCellSize : -1;
        return new Point(x, y);
    }
}
