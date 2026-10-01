using GameEngine.Elements.Managers;
using GameEngine.Enums;
using GameEngine.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GameEngine.GameObjects.Managers;

public class MenuManager : ISceneManager
{
    public void LoadContent()
    {
    }

    public void Update()
    {
        if (InputUtils.IsKeyJustPressed(InputEnum.ENTER))
        {
            GlobalManager.Scene = SceneEnum.GAME;
        }
    }

    public void Draw()
    {
        var batch = SpriteManager.SpriteBatch;
        batch.Begin(samplerState: SamplerState.PointClamp);
        batch.DrawString(SpriteManager.Font, "MENU", new Vector2(300, 200), Color.Yellow);
        batch.DrawString(SpriteManager.Font, "PRESS ENTER TO START GAME", new Vector2(300, 250), Color.Yellow);
        batch.End();
    }
}
