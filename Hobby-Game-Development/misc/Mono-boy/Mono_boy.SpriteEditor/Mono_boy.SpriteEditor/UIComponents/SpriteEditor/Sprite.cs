namespace Mono_boy.SpriteEditor.UIComponents.SpriteEditor;

internal class Sprite
{
    public int CellSize;
    public int GridSize;
    public int[,] GridColors;

    public Sprite(int cellSize, int gridSize)
    {
        CellSize = cellSize;
        GridSize = gridSize; 
        GridColors = new int[GridSize, GridSize];
        ResetGridColors();
    }

    public void ResetGridColors()
    {
        for (int x = 0; x < GridSize; x++)
        {
            for (int y = 0; y < GridSize; y++)
            {
                GridColors[x, y] = 0;
            }
        }
    }

    public static int[,] CopyColorArray(int[,] original)
    {
        int rows = original.GetLength(0);
        int cols = original.GetLength(1);
        int[,] copy = new int[rows, cols];

        for (int i = 0; i < rows; i++)
        {
            for (int j = 0; j < cols; j++)
            {
                copy[i, j] = original[i, j];
            }
        }

        return copy;
    }

    public void MoveGrid(int deltaX, int deltaY)
    {
        var newGridColors = new int[GridSize, GridSize];

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
}
