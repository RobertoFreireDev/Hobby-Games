using System;

namespace GameEngine.Elements;

public class Timer
{
    private float _interval; 
    private float _elapsedTime; 
    private bool _isActive;

    public event Action OnTimerElapsed;

    public Timer(float interval)
    {
        _interval = interval;
        _elapsedTime = 0;
        _isActive = false;
    }

    public void StartIfInactive()
    {
        if (_isActive)
        {
            return;
        }

        _isActive = true;
        _elapsedTime = 0;
    }

    public void Stop()
    {
        _isActive = false;
    }

    public void Reset()
    {
        _elapsedTime = 0;
    }

    public void Update(float elapsedTime)
    {
        if (!_isActive)
            return;

        _elapsedTime += elapsedTime;

        if (_elapsedTime >= _interval)
        {
            _elapsedTime = 0;
            OnTimerElapsed?.Invoke();
        }
    }
}