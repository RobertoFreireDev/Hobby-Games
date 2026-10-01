using gameengine.Utils;
using System;

namespace gameengine.Data;

internal static class GameData
{
    // Game name
    public static string Name { get; private set; }

    // Last Time the game was saved
    public static DateTime LastDateModified { get; private set; }

    // Color palette index
    public static int PaletteIndex {  get; private set; }

    // Tiles
    // 8x8, 16x16, 32x32, 64x64
    // 320x320 pixels = 1600 8x8 sprites
    // X            : 320 pixels 
    // Y            : 320 pixels
    public static int[,] TilesGrid { get; set; }

    // Sfx
    // Quantity     : 64 
    // Time         : 24. In each time index, it stores the note
    // Volume       : 1200 pixels
    // Instrument   : To Be Defined
    public static int[,,] SfxList { get; set; }

    // Sfx
    // Quantity     : 64 (Same quantity)
    // Speed        : 4 variations
    public static int[] SfxSpeedList { get; set; }

    // Songs
    // Quantity     : 6
    // Time         : 600. In each time index, it stores the piano note
    // Notes        : 52 notes + 1 empty note
    public static int[,,] SongsList { get; set; }

    // Map
    // Tile 8x8
    // 1066x600 (16:9 aspect ratio)
    // Layers       : 3 
    // X            : 160 tiles (10 times the width screen size)
    // Y            : 180 tiles (20 times the height screen size)
    public static int[,,] MapGrid { get; set; }

    public static void UpdateColorPaletteIndex(int paletteIndex)
    {
        PaletteIndex = paletteIndex;
        ColorUtils.SetPalette(PaletteIndex);
    }

    public static void UpdateName(string name)
    {
        Name = name;
    }

    public static void NewGame()
    {
        PaletteIndex = 0;
        Name = "NEW GAME";
        TilesGrid = new int[640,128];
        SfxList = new int[64, 3, 24];
        SfxSpeedList = new int[64];
        SongsList = new int[6, 53, 600];
        MapGrid = new int[3, 160, 180];
    }

    public static void LoadGameData(
        string name,
        DateTime lastDateModified,
        int paletteIndex,
        int[,,] spriteGridList,
        int[,] tilesGrid,
        int[,,] sfxList,
        int[] sfxSpeedList,
        int[,,] songsList,
        int[,,] mapGrid
        )
    {
        Name = name;
        LastDateModified = lastDateModified;
        PaletteIndex = paletteIndex;
        TilesGrid = tilesGrid;
        SfxList = sfxList;
        SfxSpeedList = sfxSpeedList;
        SongsList = songsList;
        MapGrid = mapGrid;
    }
}
