using gameengine.Data;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;
using System.IO;

namespace gameengine.Utils;

internal class ImageFileUtils
{
    private const string ImagePath = "Assets/Images/";

    private const string ImageExt = "*.png";

    public static Dictionary<string, Texture2D> GetAllImages()
    {
        var files = Directory.GetFiles(ImagePath, ImageExt, SearchOption.AllDirectories);
        var textures = new Dictionary<string, Texture2D>();
        foreach (string str in files)
        {
            string textureName = Path.GetFileNameWithoutExtension(str);
            textures.Add(textureName, Texture2D.FromStream(FrameworkData.GraphicsDevice, File.OpenRead(str)));
        }

        return textures;
    }
}