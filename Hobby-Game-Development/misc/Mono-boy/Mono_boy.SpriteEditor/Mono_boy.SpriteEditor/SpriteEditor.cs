using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.Utils;
using System;

namespace Mono_boy.SpriteEditor;

public class SpriteEditor : Game
{
    private SpriteBatch _spriteBatch;

    public SpriteEditor()
    {
        var graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "assets";
        IsMouseVisible = true;
        graphics.IsFullScreen = false;
        Window.AllowUserResizing = true;
        Window.ClientSizeChanged += OnResize;
        Window.AllowAltF4 = true;
        GlobalManager.GraphicsDeviceManager = graphics;
        GlobalManager.Window = Window;
        Resolution.SetResolution(GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width, 680);
        GlobalManager.CurrentScene = SceneEnum.SONG;
    }

    private void OnResize(Object sender, EventArgs e)
    {
        if (sender is not GameWindow)
        {
            return;
        }

        var window = (GameWindow)sender;
        var graphics = GlobalManager.GraphicsDeviceManager;

        if (window.ClientBounds.Width == graphics.PreferredBackBufferWidth && window.ClientBounds.Height == graphics.PreferredBackBufferHeight)
        {
            return;
        }

        Resolution.SetResolution(window.ClientBounds.Width, window.ClientBounds.Height, window.ClientBounds.X, window.ClientBounds.Y);
        GlobalManager.ReloadScences();
    }

    protected override void Initialize()
    {
        base.Initialize();
    }

    protected override void LoadContent()
    {
        var pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        pixelTexture.SetData(new Color[] { Color.White });
        GlobalManager.LoadVariables(pixelTexture, Content.Load<SpriteFont>(@"fonts\default"), GraphicsDevice);
    }

    protected override void Update(GameTime gameTime)
    {
        if (InputStateManager.IsKeyEscapePressed())
            Exit();        

        GlobalManager.Update(gameTime);
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(ColorUtils.GetColor(4));
        var spriteBatch = GlobalManager.SpriteBatch;
        spriteBatch.Begin();
        GlobalManager.Draw();
        spriteBatch.End();
        base.Draw(gameTime);
    }
}
