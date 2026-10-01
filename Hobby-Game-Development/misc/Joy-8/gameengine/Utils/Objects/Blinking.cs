using gameengine.Data;

namespace gameengine.Utils.Objects;

internal class Blinking
{
    private bool _isBlinking;
    private float _blinkTimer;
    private readonly float _blinkInterval;

    public Blinking(float blinkInterval = 0.03f)
    {
        _blinkInterval = blinkInterval;
        _isBlinking = false;
        _blinkTimer = 0f;
    }

    public bool IsBlinking()
    {
        return _isBlinking;
    }

    public void Update()
    {
        _blinkTimer += FrameworkData.DeltaTime;
        if (_blinkTimer >= _blinkInterval)
        {
            _isBlinking = !_isBlinking;
            _blinkTimer = 0f;
        }
    }
}