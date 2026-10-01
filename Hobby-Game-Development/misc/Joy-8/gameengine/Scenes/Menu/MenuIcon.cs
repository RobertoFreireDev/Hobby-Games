using gameengine.Data;
using gameengine.Scenes.Shared.UI;
using gameengine.Utils;
using Microsoft.Xna.Framework.Graphics;

namespace gameengine.Scenes.Menu;

internal class MenuIcon : UIComponent
{
    public MenuOptionEnum Option { get; }
    private int _primaryColor = 1;
    private int _hoverColor = 2;
    private bool _enableBorder = false;

    public MenuIcon(MenuOptionEnum menuOption, UIComponentEnum component, Texture2D texture) : base(texture, component, 1)
    {
        Option = menuOption;
    }

    public override void Update()
    {
        if (IsMouseOver())
        {
            _enableBorder = true;
            ColorIndex = _hoverColor;
            IsClicked();
        }
        else
        {
            _enableBorder = false;
            ColorIndex = _primaryColor;
        }
    }

    public override void AdditionalDraw()
    {
        if (!_enableBorder)
        {
            return;
        }

        FrameworkData.SpriteBatch.DrawButtonBorder(_type, ColorIndex);
    }
}