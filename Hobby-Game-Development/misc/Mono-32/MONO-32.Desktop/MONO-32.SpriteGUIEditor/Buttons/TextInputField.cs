using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MONO_32.Engine.Input;
using MONO_32.SpriteGUIEditor;

namespace Buttons;

public class TextInputField
{
    private SpriteFont _font;
    private Rectangle _fieldRectangle;
    private Color _borderColor = Color.Black;
    private Color _textColor = Color.White;
    private Color _backgroundColor = Color.Gray;
    private float _blinkTimer = 0.0f;
    private bool _showCursor = true;
    private float _cursorBlinkRate = 0.5f; // Cursor blink rate in seconds
    private int LimitTextLength = 10;
    private bool _active = false;

    public TextInputField(SpriteFont font, Rectangle fieldRectangle)
    {
        _font = font;
        _fieldRectangle = fieldRectangle;
    }

    public void UpdateMouseLeftClicked(Point mousePosition)
    {
        _active = _fieldRectangle.Contains(mousePosition);
    }

    public void Update(GameTime gameTime)
    {
        if (!_active)
        {
            return;
        }

        var elapsedTime = (float)gameTime.ElapsedGameTime.TotalSeconds;

        // Handle cursor blinking
        _blinkTimer += elapsedTime;
        if (_blinkTimer > _cursorBlinkRate)
        {
            _showCursor = !_showCursor;
            _blinkTimer = 0.0f;
        }

        var keys = InputUtils.GetReleasedKeys();

        // Handle text input
        foreach (var key in keys)
        {
            if (key == Keys.Back)
            {
                // If the string is not empty, remove the last character
                if (UIVariables.TextFileName.Length > 0)
                {
                    UIVariables.TextFileName = UIVariables.TextFileName.Remove(UIVariables.TextFileName.Length - 1);
                }
            }
            else
            {
                char keyChar = GetCharacterFromKey(key);
                if (keyChar != '\0' && UIVariables.TextFileName.Length < LimitTextLength)
                {
                    UIVariables.TextFileName += keyChar;
                }
            }
        }
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        spriteBatch.Begin();
        // Draw background
        spriteBatch.Draw(UIVariables.PixelTexture, _fieldRectangle, _backgroundColor);

        // Draw border
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(_fieldRectangle.X, _fieldRectangle.Y, _fieldRectangle.Width, 1), _borderColor); // Top
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(_fieldRectangle.X, _fieldRectangle.Y, 1, _fieldRectangle.Height), _borderColor); // Left
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(_fieldRectangle.X, _fieldRectangle.Bottom - 1, _fieldRectangle.Width, 1), _borderColor); // Bottom
        spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle(_fieldRectangle.Right - 1, _fieldRectangle.Y, 1, _fieldRectangle.Height), _borderColor); // Right

        // Draw text
        spriteBatch.DrawString(_font, UIVariables.TextFileName, new Vector2(_fieldRectangle.X + 5, _fieldRectangle.Y + 2), _textColor);

        // Draw cursor
        if (_showCursor && _active)
        {
            Vector2 cursorPosition = new Vector2(_fieldRectangle.X + 5 + _font.MeasureString(UIVariables.TextFileName).X, _fieldRectangle.Y + 2);
            spriteBatch.Draw(UIVariables.PixelTexture, new Rectangle((int)cursorPosition.X, (int)cursorPosition.Y, 2, (int)_font.MeasureString("W").Y), _textColor);
        }
        spriteBatch.End();
    }

    private char GetCharacterFromKey(Keys key)
    {
        // Map keys to lowercase alphanumeric characters
        switch (key)
        {
            case Keys.A: return 'a';
            case Keys.B: return 'b';
            case Keys.C: return 'c';
            case Keys.D: return 'd';
            case Keys.E: return 'e';
            case Keys.F: return 'f';
            case Keys.G: return 'g';
            case Keys.H: return 'h';
            case Keys.I: return 'i';
            case Keys.J: return 'j';
            case Keys.K: return 'k';
            case Keys.L: return 'l';
            case Keys.M: return 'm';
            case Keys.N: return 'n';
            case Keys.O: return 'o';
            case Keys.P: return 'p';
            case Keys.Q: return 'q';
            case Keys.R: return 'r';
            case Keys.S: return 's';
            case Keys.T: return 't';
            case Keys.U: return 'u';
            case Keys.V: return 'v';
            case Keys.W: return 'w';
            case Keys.X: return 'x';
            case Keys.Y: return 'y';
            case Keys.Z: return 'z';

            case Keys.D0: return '0';
            case Keys.D1: return '1';
            case Keys.D2: return '2';
            case Keys.D3: return '3';
            case Keys.D4: return '4';
            case Keys.D5: return '5';
            case Keys.D6: return '6';
            case Keys.D7: return '7';
            case Keys.D8: return '8';
            case Keys.D9: return '9';

            default: return '\0'; // Return null character for unsupported keys
        }
    }
}