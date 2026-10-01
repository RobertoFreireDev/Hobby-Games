using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework;
using System.Text;
using gameengine.Utils;
using gameengine.Data;
using gameengine.Input;
using gameengine.Scenes.Shared.UI;

namespace gameengine.Scenes.Rename;

internal class SingleLineTextField : UIComponent
{
    private StringBuilder _text;
    private int _cursorPosition;
    private double _blinkTime;
    private const double CursorBlinkRate = 0.5;
    private int _maxTextLength = 15;
    private int _textColor;
    private int _cursorColor;
    private float _scale;
    private int _offSet;

    public SingleLineTextField(UIComponentEnum componentOption, int maxTextLength, float scale, int offSet)
        : base(null, componentOption, 1)
    {
        _text = new StringBuilder();
        _maxTextLength = maxTextLength;
        _scale = scale;
        _offSet = offSet;
        _cursorPosition = 0;
        _textColor = 1;
        _cursorColor = 2;
    }

    public void UpdateTextValue(string text)
    {
        _text = new StringBuilder(text);
    }

    public string GetTextValue()
    {
        return _text.ToString();
    }

    public override void Update()
    {
        var key = KeyboardInput.GetAlphaNumericTextFieldJustPressedKeys();

        if (key == Keys.Back && _cursorPosition > 0)
        {
            _text.Remove(_cursorPosition - 1, 1);
            _cursorPosition--;
        }
        else if (key == Keys.Delete && _cursorPosition < _text.Length)
        {
            _text.Remove(_cursorPosition, 1);
        }
        else if (key == Keys.Left && _cursorPosition > 0)
        {
            _cursorPosition--;
        }
        else if (key == Keys.Right && _cursorPosition < _text.Length)
        {
            _cursorPosition++;
        }
        else if (key >= Keys.A && key <= Keys.Z || key >= Keys.D0 && key <= Keys.D9 || key == Keys.Space)
        {
            if (_text.Length < _maxTextLength)
            {
                char typedChar = (char)key;
                _text.Insert(_cursorPosition, typedChar);
                _cursorPosition++;
            }
        }

        _blinkTime += FrameworkData.DeltaTime;
        if (_blinkTime >= CursorBlinkRate * 2)
            _blinkTime = 0;
    }

    public override void AdditionalDraw()
    {
        var bounds = GameEngineData.UIComponentBounds[_type];
        var spriteBatch = FrameworkData.SpriteBatch;

        spriteBatch.DrawImage("renametextfieldborder", bounds, 1);
        spriteBatch.DrawText_MediumFont(_text.ToString(), new Vector2(bounds.X + 10, bounds.Y + 15), _textColor, 1f, _scale, _offSet);

        if (_blinkTime % (CursorBlinkRate * 2) < CursorBlinkRate)
        {
            float cursorX = bounds.X + _cursorPosition * (FontAtlasUtils.MediumFont.CharWidth + _offSet) * _scale;
            float cursorY = bounds.Y + 15;
            spriteBatch.DrawText_MediumFont("Ꮖ", new Vector2((int)cursorX, (int)cursorY), _cursorColor, 1f, _scale, _offSet);
        }
    }
}