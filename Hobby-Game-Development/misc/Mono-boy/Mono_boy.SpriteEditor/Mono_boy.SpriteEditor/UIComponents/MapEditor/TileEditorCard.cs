using System.Collections.Generic;
using Microsoft.Xna.Framework;
using System.Linq;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Extensions;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Input;

namespace Mono_boy.SpriteEditor.UIComponents.MapEditor;

internal class TileEditorCard
{
    public List<Texture2D> GridColorsList;
    public Pagination Pagination;
    public Point Position;
    private int _size;

    public TileEditorCard(Point position, int size)
    {
        Position = position;
        Pagination = new Pagination(7, 4, 0, 18);
        _size = size;
        LoadSprites();
    }

    public void LoadSprites()
    {
        GridColorsList = SpriteEditorManager.Sprites.Sprites.Select(s => s.Sprite.GridColors.ConvertToTexture2D().Texture).ToList();
    }

    public void Update()
    {
        ClickedTile();
    }

    protected void ClickedTile()
    {
        if (!InputStateManager.IsMouseLeftButtonJustPressed())
        {
            return;
        }

        var mousePosition = InputStateManager.MousePosition();
        int gridWidth = Pagination.Column * _size;
        int gridHeight = Pagination.Row * _size;
        if (mousePosition.X < Position.X || mousePosition.X > Position.X + gridWidth ||
            mousePosition.Y < Position.Y || mousePosition.Y > Position.Y + gridHeight)
        {
            return; // Mouse is outside the grid
        }

        int gridX = (mousePosition.X - Position.X) / _size;
        int gridY = (mousePosition.Y - Position.Y) / _size;
        int clickedIndex = gridY * Pagination.Column + gridX;
        MapEditorManager.SelectedTile = clickedIndex + Pagination.CurrentPage * Pagination.Row * Pagination.Column;
    }

    public void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var spritesPerPage = Pagination.Row * Pagination.Column;

        int r = 0;
        int c = 0;
        int i = Pagination.CurrentPage * spritesPerPage;

        spriteBatch.DrawBorder(
            new Rectangle(
                Position.X, 
                Position.Y,
                Pagination.Column * _size,
                Pagination.Row * _size),1,1,new Point(-1,-1));

        foreach (var grid in GridColorsList
            .Skip(Pagination.CurrentPage * spritesPerPage)
            .Take(spritesPerPage))
        {
            int drawX = Position.X + c * _size;
            int drawY = Position.Y + r * _size;
            spriteBatch.CustomDraw(grid, new Vector2(drawX, drawY), Color.White);
            c += 1;
            if (c >= Pagination.Column)
            {
                r += 1;
                c = 0;
            }
            i++;
        }  
    }
}