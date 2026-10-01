using GameEngine.Enums;
using Microsoft.Xna.Framework;
using System.Collections.Generic;

namespace GameEngine.Elements.Map;

public class TileMap
{
    public string TextureKey;

    public Vector2 Position;

    public Dictionary<Vector2, int> Map;

    public MapLayerEnum Layer;
}
