using gameengine.Data;
using gameengine.Utils;
using gameengine.Scenes;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using gameengine.Input;

namespace gameengine;

public class GE : Game
{
    private SceneManager _sceneManager;

    public GE()
    {
        var graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Assets";
        graphics.IsFullScreen = false;
        Window.AllowUserResizing = true;
        Window.ClientSizeChanged += OnResize;
        IsMouseVisible = true;
        FrameworkData.GraphicsDeviceManager = graphics;
        FrameworkData.Window = Window;
    }

    private void OnResize(Object sender, EventArgs e)
    {
        if (sender is not GameWindow)
        {
            return;
        }

        var window = (GameWindow)sender;
        var graphics = FrameworkData.GraphicsDeviceManager;

        if (window.ClientBounds.Width == graphics.PreferredBackBufferWidth && window.ClientBounds.Height == graphics.PreferredBackBufferHeight)
        {
            return;
        }

        ResolutionUtils.SetResolution(window.ClientBounds.Width, window.ClientBounds.Height, window.ClientBounds.X, window.ClientBounds.Y);
        _sceneManager.ReloadUIOnly();
    }

    protected override void Initialize()
    {
        base.Initialize();
    }

    protected override void LoadContent()
    {
        FrameworkData.GraphicsDevice = GraphicsDevice;
        ResolutionUtils.SetResolution(GameEngineData.BaseBox.Width, GameEngineData.BaseBox.Height);
        FrameworkData.SpriteBatch = new SpriteBatch(GraphicsDevice);
        GameEngineData.Images = ImageFileUtils.GetAllImages();
        GameEngineData.MediumKeyBoardKeys = FontAtlasUtils.GetCharMediumFont();
        GameEngineData.LargeKeyBoardKeys = FontAtlasUtils.GetCharLargeFont();

        var pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        pixelTexture.SetData(new Color[] { Color.White });
        GameEngineData.PixelTexture = pixelTexture;
        _sceneManager = new SceneManager();
        GameData.NewGame();
    }

    protected override void Update(GameTime gameTime)
    {
        if (KeyboardInput.IsAltF4Pressed())
            Exit();

        if (KeyboardInput.IsF2Released())
            ResolutionUtils.ToggleFullScreen();

        GameEngineData.UpdateIsFocused(IsActive, FrameworkData.GraphicsDeviceManager.IsFullScreen);
        FrameworkData.DeltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
        InputStateManager.Update();

        try
        {
            _sceneManager.Update();
        }
        catch (Exception ex)
        {
            // TO DO: create log file with stack trace
            Exit();
        }
        
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);
        var spriteBatch = FrameworkData.SpriteBatch;
        spriteBatch.Begin(samplerState: SamplerState.PointClamp);
        spriteBatch.Draw(GameEngineData.PixelTexture, GameEngineData.BoxToDraw, ColorUtils.GetColor(4));
        _sceneManager.Draw();
        spriteBatch.End();
        base.Draw(gameTime);
    }
}