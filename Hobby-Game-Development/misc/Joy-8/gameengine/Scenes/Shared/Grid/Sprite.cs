namespace gameengine.Scenes.Shared.Grid;

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
}