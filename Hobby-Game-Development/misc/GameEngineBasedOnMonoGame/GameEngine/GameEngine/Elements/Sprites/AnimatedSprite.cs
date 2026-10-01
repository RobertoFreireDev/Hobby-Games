using GameEngine.Elements.Managers;
using GameEngine.Enums;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;

namespace GameEngine.Elements.Sprites;

public class AnimatedSprite
{
    public Dictionary<AnimationEnum, Animation> Animations = new Dictionary<AnimationEnum, Animation>();

    public Texture Texture { get; set; }

    public SpriteEffects FlipHorizontally; 

    public AnimationEnum State {  get; private set; }

    public void SetState(AnimationEnum state)
    {
        if (State == state)
        {
            return;
        }

        State = state;
        _currentFrameIndex = 0;
    }

    public Color Color;

    public Visibility Visibility  = new Visibility();

    public Order Ordering = new Order();


    private int _currentFrameIndex;

    public float _elapsedTime;

    public AnimatedSprite(
        Color color,
        Dictionary<AnimationEnum, Animation> animations,
        AnimationEnum state,
        Texture texture)
    {
        Color = color;
        Animations = animations;
        State = state;
        _elapsedTime = 0f;
        Texture = texture;
    }

    public void Update()
    {
        var animation = Animations.GetValueOrDefault(State);

        if (animation is null) return;

        _elapsedTime += GlobalManager.DeltaTime;

        if (_elapsedTime >= animation.FrameDuration)
        {
            _elapsedTime -= animation.FrameDuration;
            _currentFrameIndex++;

            if (_currentFrameIndex >= animation.Frames.Length)
            {
                if (animation.Loop)
                {
                    _currentFrameIndex = 0;
                }
                else
                {
                    _currentFrameIndex = animation.Frames.Length - 1;
                }
            }
        }
    }

    public Rectangle GetSourceRectangle()
    {
        var animation = Animations.GetValueOrDefault(State);
        var spriteNumber = animation.Frames[_currentFrameIndex];
        return Texture.GetRectangle(spriteNumber);
    }
}