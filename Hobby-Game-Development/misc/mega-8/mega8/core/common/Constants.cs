namespace mega8.core.common;

public static class Constants
{
    public static class Scene
    {
        public const int ZindexMin = 0;
        public const int ZindexMax = 15;
        public static int ClampZindex(int z) => Math.Clamp(z, ZindexMin, ZindexMax);
    }

    public static class Entity
    {
        public const int QtyFlags = 8;
        public const int MaxElements = 8;
    }

    public static class Error
    {
        public const string UNKWONERRORMESSAGE = "unknown error";
    }

    public static class Screen
    {
        public const int ResolutionX = 320;
        public const int ResolutionY = 180;
    }

    public static class GameDataSizes
    {
        public const int Sfx = 256;
        public const int SpriteSheetX = 128;
        public const int SpriteSheetY = 128;
        public const int TileSize = 8;
        public const int SpriteSheetColumns = 16; // SpriteSheetX / TileSize
        public const int SpriteSheetRows = 16; // SpriteSheetY / TileSize
        public const int ColorPalette = 33; // Include 0 : transparent
        public const int ColorPaletteMin = 1;
        public const int ColorPaletteMax = 32;
    }

    public static class File
    {
        public const string Name = "data";

        public const string Main = "main";

        public static class Extensions
        {
            public const string Sfx = "msfx8";

            public const string SpriteSheet = "msprt8";

            public const string Lua = "lua";
        }
    }
}
