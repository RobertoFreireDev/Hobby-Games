using Buttons;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MONO_32.Core;
using MONO_32.Engine.Input;
using MONO_32.SpriteGUIEditor.Enums;
using MONO_32.SpriteGUIEditor.Grid;
using System.IO;

namespace MONO_32.SpriteGUIEditor;

public class SpriteGUIEditor : Game
{
    GraphicsDeviceManager graphics;
    SpriteBatch spriteBatch;
    SpriteGrids spriteGrids;
    Palette palette;
    Buttons.Buttons buttons;

    public SpriteGUIEditor()
    {
        graphics = new GraphicsDeviceManager(this);
        IsMouseVisible = true;
    }

    protected override void Initialize()
    {
        Content.RootDirectory = @"assets";

        graphics.PreferredBackBufferWidth = 1200;
        graphics.PreferredBackBufferHeight = 680;
        graphics.IsFullScreen = false;
        graphics.ApplyChanges();
        palette = new Palette(ColorPaletteEnum.TwilioQuest76, 8, 16);
        base.Initialize();
    }

    protected override void LoadContent()
    {
        spriteBatch = new SpriteBatch(GraphicsDevice);
        UIVariables.DefaultFont = Content.Load<SpriteFont>(@"fonts\default");
        UIVariables.Textures = FileUtils.GetAllImages(GraphicsDevice, Directory.GetFiles("assets\\imgs\\", "*.png", SearchOption.AllDirectories));

        // start with pencil
        var paintModeSelected = PaintModeEnum.Pencil;
        var buttonSelected = ButtonTypeEnum.Pencil;

        var pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        pixelTexture.SetData(new Color[] { Color.White });

        UIVariables.LoadVariables(
            pixelTexture,
            paintModeSelected,
            palette.ColorPalette[0], 
            32, 
            32);

        palette.CreatePalleteRectangles();
        buttons = new Buttons.Buttons(buttonSelected);
        spriteGrids = new SpriteGrids();
    }

    protected override void Update(GameTime gameTime)
    {
        InputUtils.Update();
        if (InputUtils.IsMouseLeftButtonPressed())
        {
            ProcessMouseClicked(InputUtils.MousePosition());
        }
        if (InputUtils.IsMouseLeftButtonReleased())
        {
            spriteGrids.UpdateMouseLeftReleased(InputUtils.MousePosition());
        }
        spriteGrids.Update();
        buttons.TextInputField.Update(gameTime);
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);
        buttons.Draw(spriteBatch);
        spriteGrids.Draw(spriteBatch);
        palette.Draw(spriteBatch);
        buttons.TextInputField.Draw(spriteBatch);
        base.Draw(gameTime);
    }

    private void ProcessMouseClicked(Point mousePosition)
    {
        buttons.TextInputField.UpdateMouseLeftClicked(mousePosition);
        spriteGrids.UpdateMouseLeftClicked(mousePosition);
        UIVariables.SelectedColor = palette.UpdateSelectedColor(mousePosition) ?? UIVariables.SelectedColor;
        buttons.Update(mousePosition, spriteGrids.currentSpriteGrid, GraphicsDevice);
    }
}