using Mono_boy.SpriteEditor.Manager;

namespace Mono_boy.SpriteEditor.UIComponents.Base;

internal class Blink
{
    private bool _isBlinking;
    private float _blinkTimer;
    private const float BlinkDuration = 0.3f;

    public bool IsBlinking()
    {
        return _isBlinking;
    }

    public void Update()
    {
        _blinkTimer += GlobalManager.DeltaTime;

        if (_blinkTimer >= BlinkDuration)
        {
            _isBlinking = false;
            _blinkTimer = 0f;
        }
    }
    public void Enable()
    {
        _isBlinking = true;
        _blinkTimer = 0f;
    }
}
