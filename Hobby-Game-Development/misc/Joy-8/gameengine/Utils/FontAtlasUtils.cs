using gameengine.Data;
using gameengine.Utils.Objects;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;

namespace gameengine.Utils;

internal static class FontAtlasUtils
{
    public static char DefaultKey = '?';

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
        '"','\'','_','+','-','=','*','/',
        '<','>',' ','~','Ꮖ'
    };

    public static Font MediumFont = new Font()
    {
        Id = "medium_font",
        Columns = 19,
        CharWidth = 5,
        CharHeight = 7,
    };

    public static Font LargeFont = new Font()
    {
        Id = "large_font",
        Columns = 19,
        CharWidth = 8,
        CharHeight = 8,
    };

    public static Dictionary<char, Texture2D> GetCharMediumFont()
    {
        return GetCharacterTexture(MediumFont);
    }

    public static Dictionary<char, Texture2D> GetCharLargeFont()
    {
        return GetCharacterTexture(LargeFont);
    }

    private static Dictionary<char, Texture2D> GetCharacterTexture(Font font)
    {
        Texture2D fontAtlas = GameEngineData.Images[font.Id];
        int columns = font.Columns;
        int charWidth = font.CharWidth;
        int charHeight = font.CharHeight;
        var graphicsDevice = FrameworkData.GraphicsDevice;
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
            fontAtlas.GetData(0, sourceRect, data, 0, data.Length);
            characterTexture.SetData(data);
            charTextures[charIndex] = characterTexture;
        }

        return charTextures;
    }
}
