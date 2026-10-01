using gameengine.Data;
using gameengine.Input;
using gameengine.Scenes.Shared.Grid;
using gameengine.Scenes.Shared.UI;
using gameengine.Scenes.Shared.UI.Buttons.Colors;
using gameengine.Scenes.Shared.UI.Buttons.Page;
using gameengine.Scenes.Shared.UI.Buttons.Paint;
using gameengine.Scenes.Tile;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using System;
using System.Linq;

namespace gameengine.Scenes;

internal class TileScene : Scene
{
    private PaintButton[] _paintButtons = new PaintButton[16];
    private ColorOption[] _colorButtons = new ColorOption[16];
    private PageButton[] _pageButtons = new PageButton[10];
    private SelectedColorOption _selectedColorOption;
    private PaintOptionEnum _paintTileOption;
    private SpriteGrid _spriteGrid = new SpriteGrid();
    private FullSpriteGrid _fullSpriteGrid = new FullSpriteGrid();
    private double moveDelay = 0.2;
    private double moveTimer = 0;

    public TileScene(SceneManager sceneManager) : base(sceneManager)
    {
        _spriteGrid.CreateChessGrid();
        CreatePaintButtons();
        CreateColorButtons();
        CreatePageButtons();

        void CreatePaintButtons()
        {
            // Changing the order of these components will affect the index selection in Button_Clicked
            var components = new[]
            {
                UIComponentEnum.PencilTileButton,
                UIComponentEnum.EraserTileButton,
                UIComponentEnum.LineTileButton,
                UIComponentEnum.BucketTileButton,
                UIComponentEnum.PixelSize1TileButton,
                UIComponentEnum.PixelSize2TileButton,
                UIComponentEnum.PixelSize3TileButton,
                UIComponentEnum.PixelSize4TileButton,
                UIComponentEnum.CopyTileButton,
                UIComponentEnum.PasteTileButton,
                UIComponentEnum.UndoTileButton,
                UIComponentEnum.RedoTileButton,
                UIComponentEnum.FlipHTileButton,
                UIComponentEnum.FlipVTileButton,
                UIComponentEnum.RotateLeftTileButton,
                UIComponentEnum.RotateRightTileButton,
            };

            int index = 0;
            var buttonSize = 16;
            var offsetX = 3;
            var offsetY = 10;
            foreach (var component in components)
            {
                int column = index % 4;
                int row = index / 4;
                int posX = offsetX + column * (buttonSize + 3);
                int posY = offsetY + row * (buttonSize + 6);
                GameEngineData.UIComponentBounds[component] = new Rectangle(posX, posY, buttonSize, buttonSize);
                _paintButtons[index] = PaintButtonTileFactory.CreatePaintButton(component);
                _paintButtons[index].Clicked += Button_Clicked;
                index++;
            }

            // Select pencil button
            _paintButtons[0].Selected = true;
            _paintTileOption = PaintOptionEnum.Pencil;

            // Select penSize 1
            _paintButtons[4].Selected = true;
            _paintButtons[5].Selected = false;
            _paintButtons[6].Selected = false;
            _paintButtons[7].Selected = false;
            _spriteGrid.PenSize(1);

            void Button_Clicked(object sender, EventArgs e)
            {
                var buttonType = ((PaintButton)sender).Type;

                switch (buttonType)
                {
                    case PaintOptionEnum.Pencil:
                        UnselectButtons();
                        _paintButtons[0].Selected = true;
                        _paintTileOption = PaintOptionEnum.Pencil;
                        break;
                    case PaintOptionEnum.Eraser:
                        UnselectButtons();
                        _paintButtons[1].Selected = true;
                        _paintTileOption = PaintOptionEnum.Eraser;
                        break;
                    case PaintOptionEnum.Line:
                        UnselectButtons();
                        _paintButtons[2].Selected = true;
                        _paintTileOption = PaintOptionEnum.Line;
                        break;
                    case PaintOptionEnum.Bucket:
                        UnselectButtons();
                        _paintButtons[3].Selected = true;
                        _paintTileOption = PaintOptionEnum.Bucket;
                        break;                 
                    case PaintOptionEnum.PixelSize1:
                        _paintButtons[4].Selected = true;
                        _paintButtons[5].Selected = false;
                        _paintButtons[6].Selected = false;
                        _paintButtons[7].Selected = false;
                        _spriteGrid.PenSize(1);
                        break;
                    case PaintOptionEnum.PixelSize2:
                        _paintButtons[4].Selected = false;
                        _paintButtons[5].Selected = true;
                        _paintButtons[6].Selected = false;
                        _paintButtons[7].Selected = false;
                        _spriteGrid.PenSize(2);
                        break;
                    case PaintOptionEnum.PixelSize3:
                        _paintButtons[4].Selected = false;
                        _paintButtons[5].Selected = false;
                        _paintButtons[6].Selected = true;
                        _paintButtons[7].Selected = false;
                        _spriteGrid.PenSize(3);
                        break;
                    case PaintOptionEnum.PixelSize4:
                        _paintButtons[4].Selected = false;
                        _paintButtons[5].Selected = false;
                        _paintButtons[6].Selected = false;
                        _paintButtons[7].Selected = true;
                        _spriteGrid.PenSize(4);
                        break;
                    case PaintOptionEnum.Copy:
                        TileData.Copy();
                        break;
                    case PaintOptionEnum.Paste:
                        TileData.Paste();
                        break;
                    case PaintOptionEnum.Undo:
                        TileData.Undo();
                        break;
                    case PaintOptionEnum.Redo:
                        TileData.Redo();
                        break;                    
                    case PaintOptionEnum.FlipH:
                        TileData.UpdateStackHistory();
                        TileData.FlipH();
                        break;
                    case PaintOptionEnum.FlipV:
                        TileData.UpdateStackHistory();
                        TileData.FlipV();
                        break;
                    case PaintOptionEnum.RotateLeft:
                        TileData.UpdateStackHistory();
                        TileData.RotateLeft();
                        break;
                    case PaintOptionEnum.RotateRight:
                        TileData.UpdateStackHistory();
                        TileData.RotateRight();
                        break;
                }

                void UnselectButtons()
                {
                    var buttonList = new PaintOptionEnum[] {
                        PaintOptionEnum.Pencil, PaintOptionEnum.Bucket, PaintOptionEnum.Eraser,
                        PaintOptionEnum.Line, PaintOptionEnum.Rectangle,PaintOptionEnum.Circle,
                        PaintOptionEnum.SelectionRectangle, PaintOptionEnum.Delete
                    };

                    foreach (var paintButton in _paintButtons.Where(b => buttonList.Contains(b.Type)).ToList())
                    {
                        paintButton.Selected = false;
                    }
                }
            }
        }

        void CreateColorButtons()
        {
            int index = 0; 
            var buttonSize = 16;
            var offsetX = 3;
            var offsetY = 120;
            foreach (var colorButton in _colorButtons)
            {
                int column = index % 4;
                int row = index / 4;
                int posX = offsetX + column * (buttonSize + 3);
                int posY = offsetY + row * (buttonSize + 3);
                var enumButton = (UIComponentEnum)((int)UIComponentEnum.ColorOption1 + index);
                GameEngineData.UIComponentBounds[enumButton] = new Rectangle(posX, posY, buttonSize, buttonSize);
                _colorButtons[index] = new ColorOption(index + 1, enumButton);
                _colorButtons[index].Clicked += ColorButton_Clicked;
                index++;
            }

            GameEngineData.UIComponentBounds[UIComponentEnum.SelectedColorOption] = new Rectangle(offsetX, 200, 73, 8);

            // Select first color
            _colorButtons[0].Selected = true;
            _selectedColorOption = new SelectedColorOption(_colorButtons[0].ColorIndex, UIComponentEnum.SelectedColorOption);

            void ColorButton_Clicked(object sender, EventArgs e)
            {
                var colorSelected = ((ColorOption)sender).ColorIndex;
                UpdateColorButtons(colorSelected);

                void UpdateColorButtons(int colorSelected)
                {
                    foreach (var paintButton in _colorButtons)
                    {
                        if (colorSelected == paintButton.ColorIndex)
                        {
                            _selectedColorOption.ColorIndex = colorSelected;
                            paintButton.Selected = true;
                            continue;
                        }

                        paintButton.Selected = false;
                    }
                }
            }
        }

        void CreatePageButtons()
        {
            int index = 0;
            var buttonSizeX = 13;
            var buttonSizeY = 15;
            var offsetX = TileData.PositionToDrawMap.X - 1;
            var offsetY = 17;
            foreach (var pageButton in _pageButtons)
            {
                int posX = offsetX + index * buttonSizeX;
                int posY = offsetY;
                var enumPageButton = (UIComponentEnum)((int)UIComponentEnum.Page0TileButton + index);
                GameEngineData.UIComponentBounds[enumPageButton] = new Rectangle(posX, posY, buttonSizeX, buttonSizeY);
                _pageButtons[index] = new PageButton(index, enumPageButton);
                _pageButtons[index].Clicked += PageButton_Clicked;
                index++;
            }

            // Select page 0
            UnSelectPages();
            _pageButtons[0].Selected = true;

            void PageButton_Clicked(object sender, EventArgs e)
            {
                var page = ((PageButton)sender).Page;
                UnSelectPages();
                _pageButtons[page].Selected = true;
                TileData.UpdatePage(page);
            }

            void UnSelectPages()
            {
                foreach (var pageButton in _pageButtons)
                {
                    pageButton.Selected = false;
                }
            }
        }
    }

    public override void Update()
    {
        _paintButtons[9].Disabled = false;
        _paintButtons[10].Disabled = false;
        _paintButtons[11].Disabled = false;

        if (TileData._undoHistory.Count == 0)
        {
            // Undo
            _paintButtons[10].Disabled = true;
        }

        if (TileData._redoHistory.Count == 0)
        {
            // Redo
            _paintButtons[11].Disabled = true;
        }

        if (!TileData.Copied)
        {
            // Paste
            _paintButtons[9].Disabled = true;
        }

        foreach (var paintButton in _paintButtons)
        {
            paintButton.Update();
        }

        foreach (var colorButton in _colorButtons)
        {
            colorButton.Update();
        }

        foreach (var pageButton in _pageButtons)
        {
            pageButton.Update();
        }
        
        _selectedColorOption.Update();
        _fullSpriteGrid.Update();

        var isMouseLeftPressed = MouseInput.LeftButton_Pressed();
        var isMouseLeftJustPressed = MouseInput.LeftButton_JustPressed();
        var isMouseLeftReleased = MouseInput.LeftButton_Released();
        var isMouseRightPressed = MouseInput.RightButton_Pressed();
        var isMouseRightJustPressed = MouseInput.RightButton_JustPressed();
        var isMouseRightReleased = MouseInput.RightButton_Released();
        var shiftPressed = KeyboardInput.IsShiftPressed();
        var controlPressed = KeyboardInput.IsControlPressed();

        MoveSprite();
        UpdateGrid();
        UpdateFullSpriteGrid();

        void UpdateGrid()
        {
            var (mousePosInGrid, isMouseInGrid) = _spriteGrid.ConvertMousePositionToGridCell();
            var isMouseLeftPressedOnGrid = isMouseLeftPressed && isMouseInGrid;
            var isMouseLeftJustPressedOnGrid = isMouseLeftJustPressed && isMouseInGrid;
            var isMouseRightJustPressedOnGrid = isMouseRightJustPressed && isMouseInGrid;
            var isMouseLeftReleasedOnGrid = isMouseLeftReleased && isMouseInGrid;
            var isMouseLeftReleasedOffGrid = isMouseLeftReleased && !isMouseInGrid;
            var x = mousePosInGrid.X;
            var y = mousePosInGrid.Y;

            if (MouseInput.ScrollUp())
            {
                _spriteGrid.ZoomIn();
            }
            else if (MouseInput.ScrollDown())
            {
                _spriteGrid.ZoomOut();
            }

            switch (_paintTileOption)
            {
                case PaintOptionEnum.Pencil:
                    if (isMouseLeftPressedOnGrid)
                    {
                        TileData.UpdateStackHistory();
                        _spriteGrid.UpdateGameDataTilesGridWithPen(x, y, _selectedColorOption.ColorIndex, shiftPressed, controlPressed);
                    }
                    break;
                case PaintOptionEnum.Eraser:
                    if (isMouseLeftPressedOnGrid)
                    {
                        TileData.UpdateStackHistory();
                        _spriteGrid.UpdateGameDataTilesGridWithPen(x, y, 0);
                    }
                    else if (isMouseRightJustPressedOnGrid)
                    {
                        TileData.UpdateStackHistory();
                        _spriteGrid.EraseAllArea();
                    }
                    break;
                case PaintOptionEnum.Bucket:
                    if (isMouseLeftJustPressedOnGrid)
                    {
                        TileData.UpdateStackHistory();
                        _spriteGrid.Fill(new Point(x, y), _selectedColorOption.ColorIndex);
                    }
                    break;
                case PaintOptionEnum.Line:
                    _spriteGrid.TemporaryGrid.ResetGridColors();
                    if (isMouseLeftJustPressedOnGrid)
                    {
                        // Start Line Drawing
                        _spriteGrid.LineStartPoint = new Point(x, y);
                    }
                    else if (isMouseLeftReleasedOnGrid)
                    {
                        // Paint Line
                        if (_spriteGrid.LineStartPoint.HasValue)
                        {
                            TileData.UpdateStackHistory();
                            _spriteGrid.ProcessLine(x, y, _selectedColorOption.ColorIndex);
                            _spriteGrid.LineStartPoint = null;
                        }
                    }
                    else if (isMouseRightJustPressed || isMouseLeftReleasedOffGrid)
                    {
                        // End Line Drawing
                        _spriteGrid.LineStartPoint = null;
                    }

                    if (_spriteGrid.LineStartPoint.HasValue)
                    {
                        _spriteGrid.ProcessLine(x, y, _selectedColorOption.ColorIndex, true);
                    }
                    break;
            }
        }

        void UpdateFullSpriteGrid()
        {
            
            if (!isMouseLeftJustPressed && !isMouseRightJustPressed)
            {
                return;
            }
            
            var (mousePosInFullSpriteGrid, isMouseInFullSpriteGrid) = _fullSpriteGrid.ConvertMousePositionToGridCell();

            if (!isMouseInFullSpriteGrid)
            {
                return;
            }

            var isMouseLeftPressedOnFullSpriteGrid = isMouseLeftPressed && isMouseInFullSpriteGrid;
            var isMouseLeftJustPressedOnFullSpriteGrid = isMouseLeftJustPressed && isMouseInFullSpriteGrid;
            var isMouseRightJustPressedOnFullSpriteGrid = isMouseRightJustPressed && isMouseInFullSpriteGrid;
            var isMouseLeftReleasedOnFullSpriteGrid = isMouseLeftReleased && isMouseInFullSpriteGrid;
            var x = mousePosInFullSpriteGrid.X;
            var y = mousePosInFullSpriteGrid.Y;

            if (isMouseLeftJustPressedOnFullSpriteGrid)
            {
                TileData.UpdateCurrentSpritePosition(x, y);
            }
            else if (isMouseRightJustPressedOnFullSpriteGrid)
            {
                TileData.ToogleBackgroundUpdateCurrentSpritePosition(x, y);
            }
        }
    }

    private void MoveSprite()
    {
        moveTimer += FrameworkData.DeltaTime;

        if (moveTimer < moveDelay)
        {
            return;
        }

        var up = KeyboardInput.IsUpPressed();
        var down = KeyboardInput.IsDownPressed();
        var left = KeyboardInput.IsLeftPressed();
        var right = KeyboardInput.IsRightPressed();

        if (!up && !down && !left && !right)
        {
            return;
        }

        TileData.UpdateStackHistory();

        if (up)
        {
            _spriteGrid.MoveGrid(0, -1);
        }
        else if (down)
        {
            _spriteGrid.MoveGrid(0, 1);
        }
        else if (left)
        {
            _spriteGrid.MoveGrid(-1, 0);
        }
        else if (right)
        {
            _spriteGrid.MoveGrid(1, 0);
        }

        moveTimer = 0;
    }

    public override void Draw()
    {
        _spriteGrid.DrawChessGrid();

        var spriteBatch = FrameworkData.SpriteBatch;

        spriteBatch.DrawText_MediumFont(TileData.GetTileNumber().ToString("0000"), new Vector2(390, 8), 2, 1f, 2f, -1);

        if (TileData.BackgroundCurrentSpritePosition.X >= 0)
        {
            spriteBatch.DrawText_MediumFont(TileData.GetBackgroundTileNumber().ToString("0000"), new Vector2(425, 8), 3, 1f, 2f, -1);
        }

        foreach (var paintButton in _paintButtons)
        {
            paintButton.Draw();
        }

        foreach (var colorButton in _colorButtons)
        {
            colorButton.Draw();
        }

        foreach (var pageButton in _pageButtons)
        {
            pageButton.Draw();
        }

        _selectedColorOption.Draw();
        _fullSpriteGrid.Draw();
        _fullSpriteGrid.DrawSelector(TileData.CurrentSpritePosition, 2, TileData.Zoom);
        _fullSpriteGrid.DrawBackGroundSelector();
        _spriteGrid.DrawSpriteGrid();
    }

    public override void Exit()
    {
        TileData.CleanStackHistory();
    }

    public override void Enter()
    {
    }
}