using gameengine.Data;
using gameengine.Input;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using System;

namespace gameengine.Scenes.Shared.Grid;

internal class FullSpriteGrid
{
    private Rectangle _bounds;

    public FullSpriteGrid()
    {
        _bounds = TileData.GetMapBounds();
        GameEngineData.Images.Add(
                "fullspriteselectorborder1",
                TextureUtils.CreateRectangleTexture(TileData.GetSelectorBorder(1), 2));
        GameEngineData.Images.Add(
                "fullspriteselectorborder2",
                TextureUtils.CreateRectangleTexture(TileData.GetSelectorBorder(2), 2));
        GameEngineData.Images.Add(
                "fullspriteselectorborder3",
                TextureUtils.CreateRectangleTexture(TileData.GetSelectorBorder(3), 2));
        GameEngineData.Images.Add(
                "fullspriteselectorborder4",
                TextureUtils.CreateRectangleTexture(TileData.GetSelectorBorder(4), 2));
        GameEngineData.Images.Add(
                "fullspriteselectorborder5",
                TextureUtils.CreateRectangleTexture(TileData.GetSelectorBorder(6), 2));
        GameEngineData.Images.Add(
                "fullspriteselectorborder6",
                TextureUtils.CreateRectangleTexture(TileData.GetSelectorBorder(8), 2));
    }

    public void Update()
    {
    }

    public void Draw()
    {
        var spriteBatch = FrameworkData.SpriteBatch;

        spriteBatch.DrawRectangle(
            new Rectangle(
                _bounds.X,
                0,
                _bounds.Width * TileData.Scale,
                18               
            ), 1, 0.2f);

        spriteBatch.DrawRectangle(new Rectangle(
                _bounds.X,
                _bounds.Y,
                _bounds.Width * TileData.Scale,
                _bounds.Height * TileData.Scale
            ), 1, 0.2f);
        for (int x = 0; x < _bounds.Width; x++)
        {
            for (int y = 0; y < _bounds.Height; y++)
            {
                spriteBatch.DrawRectangle(
                    new Rectangle(
                        _bounds.X + x * TileData.Scale,
                        _bounds.Y + y * TileData.Scale,
                        TileData.Scale,
                        TileData.Scale),
                    GameData.TilesGrid[TileData.GetPage() * _bounds.Width + x, y]);
            }
        }
    }

    public void DrawBackGroundSelector()
    {
        var spritePosition = TileData.BackgroundCurrentSpritePosition;
        if (spritePosition.X < 0)
        {
            return;
        }

        (int gridSize, int cellSize) = TileData.GetSizes(TileData.Zoom);

        int scaleX = gridSize / TileData.MinGridSize;
        int scaleY = gridSize / TileData.MinGridSize;

        if (TileData.Columns - spritePosition.X % TileData.Columns < gridSize / TileData.MinGridSize)
        {
            scaleX = (TileData.Columns - spritePosition.X % TileData.Columns);
        }

        if (TileData.Rows - spritePosition.Y < gridSize / TileData.MinGridSize)
        {
            scaleY = (TileData.Rows - spritePosition.Y);
        }

        var spriteBatch = FrameworkData.SpriteBatch;
        var tileSquare = TileData.MinTileSize * TileData.Scale;
        var ofx = _bounds.X + (spritePosition.X % TileData.Columns) * tileSquare;
        var ofy = _bounds.Y + spritePosition.Y * tileSquare;
        spriteBatch.DrawRectangle(
            new Rectangle(ofx, ofy, tileSquare * scaleX, tileSquare * scaleY),
            3, 0.2f);
    }

    public void DrawSelector(Point spritePosition, int colorIndex, int zoom)
    {
        if (spritePosition.X < 0)
        {
            return;
        }

        (int gridSize, int cellSize) = TileData.GetSizes(zoom);
        var spriteBatch = FrameworkData.SpriteBatch;
        var tileSquare = TileData.MinTileSize * TileData.Scale;
        var ofx = _bounds.X + (spritePosition.X % TileData.Columns) * tileSquare;
        var ofy = _bounds.Y + spritePosition.Y * tileSquare;
        spriteBatch.DrawImage(
            $"fullspriteselectorborder{zoom}",
            new Rectangle(ofx,ofy, tileSquare * gridSize / TileData.MinGridSize, tileSquare * gridSize / TileData.MinGridSize),
            colorIndex, 0.5f);
    }

    public (Point, bool) ConvertMousePositionToGridCell()
    {
        var mousePosition = MouseInput.MousePosition();

        if (mousePosition.X - _bounds.X < 0 || mousePosition.Y - _bounds.Y < 0)
        {
            return (new Point(0, 0), false);
        }
        var tileSquare = TileData.MinTileSize * TileData.Scale;
        int x = (mousePosition.X - _bounds.X) / tileSquare;
        int y = (mousePosition.Y - _bounds.Y) / tileSquare;
        return (new Point(TileData.GetPage() * TileData.Columns + x, y), IsMouseInGrid(x, y));

        bool IsMouseInGrid(int x, int y)
        {
            return x >= 0 && x < TileData.Columns && y >= 0 && y < TileData.Rows;
        }
    }
}
