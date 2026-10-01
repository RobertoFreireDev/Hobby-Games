using gameengine.Data;
using gameengine.Input;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace gameengine.Scenes.Shared.UI.Buttons.Slide;

public class SliderBar
{
    private Rectangle _barRect;
    private Rectangle _knobRect;
    private Texture2D _barTexture;
    private Texture2D _knobTexture;
    private bool _isDragging;
    private int _minValue;
    private int _maxValue;
    private int _value;
    private string _text;
    private Vector2 _position;

    public int Value => _value;

    public SliderBar(Vector2 position, int width, int minValue, int maxValue, string text, int offSetX)
    {
        _position = position;
        _barRect = new Rectangle((int)position.X + offSetX, (int)position.Y - 3, width, 8);
        _knobRect = new Rectangle((int)position.X + offSetX, (int)position.Y - 7, 4, 16);
        _barTexture = GameEngineData.PixelTexture;
        _knobTexture = GameEngineData.PixelTexture;
        _minValue = minValue;
        _maxValue = maxValue;
        _value = minValue;
        _text = text;
    }

    public void Update()
    {
        var mousePosition = MouseInput.MousePosition();
        if (_isDragging)
        {
            if (MouseInput.LeftButton_Released())
            {
                _isDragging = false;
            }
            else
            {
                UpdateValue(mousePosition);
            }
        }
        else if (MouseInput.LeftButton_JustPressed())
        {
            if (_knobRect.Contains(mousePosition) || _barRect.Contains(mousePosition))
            {
                _isDragging = true;
                UpdateValue(mousePosition);
            }
        }
    }

    private void UpdateValue(Point mousePosition)
    {
        int newX = MathHelper.Clamp(mousePosition.X, _barRect.X, _barRect.Right - _knobRect.Width);
        _knobRect.X = newX;
        _value = (int)(_minValue + ((_knobRect.X - _barRect.X) / (float)(_barRect.Width - _knobRect.Width)) * (_maxValue - _minValue));
    }

    public void Draw()
    {
        var spriteBatch = FrameworkData.SpriteBatch;
        spriteBatch.CustomDraw(_barTexture, _barRect, 1, 0.4f);
        spriteBatch.CustomDraw(_knobTexture, _knobRect, 3);

        if (!string.IsNullOrWhiteSpace(_text))
        {
            spriteBatch.DrawText_MediumFont(_text + _value.ToString(), new Vector2(_position.X, _position.Y), 1, 0.4f, 2f, -1);
        }
    }
}

