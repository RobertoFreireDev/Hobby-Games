using blackbox.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;

namespace blackbox.Graphics;

public static class Font
{
    public static char DefaultKey = '?';
    private static int Columns = 19;
    private static int CharWidth = 5;
    private static int CharHeight = 7;

    private static List<char> _charIndexes = new List<char>()
    {
        '0','1','2','3','4','5','6','7','8','9',
        'A','B','C','D','E','F','G','H','I','J','K',
        'L','M','N','O','P','Q','R','S','T','U','V',
        'W','X','Y','Z',
        'a','b','c','d','e','f','g','h','i','j','k',
        'l','m','n','o','p','q','r','s','t','u','v',
        'w','x','y','z',
        ',','.',':',';','[',']','{','}',
        '|','#','$','%','(',')','!','?',
        '"','\'','_','+','-','=','*','/','\\',
        '<','>',' ','~','Ꮖ'
    };

    public static Dictionary<char, Texture2D> GetCharacterTextures(
        GraphicsDevice graphicsDevice,
        Texture2D texture)
    {
        int columns = Columns;
        int charWidth = CharWidth;
        int charHeight = CharHeight;
        var charTextures = new Dictionary<char, Texture2D>();
        foreach (var charIndex in _charIndexes)
        {
            int row = (_charIndexes.IndexOf(charIndex) / columns);
            int column = (_charIndexes.IndexOf(charIndex) % columns);
            int x = column * charWidth;
            int y = row * charHeight;
            var sourceRect = new Rectangle(x, y, charWidth, charHeight);
            var characterTexture = new Texture2D(graphicsDevice, charWidth, charHeight);
            Color[] data = new Color[charWidth * charHeight];
            texture.GetData(0, sourceRect, data, 0, data.Length);
            characterTexture.SetData(data);
            charTextures[charIndex] = characterTexture;
        }

        return charTextures;
    }

    public static void DrawText(string text, Vector2 position, Color color, bool wraptext = false, int wrapLimit = 0)
    {
        var keyBoardKeys = GFW.MediumFontTextures;
        string[] lines = text.Split('\n');
        var copyPos = new Vector2(position.X, position.Y);
        int additionalLines = 0;

        if (wrapLimit == 0)
        {
            wrapLimit = ScreenUtils.BaseBox.Width - keyBoardKeys[DefaultKey].Width * 4;
        }

        for (int i = 0; i < lines.Length; i++)
        {
            position = new Vector2(copyPos.X, copyPos.Y + (i + additionalLines) * 9);

            for (int j = 0; j < lines[i].Length; j++)
            {
                char key = lines[i][j];

                // Check for color code "[cXX]"
                if (key == '[' && j + 4 < lines[i].Length && lines[i][j + 1] == 'c')
                {
                    string numStr = lines[i].Substring(j + 2, 2);
                    if (int.TryParse(numStr, out int colorIndex) && colorIndex >= 0 && colorIndex <= 31 && lines[i][j + 4] == ']')
                    {
                        color = ColorUtils.GetColor(colorIndex);
                        j += 4; // skip over "[cXX]"
                        continue;
                    }
                }

                var charTexture = keyBoardKeys.ContainsKey(key) ? keyBoardKeys[key] : keyBoardKeys[DefaultKey];

                if (wraptext && position.X >= wrapLimit)
                {
                    additionalLines++;
                    position = new Vector2(copyPos.X, copyPos.Y + (i + additionalLines) * 9);
                }

                if (key == '\t')
                {
                    position += new Vector2(charTexture.Width * 4, 0);
                    continue;
                }

                if (key == '\r')
                {
                    continue;
                }

                GFW.SpriteBatch.Draw(
                    charTexture,
                    new Vector2((int)position.X, (int)position.Y),
                    color);

                position += new Vector2((charTexture.Width - 1), 0);
            }
        }
    }
}
