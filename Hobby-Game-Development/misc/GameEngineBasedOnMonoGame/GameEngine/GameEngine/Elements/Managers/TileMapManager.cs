using GameEngine.Elements.Map;
using GameEngine.Enums;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.IO;

namespace GameEngine.Elements.Managers;

public static class TileMapManager
{
    public static Dictionary<string,TileMap> TileMaps = new Dictionary<string, TileMap>();

    public static List<Tile> Tiles;

    public static int Pixels;

    public static void SetTileMapConfiguration(List<Tile> tiles, int pixels)
    {
        Tiles = tiles;
        Pixels = pixels;
    }

    public static void AddTileMap(string name, string filePath, string textureKey, MapLayerEnum layer, uint positionX, uint positionY)
    {
        var tileMap = new TileMap()
        {
            TextureKey = textureKey,
            Position = new Vector2(positionX, positionY),            
            Map = new Dictionary<Vector2, int>(),
            Layer = layer,
        };

        var reader = new StreamReader(filePath);

        int y = 0;
        string line;
        while ((line = reader.ReadLine()) != null)
        {
            string[] items = line.Split(',');

            for (int x = 0; x < items.Length; x++)
            {
                if (int.TryParse(items[x], out int value))
                {
                    if (value > 0)
                    {
                        tileMap.Map[new Vector2(x, y)] = value;
                    }
                }
            }

            y++;
        }

        TileMaps.Add(name, tileMap);
    }

    public static void Draw(MapLayerEnum layer)
    {
        var batch = SpriteManager.GetSpriteBatchAndBeginWithLight();
        var offset = Camera.Position;

        foreach (var map in TileMaps)
        {
            if (map.Value.Layer != layer)
            {
                continue;
            }

            foreach (var tileItem in map.Value.Map)
            {
                var dest = GetTileRectangle(map.Value, tileItem.Key, (int)offset.X, (int)offset.Y);
                var src = Tiles[tileItem.Value - 1].Texture;
                batch.Draw(
                    TextureManager.Texture2D[map.Value.TextureKey],
                    dest,
                    src,
                    Color.White
                );
            }
        }

        batch.End();
    }

    public static bool IsColliding(Func<Rectangle, bool> collisionCheck)
    {
        foreach (var map in TileMaps)
        {
            foreach (var tileItem in map.Value.Map)
            {
                var tileRect = GetTileRectangle(map.Value, tileItem.Key);
                if (collisionCheck(tileRect))
                {
                    if (!Tiles[tileItem.Value - 1].Collidable)
                    {
                        continue;
                    }
                    return true;
                }
            }
        }

        return false;
    }

    public static bool IsCollidingWith(Rectangle rect)
    {
        return IsColliding(tileRect => tileRect.Intersects(rect));
    }

    public static bool IsCollidingWith(Vector2 position)
    {
        return IsColliding(tileRect => tileRect.Contains(position));
    }

    private static Rectangle GetTileRectangle(TileMap map, Vector2 tilePosition, int offSetX = 0, int offSetY = 0)
    {
        return new Rectangle(
            (int)map.Position.X + (int)tilePosition.X * Pixels + offSetX,
            (int)map.Position.Y + (int)tilePosition.Y * Pixels + offSetY,
            Pixels,
            Pixels
        );
    }
}
