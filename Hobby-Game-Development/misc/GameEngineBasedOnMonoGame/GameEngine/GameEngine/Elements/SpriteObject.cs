using GameEngine.Elements.Managers;
using GameEngine.Elements.Sprites;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GameEngine.Elements;

public abstract class SpriteObject
{
    public Vector2 Position;

    public int Speed;

    public AnimatedSprite AnimatedSprite;

    public CollisionBox CollisionBox;

    public SpriteObject(int x, int y)
    {
        Position = new Vector2(x, y);
    }

    public virtual void Draw(Color? newColor = null)
    {
        if (!AnimatedSprite.Visibility.Visible)
        {
            return;
        }

        var batch = SpriteManager.SpriteBatch;
        batch.Begin(samplerState: SamplerState.PointClamp);

        var color = newColor ?? AnimatedSprite.Color;
        var offset = Camera.Position;        
        AnimatedSprite.Update();
        var position = new Vector2(
            Position.X + (int)offset.X,
            Position.Y + (int)offset.Y
        );

        batch.Draw(
            TextureManager.Texture2D[AnimatedSprite.Texture.TextureKey],
            position,
            AnimatedSprite.GetSourceRectangle(),
            color,
            0,
            new Vector2(1, 1),
            new Vector2(1, 1),
            AnimatedSprite.FlipHorizontally,
            0f
        );

        batch.End();
    }

    public virtual Rectangle GetBox()
    {
        return new Rectangle((int)Position.X + CollisionBox.X, (int)Position.Y + CollisionBox.Y, CollisionBox.Width, CollisionBox.Height);
    }
}
