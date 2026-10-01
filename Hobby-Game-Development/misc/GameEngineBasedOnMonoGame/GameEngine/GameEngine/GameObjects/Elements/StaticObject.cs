using GameEngine.Elements;
using GameEngine.Elements.Sprites;
using GameEngine.Enums;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace GameEngine.GameObjects.Elements;

public class StaticObject : SpriteObject
{
    public StaticObject(int x, int y) : base(x, y)
    {
        var animations = new Dictionary<AnimationEnum, Animation>
            {
                {
                    AnimationEnum.IDLE,
                    new Animation()
                    {
                        Frames = new int[] { 17 },
                        FrameDuration = 0.3f,
                        Loop = false
                    }
                }
            };

        AnimatedSprite = new AnimatedSprite(
                    Color.White
                    , animations
                    , AnimationEnum.IDLE
                    , new GameEngine.Elements.Texture("world", 40, 26, 13, 40, 40)
                );
        AnimatedSprite.Ordering.Z = 0;
        AnimatedSprite.Ordering.IsSortable = false;
        CollisionBox = new CollisionBox(6, 17, 28, 18);
    }
}
