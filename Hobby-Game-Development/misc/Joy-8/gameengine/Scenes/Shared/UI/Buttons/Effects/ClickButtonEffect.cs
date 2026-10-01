using gameengine.Utils.Objects;

namespace gameengine.Scenes.Shared.UI.Buttons.Effects;

internal class ClickButtonEffect : ButtonEffect
{
    private Blink _blink = new Blink();

    public ClickButtonEffect()
    {

    }

    public override bool? IsSelected(bool isMouseOver, bool isClicked)
    {
        if (isMouseOver && isClicked)
        {
            _blink.Enable();
        }

        _blink.Update();
        return _blink.IsBlinking();
    }
}
