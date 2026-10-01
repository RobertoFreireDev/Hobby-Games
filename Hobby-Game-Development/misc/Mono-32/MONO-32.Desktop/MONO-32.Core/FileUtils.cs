using Microsoft.Xna.Framework.Graphics;

namespace MONO_32.Core;

public static class FileUtils
{
    public static Dictionary<string,Texture2D> GetAllImages(
        GraphicsDevice graphicsDevice,
        string[] files)
    {
        var textures = new Dictionary<string, Texture2D>(); 
        foreach (string str in files)
        {
            int lastSlash = str.LastIndexOf('\\');
            string textureName = ((lastSlash > -1) ? str.Substring(lastSlash + 1) : str).Replace(".png", "");
            textures.Add(textureName, Texture2D.FromStream(graphicsDevice, (Stream)File.OpenRead(str)));
        }

        return textures;
    }
}
