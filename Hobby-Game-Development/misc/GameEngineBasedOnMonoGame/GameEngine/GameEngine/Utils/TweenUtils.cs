using GameEngine.Elements.Managers;
using Microsoft.Xna.Framework;
using System;

namespace GameEngine.Utils;

public class TweenUtils
{
    private float _startValue;
    private float _endValue;
    private float _duration;
    private float _elapsedTime;
    private Func<float, float> _easingFunction;
    public bool Active = true;

    public TweenUtils(float startValue, float endValue, float duration, Func<float, float> easingFunction)
    {
        _startValue = startValue;
        _endValue = endValue;
        _duration = duration;
        _easingFunction = easingFunction;
        _elapsedTime = 0f;
    }

    public float Update()
    {
        _elapsedTime += GlobalManager.DeltaTime;
        float t = MathHelper.Clamp(_elapsedTime / _duration, 0f, 1f);
        float easedT = _easingFunction(t);
        return MathHelper.Lerp(_startValue, _endValue, easedT);
    }

    public bool IsComplete()
    {
        if (_elapsedTime >= _duration)
        {
            Active = false;
        }
        
        return !Active;
    }

    public void Reset()
    {
        Active = true;
        _elapsedTime = 0;
    }
}

public static class EasingFunctions
{
    public static float Linear(float t)
    {
        return t;
    }

    public static float EaseInQuad(float t)
    {
        return t * t;
    }

    public static float EaseOutQuad(float t)
    {
        return t * (2 - t);
    }
}
