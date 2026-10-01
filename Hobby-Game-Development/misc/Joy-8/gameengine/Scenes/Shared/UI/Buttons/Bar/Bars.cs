using gameengine.Data;
using gameengine.Input;
using gameengine.Utils;
using Microsoft.Xna.Framework;
using System;

namespace gameengine.Scenes.Shared.UI.Buttons.Bar;

internal class Bars
{
    public int[] Values = new int[SfxData.Length];
    protected int _startX;
    protected int _startY;
    protected int _rectWidth;
    protected int _margin;
    protected int _scale;
    protected int _maxValue;
    protected int _minValue;
    protected Rectangle _area;
    protected string _title;
    protected string[] _display;

    public Bars(int[] values, int startX, int startY, int rectWidth, int margin, int scale, int minValue, int maxValue, string title, string[] display = null)
    {
        for (int i = 0; i < values.Length; i++)
        {
            Values[i] = Math.Max(minValue, values[i]);
        }
        _startX = startX;
        _startY = startY;
        _rectWidth = rectWidth;
        _margin = margin;
        _scale = scale;
        _minValue = minValue;
        _maxValue = maxValue;
        _title = title;
        _display = display;

        int totalWidth = Values.Length * (_rectWidth + _margin) - _margin;
        int maxHeight = _scale * (_maxValue + 1) + _margin * 2;
        _area = new Rectangle(_startX - _margin, _startY - maxHeight, totalWidth + _margin * 2, maxHeight + _margin);
    }

    public void Update()
    {
        var position = MouseInput.MousePosition();

        if (MouseInput.RightButton_JustPressed())
        {
            int index = (position.X - _startX) / (_rectWidth + _margin);
            if (index >= 0 && index < Values.Length)
            {
                int? temp = null;
                if (position.Y >= _startY - _scale * (_maxValue + 1) && position.Y <= _startY)
                {
                    int newValue = (_startY - position.Y) / _scale;
                    temp = Math.Clamp(newValue, _minValue, _maxValue);
                }

                if (temp.HasValue)
                {
                    for (int i = 0; i < Values.Length; i++)
                    {
                        if (i > index)
                        {
                            break;
                        }
                        Values[i] = temp.Value;
                    }

                    return;
                }
            }
        }

        if (MouseInput.LeftButton_Pressed())
        {
            int index = (position.X - _startX) / (_rectWidth + _margin);
            if (index >= 0 && index < Values.Length)
            {
                if (position.Y >= _startY - _scale * (_maxValue + 1) && position.Y <= _startY)
                {
                    int newValue = (_startY - position.Y) / _scale;
                    Values[index] = Math.Clamp(newValue, _minValue, _maxValue);
                }
            }
            return;
        }
    }

    public void Draw()
    {
        var spriteBatch = FrameworkData.SpriteBatch;

        spriteBatch.CustomDraw(GameEngineData.PixelTexture, new Rectangle(_area.X, _area.Y, _area.Width, 2), 1, 0.2f);
        spriteBatch.CustomDraw(GameEngineData.PixelTexture, _area, 1, 0.6f);
        spriteBatch.DrawText_MediumFont(_title, new Vector2(_startX - 10, _startY), 1, 0.4f, 2f, -1, -MathHelper.PiOver2);

        for (int i = 0; i < Values.Length; i++)
        {
            int rectHeight = Values[i] * _scale;
            int x = _startX + i * (_rectWidth + _margin);
            int y = _startY - rectHeight;
            int color = Values[i] - _minValue + 2;
            spriteBatch.CustomDraw(GameEngineData.PixelTexture, new Rectangle(x, y, _rectWidth, rectHeight), color);
            spriteBatch.CustomDraw(GameEngineData.PixelTexture, new Rectangle(x, y, _rectWidth, 1), color + 1);

            if (_display != null)
            {
                spriteBatch.DrawText_MediumFont(_display[Values[i] - _minValue], new Vector2(x + 5, _area.Y + 5), 2, 0.8f, 1f, -1);
            }
        }
    }
}