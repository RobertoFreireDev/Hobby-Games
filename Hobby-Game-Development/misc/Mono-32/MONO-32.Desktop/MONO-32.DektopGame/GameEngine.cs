using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MONO_32.Core;
using System.IO;

namespace MONO_32.DektopGame
{
    public class GameEngine : Game
    {
        private GraphicsDeviceManager _graphics;
        private SpriteBatch _spriteBatch;
        private Texture2D _texture2D;

        public GameEngine()
        {
            _graphics = new GraphicsDeviceManager(this);
            IsMouseVisible = true;
        }

        protected override void Initialize()
        {
            // TODO: Add your initialization logic here

            base.Initialize();
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            var textures = FileUtils.GetAllImages(GraphicsDevice, Directory.GetFiles("assets\\imgs\\", "*.png", SearchOption.AllDirectories));
            _texture2D = textures["wall"];
        }

        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            // TODO: Add your update logic here

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            _spriteBatch.Begin();
            _spriteBatch.Draw(_texture2D, new Vector2(100, 100), Color.White);
            _spriteBatch.End();

            base.Draw(gameTime);
        }
    }
}
