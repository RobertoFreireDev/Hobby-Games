using gameengine.Data;

namespace gameengine.Utils.Objects;

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

        _time += FrameworkData.DeltaTime;

        if (_time >= _duration)
        {
            _isActive = false;
            _time = 0f;
        }
    }

    public bool IsActive()
    {
        return _isActive;
    }
}