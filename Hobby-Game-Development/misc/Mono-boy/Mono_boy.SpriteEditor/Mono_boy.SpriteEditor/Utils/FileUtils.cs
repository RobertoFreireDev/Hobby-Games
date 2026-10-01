using Microsoft.Xna.Framework.Graphics;
using Mono_boy.SpriteEditor.Manager;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace Mono_boy.SpriteEditor.Utils;

public static class FileUtils
{
    private static string GamePath = "games\\";

    private static string GameExt = "*.txt";

    private static string ImagePath = "assets\\imgs\\";

    private static string ImageExt = "*.png";

    public static Dictionary<string, Texture2D> GetAllImages(GraphicsDevice graphicsDevice)
    {
        var files = Directory.GetFiles(ImagePath, ImageExt, SearchOption.AllDirectories);
        var textures = new Dictionary<string, Texture2D>();
        foreach (string str in files)
        {
            int lastSlash = str.LastIndexOf('\\');
            string textureName = ((lastSlash > -1) ? str.Substring(lastSlash + 1) : str).Replace(".png", "");
            textures.Add(textureName, Texture2D.FromStream(graphicsDevice, (Stream)File.OpenRead(str)));
        }

        return textures;
    }

    public static int GetTotalNumberOfGames()
    {
        string binDirectory = AppDomain.CurrentDomain.BaseDirectory;
        var directories = Directory.GetDirectories(binDirectory + "\\" + GamePath);
        HashSet<int> uniqueGameFolders = new HashSet<int>();

        foreach (string directory in directories)
        {
            string folderName = Path.GetFileName(directory);

            if (int.TryParse(folderName, out int folderNumber))
            {
                uniqueGameFolders.Add(folderNumber);
            }
        }

        return uniqueGameFolders.Count;
    }

    public static Dictionary<int, GameData> GetAllGames()
    {
        string binDirectory = AppDomain.CurrentDomain.BaseDirectory;
        var gameFiles = Directory.GetFiles(binDirectory + "\\" + GamePath, GameExt, SearchOption.AllDirectories);
        var games = new Dictionary<int, GameData>();

        if (gameFiles.Length == 0)
        {
            Games.AddNewGame();
            List<int[,]> dataList = new List<int[,]>();
            List<int[,]> songs = new List<int[,]>();
            int PaletteIndex = 0;
            List<int[,]> tilesLayers = new List<int[,]>();
            string script = string.Empty;
            var gameData = new GameData();
            gameData.SetGameData(dataList, PaletteIndex, tilesLayers, songs, script);
            games.Add(0, gameData);
            return games;
        }

        foreach (string str in gameFiles)
        {
            try
            {
                string directoryPath = Path.GetDirectoryName(str);
                // Extract the GUID from the folder name (which is one level above the 'game.txt' file)
                int lastSlash = directoryPath.LastIndexOf('\\');
                string folderName = directoryPath.Substring(lastSlash + 1);

                // Parse the folder name as a GUID
                if (int.TryParse(folderName, out int gameId))
                {
                    // Add the parsed GUID to the dictionary with the GameData (assuming you initialize GameData later)
                    var gameData = LoadGame(directoryPath);
                    games.Add(gameId, gameData);
                }
            }
            catch (Exception ex)
            {
                continue;
            }
        }

        return games;
    }

    public static void SaveGame()
    {
        List<int[,]> dataList = SpriteEditorManager.Sprites.Sprites.Select(s => s.Sprite.GridColors).ToList();
        List<int[,]> songs = SongEditorManager.Songs;
        List<int[,]> layersMapDataList = MapEditorManager.Map.Tiles.ToList();
        string filePath = GamePath + Games.GetCurrentGameIndex() + "\\game.txt";

        using (StreamWriter writer = new StreamWriter(filePath))
        {
            writer.WriteLine($"BEGIN CONFIGURATION DATA");
            writer.WriteLine($"PALETTE:{ColorUtils.GetCurrentPalette()}");
            writer.WriteLine($"END CONFIGURATION DATA");
            writer.WriteLine($"BEGIN SONGS");
            for (int i = 0; i < songs.Count; i++)
            {
                writer.WriteLine($"BEGIN SONG {i}:");
                int[,] array = songs[i];
                for (int row = 0; row < array.GetLength(0); row++)
                {
                    for (int col = 0; col < array.GetLength(1); col++)
                    {
                        writer.Write(array[row, col]);
                        if (col < array.GetLength(1) - 1)
                            writer.Write(", "); // Comma-separated values
                    }
                    writer.WriteLine(); // New line after each row
                }
                writer.WriteLine($"END SONG {i}:");
            }
            writer.WriteLine($"END SONGS");
            writer.WriteLine($"BEGIN SPRITES");
            for (int i = 0; i < dataList.Count; i++)
            {
                writer.WriteLine($"BEGIN SPRITE {i}:");
                int[,] array = dataList[i];
                for (int row = 0; row < array.GetLength(0); row++)
                {
                    for (int col = 0; col < array.GetLength(1); col++)
                    {
                        writer.Write(array[col, row]);
                        if (col < array.GetLength(1) - 1)
                            writer.Write(", "); // Comma-separated values
                    }
                    writer.WriteLine(); // New line after each row
                }
                writer.WriteLine($"END SPRITE {i}:");
            }
            writer.WriteLine($"END SPRITES");
            writer.WriteLine($"BEGIN LAYERSMAP");
            for (int i = 0; i < layersMapDataList.Count; i++)
            {
                writer.WriteLine($"BEGIN LAYERMAP {i}:");
                int[,] array = layersMapDataList[i];
                for (int row = 0; row < array.GetLength(0); row++)
                {
                    for (int col = 0; col < array.GetLength(1); col++)
                    {
                        writer.Write(array[col, row]);
                        if (col < array.GetLength(1) - 1)
                            writer.Write(", "); // Comma-separated values
                    }
                    writer.WriteLine(); // New line after each row
                }
                writer.WriteLine($"END LAYERMAP {i}:");
            }
            writer.WriteLine($"END LAYERSMAP");
        }
    }

    public static void CreateEmptyGame(int index)
    {
        string folderPath = GamePath + index;
        string scriptPath = Path.Combine(folderPath, "game.lua");
        Directory.CreateDirectory(folderPath);

        using (StreamWriter writer = new StreamWriter(scriptPath))
        {
            writer.WriteLine("function _init()");
            writer.WriteLine("end");
            writer.WriteLine("");
            writer.WriteLine("function _update()");
            writer.WriteLine("end");
            writer.WriteLine("");
            writer.WriteLine("function _draw()");
            writer.WriteLine("end");
        }

        string dataPath = Path.Combine(folderPath, "game.txt");
        Directory.CreateDirectory(folderPath);

        using (StreamWriter writer = new StreamWriter(dataPath))
        {
            writer.WriteLine("");
        }
    }

    public static GameData LoadGame(string path)
    {
        List<int[,]> dataList = new List<int[,]>();
        List<int[,]> songs = new List<int[,]>();
        int PaletteIndex = 0;
        List<int[,]> tilesLayers = new List<int[,]>();
        string script = string.Empty;
        var gameData = new GameData();
        string filePath = path + "\\game.txt";
        string scriptPath = path + "\\game.lua";
        int? spriteIndex = null;
        int? songIndex = null;
        int? mapIndex = null;

        if (!File.Exists(filePath))
        {
            gameData.SetGameData(dataList, PaletteIndex, tilesLayers, songs, script);
            return gameData;
        }

        script = GetFileContent(scriptPath);

        using (StreamReader reader = new StreamReader(filePath))
        {
            string line;
            bool inSpriteSection = false;
            bool inSongsSection = false;
            bool inMetaDataSection = false;
            bool inLayersMapDataSection = false;
            List<string[]> currentSongData = new List<string[]>();
            List<string[]> currentSpriteData = new List<string[]>();
            List<string[]> currentlayerMapData = new List<string[]>();

            while ((line = reader.ReadLine()) != null)
            {
                if (line == "BEGIN SONGS")
                {
                    inSongsSection = true;
                    continue;
                }
                else if (line == "END SONGS")
                {
                    inSongsSection = false;
                    continue;
                }
                else if(line == "BEGIN LAYERSMAP")
                {
                    inLayersMapDataSection = true;
                    continue;
                }
                else if (line == "END LAYERSMAP")
                {
                    inLayersMapDataSection = false;
                    continue;
                }
                else if(line == "BEGIN SPRITES")
                {
                    inSpriteSection = true;
                    continue;
                }
                else if (line == "END SPRITES")
                {
                    inSpriteSection = false;
                    continue;
                }
                else if (line == "BEGIN CONFIGURATION DATA")
                {
                    inMetaDataSection = true;
                    continue;
                }
                else if (line == "END CONFIGURATION DATA")
                {
                    inMetaDataSection = false;
                    continue;
                }

                if (inSongsSection)
                {
                    if (line.StartsWith("BEGIN SONG "))
                    {
                        songIndex = GetIntValue(line, @"BEGIN SONG (\d+):");
                        continue;
                    }
                    else if (line.StartsWith("END SONG "))
                    {
                        if (currentSongData.Count > 0)
                        {
                            int rows = currentSongData.Count;
                            int cols = currentSongData[0].Length;
                            int[,] songsArray = new int[rows, cols];

                            for (int row = 0; row < rows; row++)
                            {
                                for (int col = 0; col < cols; col++)
                                {
                                    songsArray[row, col] = int.Parse(currentSongData[row][col]);
                                }
                            }

                            songs.Add(songsArray);
                            currentSongData.Clear();
                        }
                        songIndex = null;
                        continue;
                    }

                    if (songIndex.HasValue)
                    {
                        string[] rowValues = line.Split(new[] { ", " }, StringSplitOptions.None);
                        currentSongData.Add(rowValues);
                    }
                }

                if (inSpriteSection)
                {
                    if (line.StartsWith("BEGIN SPRITE "))
                    {
                        spriteIndex = GetIntValue(line, @"BEGIN SPRITE (\d+):");
                        continue;
                    }
                    else if (line.StartsWith("END SPRITE "))
                    {
                        if (currentSpriteData.Count > 0)
                        {
                            int rows = currentSpriteData.Count;
                            int cols = currentSpriteData[0].Length;
                            int[,] spriteArray = new int[rows, cols];

                            for (int row = 0; row < rows; row++)
                            {
                                for (int col = 0; col < cols; col++)
                                {
                                    spriteArray[col, row] = int.Parse(currentSpriteData[row][col]);
                                }
                            }

                            dataList.Add(spriteArray);
                            currentSpriteData.Clear(); // Clear the current sprite data for the next sprite
                        }
                        spriteIndex = null;
                        continue;
                    }

                    if (spriteIndex.HasValue)
                    {
                        string[] rowValues = line.Split(new[] { ", " }, StringSplitOptions.None);
                        currentSpriteData.Add(rowValues);
                    }
                }

                if (inMetaDataSection)
                {
                    if (line.StartsWith("PALETTE:"))
                    {
                        PaletteIndex = GetIntValue(line, @"PALETTE:(\d+)");
                    }
                }

                if (inLayersMapDataSection)
                {
                    if (line.StartsWith("BEGIN LAYERMAP "))
                    {
                        mapIndex = GetIntValue(line, @"BEGIN LAYERMAP (\d+):");
                        continue;
                    }
                    else if (line.StartsWith("END LAYERMAP "))
                    {
                        if (currentlayerMapData.Count > 0)
                        {
                            int rows = currentlayerMapData.Count;
                            int cols = currentlayerMapData[0].Length;
                            int[,] layerMapArray = new int[rows, cols];

                            for (int row = 0; row < rows; row++)
                            {
                                for (int col = 0; col < cols; col++)
                                {
                                    layerMapArray[col, row] = int.Parse(currentlayerMapData[row][col]);
                                }
                            }

                            tilesLayers.Add(layerMapArray);
                            currentlayerMapData.Clear(); // Clear the current sprite data for the next sprite
                        }
                        mapIndex = null;
                        continue;
                    }

                    if (mapIndex.HasValue)
                    {
                        string[] rowValues = line.Split(new[] { ", " }, StringSplitOptions.None);
                        currentlayerMapData.Add(rowValues);
                    }
                }
            }
        }

        gameData.SetGameData(dataList, PaletteIndex, tilesLayers, songs, script);
        return gameData;
    }

    private static string GetFileContent(string filePath)
    {
        try
        {
            using (StreamReader reader = new StreamReader(filePath))
            {
                return reader.ReadToEnd();
            }
        }
        catch (FileNotFoundException e)
        {
            Console.WriteLine("File not found: " + e.Message);
        }
        catch (IOException e)
        {
            Console.WriteLine("Error reading file: " + e.Message);
        }

        return string.Empty;
    }

    private static int GetIntValue(string line, string text)
    {
        Regex regex = new Regex(text);

        Match match = regex.Match(line);
        if (match.Success && int.TryParse(match.Groups[1].Value, out int i))
        {
            return i;
        }

        throw new FormatException("The string is not in the expected format.");
    }
}