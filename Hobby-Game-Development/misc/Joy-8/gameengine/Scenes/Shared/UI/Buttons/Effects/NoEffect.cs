namespace gameengine.Scenes.Shared.UI.Buttons.Effects;

internal class NoEffect : ButtonEffect
{
    public NoEffect()
    {

    }

    public override bool? IsSelected(bool isMouseOver, bool isClicked)
    {
        return null;
    }
}