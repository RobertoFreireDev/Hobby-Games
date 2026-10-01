using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.MapEditor;

internal class MapEditor
{
    public List<int[,]> Tiles;
    private int _gridSize;
    private int _cellSize;
    private int _width;
    private int _height;
    private Point _position;
    private Point _pointer;
    private double _moveDelay = 0.1;
    private double _moveTimer = 0;

    public MapEditor(Point position, int width, int height, int cellSize)
    {
        _gridSize = MapEditorManager.GridSize;
        _cellSize = cellSize;
        _position = position;
        _width = width;
        _height = height;
        _pointer = new Point(0, 0);
        Tiles = Games.GetCurrentGame().LoadTiles();
    }

    public void Update()
    {
        ClickedTile();
        MoveMap();

        if (InputStateManager.IsDelJustPressed())
        {
            DeleteCurrentArea();
        }
    }

    private void DeleteCurrentArea()
    {
        for (int x = 0; x < _width; x++)
        {
            for (int y = 0; y < _height; y++)
            {
                Tiles[MapEditorManager.CurrentLayer][_pointer.X + x, _pointer.Y + y] = 0;
            }
        }
    }

    private void MoveMap()
    {
        _moveTimer += GlobalManager.DeltaTime;

        if (!InputStateManager.IsControlPressed() && _moveTimer < _moveDelay)
        {
            return;
        }

        var up = InputStateManager.IsUpPressed();
        var down = InputStateManager.IsDownPressed();
        var left = InputStateManager.IsLeftPressed();
        var right = InputStateManager.IsRightPressed();

        if (up && _pointer.Y > 0)
        {
            _pointer.Y += -1;
        }
        else if (down && _pointer.Y < _gridSize - _height)
        {
            _pointer.Y += 1;
        }
        else if (left && _pointer.X > 0)
        {
            _pointer.X += -1;
        }
        else if (right && _pointer.X < _gridSize - _width)
        {
            _pointer.X += 1;
        }

        _moveTimer = 0;
    }

    private void ClickedTile()
    {
        if (!InputStateManager.IsMouseLeftButtonPressed())
        {
            return;
        }

        var mousePosition = InputStateManager.MousePosition();
        int gridWidth = _cellSize * _width;
        int gridHeight = _cellSize * _height;
        int gridX = (mousePosition.X - _position.X) / _cellSize;
        int gridY = (mousePosition.Y - _position.Y) / _cellSize;

        if (mousePosition.X < _position.X || mousePosition.X > _position.X + gridWidth ||
            mousePosition.Y < _position.Y || mousePosition.Y > _position.Y + gridHeight ||
            gridX < 0 || gridX >= _width || gridY < 0 || gridY >= _height)
        {
            return; // Mouse is outside the grid
        }
        Tiles[MapEditorManager.CurrentLayer][_pointer.X + gridX, _pointer.Y + gridY] = MapEditorManager.SelectedTile;
    }

    public void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var pixelTexture = GlobalManager.PixelTexture;
        spriteBatch.DrawBorder(
            new Rectangle(
                _position.X,
                _position.Y,
                _cellSize* _width,
                _cellSize * _height), 1, 1, new Point(-1, -1));

        for (int x = 1; x < _width; x++)
        {
            for (int y = 1; y < _height; y++)
            {
                int drawX = _position.X + x * _cellSize;
                int drawY = _position.Y + y * _cellSize;
                // Draw vertical lines
                spriteBatch.CustomDraw(pixelTexture, new Rectangle(drawX, _position.Y, 1, _height * _cellSize), ColorUtils.GetColor(1));
                // Draw horizontal lines
                spriteBatch.CustomDraw(pixelTexture, new Rectangle(_position.X, drawY, _width * _cellSize, 1), ColorUtils.GetColor(1));
            }
        }

        for (int i = 0; i < Tiles.Count; i++)
        {
            if (!MapEditorManager.DisplayLayer[i])
            {
                continue;
            }
            for (int x = 0; x < _width; x++)
            {
                for (int y = 0; y < _height; y++)
                {
                    int drawX = _position.X + x * _cellSize;
                    int drawY = _position.Y + y * _cellSize;
                    spriteBatch.CustomDraw(
                        MapEditorManager.TileEditor.GridColorsList[Tiles[i][_pointer.X + x, _pointer.Y + y]],
                        new Rectangle(drawX, drawY, _cellSize, _cellSize),
                        Color.White);
                }
            }
        }
    }
}
