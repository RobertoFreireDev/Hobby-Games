using Mono_boy.SpriteEditor.Manager;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Utils;

public class GameData
{
    public List<int[,]> DataList;

    public List<int[,]> Songs;

    public int PaletteIndex;

    public List<int[,]> TilesLayers;

    public string Script;

    public void SetGameData(List<int[,]> dataList, int paletteIndex, List<int[,]> tilesLayers, List<int[,]> songs, string script)
    {
        DataList = dataList;
        PaletteIndex = paletteIndex;
        TilesLayers = tilesLayers;
        Songs = songs;
        Script = script;
    }

    public List<int[,]> LoadTiles()
    {
        int gridSize = MapEditorManager.GridSize;
        var tiles = new List<int[,]>();
        tiles.Add(new int[gridSize, gridSize]);
        tiles.Add(new int[gridSize, gridSize]);
        tiles.Add(new int[gridSize, gridSize]);
        tiles.Add(new int[gridSize, gridSize]);
        tiles.Add(new int[gridSize, gridSize]);

        var tilesLayers = Games.GetCurrentGame().TilesLayers;
        if (tilesLayers == null || tilesLayers.Count == 0)
        {
            return tiles;
        }

        for (int i = 0; i < tilesLayers.Count; i++)
        {
            int layerRows = tilesLayers[i].GetLength(0);
            int layerCols = tilesLayers[i].GetLength(1);

            if (layerRows < gridSize || layerCols < gridSize)
            {
                for (int row = 0; row < layerRows; row++)
                {
                    for (int col = 0; col < layerCols; col++)
                    {
                        tiles[i][row, col] = tilesLayers[i][row, col];
                    }
                }
            }
            else
            {
                tiles[i] = tilesLayers[i];
            }
        }

        return tiles;
    }
}