using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.MapEditor;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Manager;

internal class MapEditorManager : ISceneManager
{
    public static TileEditorCard TileEditor;
    public TileEditorButtonsCard TileEditorButtons;
    public LayersCard Layers;
    public static int SelectedTile;
    public static MapEditor Map;
    public static List<bool> DisplayLayer = new List<bool>() { true, true, true, true, true };
    public static int CurrentLayer = 0;
    public static int GridSize = 500;

    public SceneEnum SceneType { get; set; }

    public NavButtonEnum NavButton { get; set; }

    public MapEditorManager()
    {
        SceneType = SceneEnum.MAP;
        NavButton = NavButtonEnum.Map;
    }

    public void LoadContent()
    {
        SelectedTile = 0;
        TileEditor = new TileEditorCard(new Point(4,80), 32);
        TileEditorButtons = new TileEditorButtonsCard(new Rectangle(3, 309, 130, 40));
        Layers = new LayersCard(new Rectangle(3, 352, 130, 60));
        var cellSize = 32;
        int numberCellsW = (GlobalManager.GraphicsDevice.Viewport.Width - 200) / cellSize;
        int numberCellsH = (GlobalManager.GraphicsDevice.Viewport.Height - 150) / cellSize;
        Map = new MapEditor(new Point(GlobalManager.GraphicsDevice.Viewport.Width - numberCellsW * cellSize - 8, 80), numberCellsW, numberCellsH, cellSize);
    }

    public void Reload()
    {
        TileEditor.LoadSprites();
    }

    public void Update()
    {
        TileEditor.Update();
        TileEditorButtons.Update();
        Layers.Update();
        Map.Update();
    }

    public void Draw()
    {
        TileEditor.Draw();
        TileEditorButtons.Draw();
        Layers.Draw();
        Map.Draw();
    }
}