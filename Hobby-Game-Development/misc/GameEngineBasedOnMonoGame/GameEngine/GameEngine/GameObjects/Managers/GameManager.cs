using GameEngine.Elements;
using GameEngine.Elements.Managers;
using GameEngine.Elements.Map;
using GameEngine.Enums;
using GameEngine.GameObjects.Elements;
using GameEngine.Utils;
using Microsoft.Xna.Framework;
using System.Collections.Generic;
using System.Linq;

namespace GameEngine.GameObjects.Managers;

public class GameManager : ISceneManager
{
    private Player _player;
    private List<Enemy> _enemies = new List<Enemy>();
    private List<StaticObject> _objects = new List<StaticObject>();

    public void LoadContent()
    {
        uint pixelsInUInt = 40;
        int pixels = (int)pixelsInUInt;
        TileMapManager.SetTileMapConfiguration(
            new()
            {
                new Tile()
                {
                    Texture = new Rectangle(0 * pixels, 1 * pixels, pixels, pixels)
                },
                new Tile()
                {
                    Texture = new Rectangle(0 * pixels, 1 * pixels, pixels, pixels),
                    Collidable = false
                }
            },
            pixels
        );
        TileMapManager.AddTileMap(
            "world",
            "../../../Tilemaps/Map.csv",
            "world",
            MapLayerEnum.Foreground,
            0 * pixelsInUInt,
            0 * pixelsInUInt
        );
        TileMapManager.AddTileMap(
            "hiddenplace1",
            "../../../Tilemaps/HiddenPlace1.csv",
            "world",
            MapLayerEnum.Parallax,
            10 * pixelsInUInt,
            3 * pixelsInUInt
        );
        Camera.LoadCamera();
        _player = new Player(22 * pixels, 20 * pixels);

        for (int i = 27; i <= 30; i+=2)
        {
            for (int j = 13; j <= 16; j+=2)
            {
                _enemies.Add(new Enemy(i * pixels, j * pixels));
            }
        }
        _objects.Add(new StaticObject(22 * pixels, 18 * pixels));

        var melody = "B15G30G5F5E5D10C20";
        MusicManager.AddMelody("Square", melody, Waveform.Square);
    }

    public void Update()
    {
        if (InputUtils.IsKeyJustPressed(InputEnum.ENTER))
        {
            MusicManager.Play("Square");
            GlobalManager.Scene = SceneEnum.MENU;
        }

        _player.Update(_enemies);
        foreach (var eny in _enemies)
        {
            eny.Update(_player, _enemies);
        }
        Camera.UpdateForFollowPosition(_player.GetBox().Center.ToVector2(), 0.05f);
    }

    public void Draw()
    {
        TileMapManager.Draw(MapLayerEnum.Background);
        TileMapManager.Draw(MapLayerEnum.Foreground);

        var objSrites = new List<SpriteObject>();
        objSrites.Add(_player);
        objSrites.AddRange(_enemies);
        objSrites.AddRange(_objects);
        objSrites = objSrites
            .OrderBy(obj => obj.AnimatedSprite.Ordering.IsSortable ? obj.Position.Y : obj.AnimatedSprite.Ordering.Z)
            .ToList();

        foreach (var obj in objSrites)
        {
            obj.Draw();
        }

        TileMapManager.Draw(MapLayerEnum.Parallax);
    }
}
