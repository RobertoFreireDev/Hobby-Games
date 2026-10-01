using gameengine.Data;
using gameengine.Scenes.ColorPalette;
using gameengine.Scenes.Shared.UI;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using System;

namespace gameengine.Scenes;

internal class ColorPaletteScene : Scene
{
    public ColorPaletteOption[] Palettes { get; set; } = new ColorPaletteOption[24];

    public ColorPaletteScene(SceneManager sceneManager) : base(sceneManager)
    {
        var components = new[]
        {
            UIComponentEnum.ColorPaletteOption1,
            UIComponentEnum.ColorPaletteOption2,
            UIComponentEnum.ColorPaletteOption3,
            UIComponentEnum.ColorPaletteOption4,
            UIComponentEnum.ColorPaletteOption5,
            UIComponentEnum.ColorPaletteOption6,
            UIComponentEnum.ColorPaletteOption7,
            UIComponentEnum.ColorPaletteOption8,
            UIComponentEnum.ColorPaletteOption9,
            UIComponentEnum.ColorPaletteOption10,
            UIComponentEnum.ColorPaletteOption11,
            UIComponentEnum.ColorPaletteOption12,
            UIComponentEnum.ColorPaletteOption13,
            UIComponentEnum.ColorPaletteOption14,
            UIComponentEnum.ColorPaletteOption15,
            UIComponentEnum.ColorPaletteOption16,
            UIComponentEnum.ColorPaletteOption17,
            UIComponentEnum.ColorPaletteOption18,
            UIComponentEnum.ColorPaletteOption19,
            UIComponentEnum.ColorPaletteOption20,
            UIComponentEnum.ColorPaletteOption21,
            UIComponentEnum.ColorPaletteOption22,
            UIComponentEnum.ColorPaletteOption23,
            UIComponentEnum.ColorPaletteOption24,
        };

        int index = 0;
        int size = 15;
        int columnWidth = size * 16 + 3;
        int rowHeight = size + 4;
        int offsetX = 10;
        int offsetY = 30;

        foreach (var component in components)
        {
            int column = index % 2;
            int row = index / 2;
            int posX = offsetX + column * (columnWidth + 10);
            int posY = offsetY + row * (rowHeight + 2);
            GameEngineData.UIComponentBounds[component] = new Rectangle(posX, posY, columnWidth, rowHeight);
            Palettes[index] = new ColorPaletteOption(index, component);
            Palettes[index].Clicked += Button_Clicked;
            index++;
        }

        GameEngineData.Images.Add(
                "colorpaletteborder",
                TextureUtils.CreateRectangleTexture(new Rectangle(0, 0, columnWidth, rowHeight), 2));
    }

    public override void Update()
    {
        foreach (var palette in Palettes)
        {
            palette.Update();
        }
    }

    public override void Draw()
    {
        FrameworkData.SpriteBatch.DrawText_MediumFont("Select a palette:", new Vector2(20, 10), 1, 1f, 3f, -1);

        foreach (var palette in Palettes)
        {
            palette.Draw();
        }
    }

    public override void Exit()
    {
    }

    public override void Enter()
    {
    }

    private void Button_Clicked(object sender, EventArgs e)
    {
        GameData.UpdateColorPaletteIndex(((ColorPaletteOption)sender).Index);
    }
}