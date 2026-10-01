using gameengine.Data;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Menu;

internal class AnimationMenuIcon : MenuIcon
{
    public AnimationMenuIcon() : base(MenuOptionEnum.Animation, UIComponentEnum.AnimationMenu, GameEngineData.Images["animation_button"])
    {
    }
}