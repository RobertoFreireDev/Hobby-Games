using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Extensions;
using Mono_boy.SpriteEditor.Input;
using Mono_boy.SpriteEditor.Manager;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.Utils;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.UIComponents.ConfigEditor;

internal class Dropdown : UIComponent
{
    private List<int> _options;
    private int _selectedIndex;
    private bool _isOpen;

    public Dropdown(
        Rectangle bounds,
        List<int> options, 
        int selectedIndex) : base(GlobalManager.PixelTexture, bounds, 4)
    {
        _options = options;
        _selectedIndex = selectedIndex;
        _isOpen = false;
    }

    public int GetSelectedIndex()
    {
        return _selectedIndex;
    }

    public override void Update()
    {
        
        if (Bounds.Contains(InputStateManager.MousePosition()) && InputStateManager.IsMouseLeftButtonJustPressed())
        {
            _isOpen = !_isOpen;
        }

        if (_isOpen)
        {
            for (int i = 0; i < _options.Count; i++)
            {
                Rectangle optionBounds = new Rectangle(Bounds.X, Bounds.Y + (i + 1) * Bounds.Height, Bounds.Width, Bounds.Height);
                if (optionBounds.Contains(InputStateManager.MousePosition()) && InputStateManager.IsMouseLeftButtonJustPressed())
                {
                    _selectedIndex = i;
                    _isOpen = false;
                    InvokeClick();
                }
            }
        }
    }

    public override void Draw()
    {
        var spriteBatch = GlobalManager.SpriteBatch;
        var font = GlobalManager.DefaultFont;
        var texture = GlobalManager.PixelTexture;
        var backgroundColor = ColorUtils.GetColor(4);
        var box = new Rectangle(Bounds.X, Bounds.Y + 4, Bounds.Width, Bounds.Height - 5);
        spriteBatch.CustomDraw(texture, box, backgroundColor);
        spriteBatch.DrawBorder(box, 1, 1, Point.Zero);
        DrawPalette(_selectedIndex, new Vector2(Bounds.X + 5, Bounds.Y + 5));
        if (_isOpen)
        {
            for (int i = 0; i < _options.Count; i++)
            {
                Rectangle optionBounds = new Rectangle(Bounds.X, Bounds.Y + (i + 1) * Bounds.Height, Bounds.Width, Bounds.Height);
                spriteBatch.CustomDraw(texture, optionBounds, backgroundColor);
                DrawPalette(i, new Vector2(optionBounds.X + 5, optionBounds.Y + 5));
            }
            spriteBatch.DrawBorder(new Rectangle(Bounds.X, Bounds.Y + Bounds.Height, Bounds.Width, _options.Count * Bounds.Height), 1, 1, Point.Zero);
        }

        void DrawPalette(int paletteIndex, Vector2 vector)
        {
            var (color1, color2, color3, color4,
                color5, color6, color7, color8,
                color9, color10, color11, color12,
                color13, color14, color15, color16) = ColorUtils.GetPalette(paletteIndex);
            var size = 15;
            var ofx = 2;
            var ofy = 2;

            var rect1 = new Rectangle((int)vector.X + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect1, color1);

            var rect2 = new Rectangle(rect1.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect2, color2);

            var rect3 = new Rectangle(rect2.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect3, color3);

            var rect4 = new Rectangle(rect3.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect4, color4);

            var rect5 = new Rectangle(rect4.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect5, color5);

            var rect6 = new Rectangle(rect5.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect6, color6);

            var rect7 = new Rectangle(rect6.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect7, color7);

            var rect8 = new Rectangle(rect7.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect8, color8);

            var rect9 = new Rectangle(rect8.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect9, color9);

            var rect10 = new Rectangle(rect9.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect10, color10);

            var rect11 = new Rectangle(rect10.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect11, color11);

            var rect12 = new Rectangle(rect11.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect12, color12);

            var rect13 = new Rectangle(rect12.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect13, color13);

            var rect14 = new Rectangle(rect13.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect14, color14);

            var rect15 = new Rectangle(rect14.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect15, color15);

            var rect16 = new Rectangle(rect15.Right + ofx, (int)vector.Y + ofy, size, size);
            spriteBatch.CustomDraw(GlobalManager.PixelTexture, rect16, color16);
        }
    }
}