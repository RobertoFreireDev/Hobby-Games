using GameEngine.Elements.Sprites;
using Microsoft.Xna.Framework;
using System.Collections.Generic;
using GameEngine.Enums;
using GameEngine.Elements;
using GameEngine.Elements.Strategies;

namespace GameEngine.GameObjects.Elements;

public class Enemy : SpriteObject
{
    private IMovementStrategy _movementStrategy;

    public Enemy(int x, int y) : base(x, y)
    {
        Speed = 1;
        var animations = new Dictionary<AnimationEnum, Animation>
            {
                {
                    AnimationEnum.IDLE,
                    new Animation()
                    {
                        Frames = new int[] { 6 },
                        FrameDuration = 0.3f,
                        Loop = false
                    }
                }
            };

        AnimatedSprite = new AnimatedSprite(
                    Color.White
                    , animations
                    , AnimationEnum.IDLE
                    , new GameEngine.Elements.Texture("world",40, 26, 13, 40, 40)
                );
        AnimatedSprite.Ordering.Z = 2;
        CollisionBox = new CollisionBox(6, 17, 28, 18);
        _movementStrategy = new SimpleMovementStrategy(this, 40f, 160f);
    }

    public void Update(Player player, List<Enemy> enemies)
    {
        _movementStrategy.Update(player, enemies.ConvertAll(e => (SpriteObject)e), AttackPlayer);
        
        void AttackPlayer()
        {
            player.ReceivesDamage();
        }
    }

    public override void Draw(Color? color = null)
    {
        base.Draw();
    }
}
