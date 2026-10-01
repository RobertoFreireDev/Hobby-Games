using Microsoft.Xna.Framework;
using Mono_boy.SpriteEditor.Enums;
using Mono_boy.SpriteEditor.UIComponents.Base;
using Mono_boy.SpriteEditor.UIComponents.SongEditor;
using Mono_boy.SpriteEditor.Utils;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Manager;

internal class SongEditorManager : ISceneManager
{
    public List<Card> Cards = new List<Card>();
    public Piano Piano;
    public static int CurrentSong = 0;
    public static int TotalSongs = 6;
    public static uint SongMinLength = 12u;
    public static List<int[,]> Songs;
    public static int TimeSong = 100;
    public static uint MinSpeed = 8;
    public static uint MaxSpeed = 24;

    public SceneEnum SceneType { get; set; }

    public NavButtonEnum NavButton { get; set; }

    public SongEditorManager()
    {
        SceneType = SceneEnum.SONG;
        NavButton = NavButtonEnum.Song;
        LoadSongs();
    }

    private void LoadSongs()
    {
        Songs = new List<int[,]>();
        for (int i = 0; i < TotalSongs; i++)
        {
            Songs.Add(new int[Piano.SongLength, Piano.NotesNumber]);
        }

        var songs = Games.GetCurrentGame().Songs;

        for (int i = 0; i < songs.Count; i++)
        {
            Songs[i] = songs[i];
        }
    }

    public void LoadContent()
    {
        Cards.Add(new SfxSelectorCard(new Rectangle(4, 82, 118, 40)));
        Piano = new Piano();
    }

    public void Reload()
    {

    }

    public void Update()
    {
        foreach (var card in Cards)
        {
            card.Update();
        }
        Piano.Update();
    }

    public void Draw()
    {
        foreach (var card in Cards)
        {
            card.Draw();
        }
        Piano.Draw();
    }
}