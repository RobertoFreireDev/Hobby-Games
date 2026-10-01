using System;

namespace blackbox.Assets;

public static class AppConfig
{
    public static string Palette { get; set; } = string.Empty;
    public static string Title { get; set; } = string.Empty;
    public static int ResolutionX { get; set; }
    public static int ResolutionY { get; set; }
    public static bool IsFullscreen { get; set; }

    public static void SetConfig(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return;
        }

        var lines = content.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);

        foreach (var line in lines)
        {
            var parts = line.Split(new[] { '=' }, 2);
            if (parts.Length != 2) continue;

            var key = parts[0].Trim().ToLower();
            var value = parts[1].Trim();

            switch (key)
            {
                case "palette":
                    Palette = value.Trim('"');
                    break;
                case "title":
                    Title = value.Trim('"');
                    break;
                case "resolutionx":
                    if (int.TryParse(value, out int resX)) ResolutionX = resX;
                    break;
                case "resolutiony":
                    if (int.TryParse(value, out int resY)) ResolutionY = resY;
                    break;
                case "isfullscreen":
                    if (bool.TryParse(value, out bool isFull)) IsFullscreen = isFull;
                    break;
            }
        }
    }
}