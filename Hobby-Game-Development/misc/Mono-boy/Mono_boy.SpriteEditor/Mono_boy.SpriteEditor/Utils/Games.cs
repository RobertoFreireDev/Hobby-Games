using Mono_boy.SpriteEditor.Manager;
using System.Collections.Generic;

namespace Mono_boy.SpriteEditor.Utils;

public static class Games
{
    private static int CurrentGame = 0;

    public static Dictionary<int, GameData> List = new Dictionary<int, GameData>();

    public static GameData GetCurrentGame()
    {
        return List[CurrentGame];
    }

    public static int GetCurrentGameIndex()
    {
        return CurrentGame;
    }

    public static void UpdateCurrentGame(int newCurrentGame)
    {
        List = FileUtils.GetAllGames();
        CurrentGame = newCurrentGame;
        GlobalManager.ReloadScences();
    }

    public static void LoadGames()
    {
        List = FileUtils.GetAllGames();
    }

    public static void AddNewGame()
    {
        var total = FileUtils.GetTotalNumberOfGames();
        FileUtils.CreateEmptyGame(total);
        UpdateCurrentGame(total);
    }
}