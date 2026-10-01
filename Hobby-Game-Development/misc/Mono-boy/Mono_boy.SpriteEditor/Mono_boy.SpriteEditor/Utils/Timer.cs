using Mono_boy.SpriteEditor.Manager;

namespace Mono_boy.SpriteEditor.Utils;

internal class Timer
{
    private bool _isActive;
    private float _duration;
    private float _time;

    public Timer(float duration = 1f)
    {
        _time = 0f;
        _duration = duration;
    }

    public void Enable()
    {
        _isActive = true;
        _time = 0f;
    }

    public void Update()
    {
        if (!_isActive)
        {
            return;
        }

        _time += GlobalManager.DeltaTime;

        if (_time >= _duration)
        {
            _isActive = false;
            _time = 0f;
        }
    }

    public bool isActive()
    {
        return _isActive;
    }
}
