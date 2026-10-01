using gameengine.Input;
using gameengine.Utils;
using System;
using System.Linq;

namespace gameengine.Scenes.Shared.UI.Buttons.Bar;

internal class PitchBar : Bars
{
    public PitchBar(int[] values, int startX, int startY, int rectWidth, int margin, int scale, int minValue, int maxValue, string title, string[] display = null)
        : base(values, startX, startY, rectWidth, margin, scale, minValue, maxValue, title, display)
    {
    }

    public void Update()
    {
        if (string.IsNullOrWhiteSpace(SfxScene.pent))
        {
            base.Update();
            return;
        }

        string[] filter = Pentatonic.ScaleValues[SfxScene.pent];
        var filterList = filter.Select(i => Pitches.GetNote(i) + 1).ToList();
        filterList.Add(0);
        int[] filterInt = filterList.ToArray();

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
                    int clampedValue = Math.Clamp(newValue, _minValue, _maxValue);

                    // Find the closest value in filterInt
                    temp = filterInt.OrderBy(v => Math.Abs(v - clampedValue)).FirstOrDefault();
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
                    int clampedValue = Math.Clamp(newValue, _minValue, _maxValue);

                    // Find the closest value in filterInt
                    Values[index] = filterInt.OrderBy(v => Math.Abs(v - clampedValue)).FirstOrDefault();
                }
            }
            return;
        }
    }

    public void Draw()
    {
        base.Draw();
    }
}
