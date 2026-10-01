using gameengine.Data;
using gameengine.Scenes.Shared.UI;
using gameengine.Utils;
using Microsoft.Xna.Framework;

namespace gameengine.Scenes.Rename;

internal class ConfirmButton : UIComponent
{
    public bool Disable = false;
    private int _primaryColor = 1;
    private int _hoverColor = 2;
    private int _disableColor = 3;
    private float _scale;
    private int _offSet;

    public ConfirmButton(UIComponentEnum component, float scale, int offSet) 
        : base (null, component, 1)
    {
        _scale = scale;
        _offSet = offSet;
    }

    public override void Update()
    {
        if (Disable)
        {
            ColorIndex = _disableColor;
            return;
        }

        if (IsMouseOver())
        {
            ColorIndex = _hoverColor;
            IsClicked();
        }
        else
        {
            ColorIndex = _primaryColor;
        }
    }

    public override void AdditionalDraw()
    {
        var bounds = GameEngineData.UIComponentBounds[_type];
        var spriteBatch = FrameworkData.SpriteBatch;
        spriteBatch.DrawImage("confirmbuttonborder", bounds, ColorIndex);
        spriteBatch.DrawText_MediumFont("Save", new Vector2(bounds.X + 10, bounds.Y + 15), ColorIndex, 1f, _scale, _offSet);
    }
}