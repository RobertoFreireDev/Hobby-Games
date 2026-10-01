using Grid;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MONO_32.SpriteGUIEditor.Buttons;
using MONO_32.SpriteGUIEditor.Enums;
using System.Collections.Generic;
using System.Linq;

namespace MONO_32.SpriteGUIEditor.Grid;

internal class SpriteGrids
{
    public SpriteGrid currentSpriteGrid;

    private List<SpriteGrid> spriteGrids = new List<SpriteGrid>();
    private int scaleFactor = 1;
    private int miniatureScale = 4;

    public SpriteGrids()
    {
        AddSprite();
    }

    public void AddSprite(Color[,] gridColor = null, int index = 0)
    {
        var newSpriteGrid = new SpriteGrid(UIVariables.CellSize, UIVariables.GridSize);

        if (gridColor is not null)
        {
            newSpriteGrid.GridColors = SpriteGrid.CopyColorArray(gridColor);
        }

        var buttons = new List<Button>();

        buttons.Add(new Button(
                ButtonTypeEnum.Delete,
                UIVariables.Textures["delete_button"]
            ));
        buttons.Add(new Button(
               ButtonTypeEnum.LeftArrow,
               UIVariables.Textures["left_arrow_button"]
           ));
        buttons.Add(new Button(
               ButtonTypeEnum.RightArrow,
               UIVariables.Textures["right_arrow_button"]
           ));
        buttons.Add(new Button(
               ButtonTypeEnum.Copy,
               UIVariables.Textures["copy_button"]
           ));
        buttons.Add(new Button(
               ButtonTypeEnum.Add,
               UIVariables.Textures["add_button"]
           ));

        for (int i = 0; i < buttons.Count; i++)
        {
            buttons[i].Rectangle = new Rectangle(
                0,
                0,
                UIVariables.ButtonSize * 4 / 5,
                UIVariables.ButtonSize * 4 / 5);
        }

        newSpriteGrid.Buttons = buttons;

        if (index == spriteGrids.Count)
        {
            spriteGrids.Add(newSpriteGrid);
        }
        else
        {
            spriteGrids.Insert(index + 1, newSpriteGrid);
        }

        currentSpriteGrid = newSpriteGrid;
    }

    public void UpdateMouseLeftClicked(Point mousePosition)
    {
        currentSpriteGrid.UpdateMouseLeftClicked(mousePosition, scaleFactor);
        UpdateMouseLeftClickedMiniatureGrid(mousePosition);
    }

    public void UpdateMouseLeftReleased(Point mousePosition)
    {
        UpdateButtonsMiniature(mousePosition);
    }

    public void Update()
    {
        currentSpriteGrid.Update();
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        var totalSize = UIVariables.CellSize * UIVariables.GridSize;

        currentSpriteGrid.Draw(spriteBatch, scaleFactor, Point.Zero);
        currentSpriteGrid.DrawGrid(spriteBatch, scaleFactor, Point.Zero, Color.Black);

        // draw miniature
        for (int i = 0; i < spriteGrids.Count; i++)
        {
            spriteGrids[i].Draw(spriteBatch, miniatureScale, new Point(-UIVariables.Edition.Width + i * totalSize / miniatureScale, 2 * UIVariables.Margin + totalSize));
            spriteGrids[i].DrawGrid(spriteBatch, miniatureScale, GetMiniatureGridPoint(i), Color.Black);
            spriteGrids[i].DrawButtons(spriteBatch, GetButtonPoint(i));
        }
    }

    private Point GetMiniatureGridPoint(int i)
    {
        var totalSize = UIVariables.CellSize * UIVariables.GridSize;
        return new Point(-UIVariables.Edition.Width + i * totalSize / miniatureScale, 2 * UIVariables.Margin + totalSize);
    }

    private Point GetButtonPoint(int i)
    {
        var totalSize = UIVariables.CellSize * UIVariables.GridSize;
        return new Point(-UIVariables.Edition.Width + i * totalSize / miniatureScale, 3 * UIVariables.Margin + totalSize + totalSize / miniatureScale);
    }

    private void UpdateButtonsMiniature(Point mousePosition)
    {
        for (int i = 0; i < spriteGrids.Count; i++)
        {
            var buttons = spriteGrids[i].Buttons;
            var point = GetButtonPoint(i);
            for (int j = 0; j < buttons.Count; j++)
            {
                var rectangle = spriteGrids[i].GetButtonRectangle(j, point);
                if (rectangle.Contains(mousePosition))
                {
                    switch (buttons[j].Type)
                    {
                        case Enums.ButtonTypeEnum.Delete:
                            if (spriteGrids.Count > 1)
                            {
                                var update = currentSpriteGrid == spriteGrids[i];
                                spriteGrids.Remove(spriteGrids[i]);
                                if (update)
                                {
                                    currentSpriteGrid = spriteGrids.First();
                                }
                            }
                            return;
                        case Enums.ButtonTypeEnum.LeftArrow:
                            if (i > 0)
                            {
                                SpriteGrid temp = spriteGrids[i];
                                spriteGrids[i] = spriteGrids[i-1];
                                spriteGrids[i - 1] = temp;
                            }
                            return;
                        case Enums.ButtonTypeEnum.RightArrow:
                            if (i < spriteGrids.Count - 1)
                            {
                                SpriteGrid temp = spriteGrids[i];
                                spriteGrids[i] = spriteGrids[i + 1];
                                spriteGrids[i + 1] = temp;
                            }
                            return;
                        case Enums.ButtonTypeEnum.Copy:
                            if (spriteGrids.Count < 10)
                            {
                                AddSprite(spriteGrids[i].GridColors, i);
                            }
                            return;
                        case Enums.ButtonTypeEnum.Add:
                            if (spriteGrids.Count < 10)
                            {
                                AddSprite(null, i);
                            }
                            return;
                    }
                }
            }
        }
    }

    private void UpdateMouseLeftClickedMiniatureGrid(Point mousePosition)
    {
        for (int i = 0; i < spriteGrids.Count; i++)
        {
            var miniatureGridRectangle = spriteGrids[i].GetGridRectangle(miniatureScale, GetMiniatureGridPoint(i));

            if (miniatureGridRectangle.Contains(mousePosition))
            {
                currentSpriteGrid = spriteGrids[i];
            }
        }
    }
}
