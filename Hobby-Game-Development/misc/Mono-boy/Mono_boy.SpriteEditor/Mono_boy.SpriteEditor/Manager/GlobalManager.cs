using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Input;
using System.Collections.Generic;
using Mono_boy.SpriteEditor.Utils;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.UIComponents.NavBar;

namespace Mono_boy.SpriteEditor.Manager;

public static class GlobalManager
{
    public static GraphicsDeviceManager GraphicsDeviceManager;

    public static GameWindow Window;

    public static GraphicsDevice GraphicsDevice;

    public static Texture2D PixelTexture;

    public static SpriteFont DefaultFont;

    public static Dictionary<string, Texture2D> Textures;

    public static SpriteBatch SpriteBatch;

    internal static float DeltaTime;

    internal static Dictionary<SceneEnum, ISceneManager> Scenes;

    internal static SceneEnum SceneLastFrame;

    internal static SceneEnum CurrentScene;

    internal static Modal Modal;

    internal static NavigationBar NavBar;

    public static void LoadVariables(Texture2D pixelTexture, SpriteFont defaultFont, GraphicsDevice graphicsDevice)
    {
        DefaultFont = defaultFont;
        Modal = new Modal();
        GraphicsDevice = graphicsDevice;
        PixelTexture = pixelTexture;
        SpriteBatch = new SpriteBatch(graphicsDevice);
        Textures = FileUtils.GetAllImages(graphicsDevice);
        Games.LoadGames();
        ReloadScences();
    }

    public static void ReloadScences()
    {
        ColorUtils.SetPalette(Games.GetCurrentGame().PaletteIndex);
        Scenes = new Dictionary<SceneEnum, ISceneManager>();
        Scenes.Add(SceneEnum.SPRITE, new SpriteEditorManager());
        Scenes.Add(SceneEnum.MAP, new MapEditorManager());
        Scenes.Add(SceneEnum.SFX, new SfxEditorManager());
        Scenes.Add(SceneEnum.SONG, new SongEditorManager());
        Scenes.Add(SceneEnum.CONFIG, new ConfigEditorManager());
        Scenes.Add(SceneEnum.PLAYGAME, new PlayGameManager());
        Scenes.Add(SceneEnum.LOADGAME, new LoadGamesManager());

        foreach (var scene in Scenes)
        {
            scene.Value.LoadContent();
        }

        NavBar = new NavigationBar(new Rectangle(4, 4, GraphicsDevice.Viewport.Width - 8, 60 - 8));
    }

    public static void Update(GameTime gameTime)
    {
        DeltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
        InputStateManager.Update();
        if (InputStateManager.IsF11Released())
        {
            Resolution.ToggleFullScreen();
            ReloadScences();
        }
        if (InputStateManager.IsF10Released())
        {
            NavBar.Toogle();
        }
        if (SceneLastFrame != CurrentScene)
        {
            Scenes[CurrentScene].Reload();
        }
        Scenes[CurrentScene].Update();
        SceneLastFrame = CurrentScene;
        Modal.Update();
        NavBar.Update();
    }

    public static void Draw()
    {
        Scenes[CurrentScene].Draw();
        Modal.Draw();
        NavBar.Draw();
    }
}