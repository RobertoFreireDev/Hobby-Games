using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.IO;
using System;

namespace MONO_32.SpriteGUIEditor.Extensions;

public static class Texture2DExtensions
{
    public static void SaveImageAsPng(this Texture2D texture, string fileName)
    {
        var projectRootPath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, @"..\..\..\..\MONO-32.DektopGame\assets\imgs"));
        var filePath = Path.Combine(projectRootPath, fileName);

        var data = new Color[texture.Width * texture.Height];
        texture.GetData(data);

        // Convert to System.Drawing.Bitmap
        using (System.Drawing.Bitmap bitmap = new System.Drawing.Bitmap(texture.Width, texture.Height))
        {
            for (int y = 0; y < texture.Height; y++)
            {
                for (int x = 0; x < texture.Width; x++)
                {
                    // Convert Color to System.Drawing.Color
                    System.Drawing.Color color = System.Drawing.Color.FromArgb(data[x + y * texture.Width].A,
                                                                              data[x + y * texture.Width].R,
                                                                              data[x + y * texture.Width].G,
                                                                              data[x + y * texture.Width].B);
                    bitmap.SetPixel(x, y, color);
                }
            }

            bitmap.Save(filePath, System.Drawing.Imaging.ImageFormat.Png);
        }
    }
}
