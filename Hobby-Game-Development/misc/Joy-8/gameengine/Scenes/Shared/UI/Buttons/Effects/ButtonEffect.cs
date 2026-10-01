namespace gameengine.Scenes.Shared.UI.Buttons.Effects;

internal abstract class ButtonEffect
{
    public abstract bool? IsSelected(bool isMouseOver, bool isClicked);
}
