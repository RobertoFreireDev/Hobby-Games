namespace mono8;

internal class Mono8API : IEditorAPI
{
    public static EditorRegistry Editors = new EditorRegistry();
    private static SfxEngine _sfxEngine = new SfxEngine();
    public static SpriteSheet SpriteSheet = new SpriteSheet();
    public static AutotileSheet AutotileSheet = new AutotileSheet();
    public static SfxSheet SfxSheet = new SfxSheet();
    public static MusicSheet MusicSheet = new MusicSheet();
    public static MapSheet MapSheet = new MapSheet();
    public static LuaSheet LuaSheet = new LuaSheet();
    private static string _folder = Constants.File.Folder;
    private EditorMenuBar _menuBar;
    private LuaGame _game;
    private bool _playingGame;

    // While a host cart Save/Load dialog is open, the engine pauses and draws a "busy" overlay in place
    // of the editor (the dialog is asynchronous on the web head). Null means not busy; cleared by the
    // completion callback CartIO invokes once the dialog is dismissed. See ExportCart/ImportCart.
    private string _busyMessage;

    // Heavy cart work (serialize on save, parse+persist on load) deferred to the tick after the busy
    // overlay is set, so the "busy" screen is actually drawn before we block the thread doing it.
    private Action _pendingBusyWork;

    public bool IsPlayingGame => _playingGame;

    public Mono8API()
    {
        Load();
        Editors.Register(new SpriteEditor(this), 15, "Sprite");
        Editors.Register(new MapEditor(this), 16, "Map");
        Editors.Register(new SfxEditor(this), 17, "Sfx");
        Editors.Register(new MusicEditor(this), 18, "Music");
        _menuBar = new EditorMenuBar(this, Editors);
        _game = new LuaGame(this);

        // Boot straight into the running game rather than the editor; Esc drops out of it into the
        // editor (and, on the web head, on into the Lua code editor). The web head starts its JS Esc
        // cycle in the matching "game running" state — see index.html.
        RunGame();
    }

    internal void Load()
    {
        var path = Path.Combine(Directory.GetCurrentDirectory(), _folder);

        // The whole cartridge is one sectioned file now; parse it once, then hand each __section__
        // to its sheet. data.icons (built-in) and data.save stay as their own files.
        var cart = DataFile.Parse(FileIO.Read(Constants.File.Name, Constants.File.Extensions.Cart, path));

        ApplyCart(cart);
        IconSheet.LoadIcons(ReadLines(Constants.File.Extensions.IconSheet, path));
        SaveData.Load(path);

        _sfxEngine.Sfx(-1);
    }

    // Hand each parsed __section__ to its sheet and push the audio snapshots into the engine. Shared
    // by Load() (the on-disk cartridge) and Import() (a user-chosen cartridge file). data.icons and
    // data.save are deliberately excluded: they are not part of a cartridge.
    private void ApplyCart(Dictionary<string, string> cart)
    {
        LuaSheet.LoadLua(CartLines(cart, Constants.File.Extensions.Lua));
        SfxSheet.LoadSfxs(CartLines(cart, Constants.File.Extensions.Sfx));
        MusicSheet.LoadMusic(CartLines(cart, Constants.File.Extensions.Music));
        SpriteSheet.LoadSprites(
            CartLines(cart, Constants.File.Extensions.SpriteSheet),
            CartLines(cart, Constants.File.Extensions.Flags));
        AutotileSheet.LoadAutotiles(CartLines(cart, Constants.File.Extensions.Autotile));
        MapSheet.LoadMaps(CartLines(cart, Constants.File.Extensions.MapSheet));

        // The sheets are the only parsers; the engine plays the snapshots they hand it.
        for (int i = 0; i < SfxSheet.Count; i++) SyncSfx(i);
        for (int p = 0; p < MusicSheet.Count; p++) SyncMusic(p);
    }

    // A cart section that is absent reads as empty, exactly like a missing file did before.
    private static string[] CartLines(Dictionary<string, string> cart, string extension) =>
        FileIO.SplitData(cart.TryGetValue(extension, out var body) ? body : string.Empty);

    private static string[] ReadLines(string extension, string path) =>
        FileIO.SplitData(FileIO.Read(Constants.File.Name, extension, path));

    internal void Save()
    {
        var path = Path.Combine(Directory.GetCurrentDirectory(), _folder);
        FileIO.Write(Constants.File.Name, Constants.File.Extensions.Cart, BuildCart(), path);
    }

    // Serialize every sheet into the single sectioned cartridge text (the same text Save() writes to
    // data.mono8), so Save() and Export() round-trip through the identical format.
    private string BuildCart() => DataFile.Build(new[]
    {
        // Lua source goes first, so a cartridge opens with its game code at the top of data.mono8.
        (Constants.File.Extensions.Lua, LuaSheet.ToLuaText()),
        (Constants.File.Extensions.SpriteSheet, string.Join("\n", SpriteSheet.ToSheetLines())),
        (Constants.File.Extensions.Flags, string.Join("\n", SpriteSheet.ToFlagLines())),
        (Constants.File.Extensions.Autotile, string.Join("\n", AutotileSheet.ToAutotileLines())),
        (Constants.File.Extensions.MapSheet, string.Join("\n", MapSheet.ToMapLines())),
        (Constants.File.Extensions.Sfx, string.Join("\n", SfxSheet.ToSfxLines())),
        (Constants.File.Extensions.Music, string.Join("\n", MusicSheet.ToMusicLines())),
    });

    // Menu-bar Save: hand the current cartridge text to the host "save as" dialog (browser download
    // on the web head; no-op on desktop, where CartIO.OnExport is null). While the dialog is open the
    // engine shows a "saving cart..." overlay and pauses; the completion callback lifts it afterward.
    public void ExportCart()
    {
        if (CartIO.OnExport == null) return;
        _busyMessage = "saving cart...";
        _pendingBusyWork = () => CartIO.OnExport.Invoke(
            $"{Constants.File.Name}.{Constants.File.Extensions.Cart}",
            BuildCart(),
            DismissBusy);
    }

    // Menu-bar Load: ask the host to pick a cartridge file, then apply and persist its contents so
    // the loaded cartridge becomes the current one (and survives a reload on the web head). Mirrors
    // ExportCart's busy overlay/pause while the picker is open.
    public void ImportCart()
    {
        if (CartIO.OnImport == null) return;
        _busyMessage = "loading cart...";
        _pendingBusyWork = () => CartIO.OnImport.Invoke(
            raw =>
            {
                ApplyCart(DataFile.Parse(raw));
                Save();
            },
            DismissBusy);
    }

    // Lift the busy overlay once a host cart dialog is dismissed. The dialog was opened by a left-click
    // whose mouse-up landed on the OS dialog rather than the canvas, so the button can resume stuck at
    // "pressed"; latch it off until it genuinely releases so no phantom click/drag leaks into the editor.
    private void DismissBusy()
    {
        _busyMessage = null;
        InputStateManager.SuppressLeftButtonUntilReleased();
    }

    /// <summary>Start running the user's game (recompiling the current Lua). On desktop this is the
    /// editor->game step of the Esc state cycle; the web head calls it from JS, which drives the same
    /// cycle (editor -> game -> Lua code editor) because its engine tick doesn't see Esc. Compile
    /// errors are routed to the on-screen ErrorHandler, matching the normal run path in
    /// <see cref="Update"/>.</summary>
    public void RunGame()
    {
        try
        {
            ErrorHandler.Reset();
            _playingGame = true;
            _game.Init();
        }
        catch (Exception ex) { ErrorHandler.SetError(ex); }
    }

    /// <summary>Stop the running game and return to the editor — the game->(next) step of the Esc
    /// state cycle. The web head calls this from JS since its engine tick doesn't handle Esc.</summary>
    public void StopGame() 
    {
        ErrorHandler.Reset();
        _playingGame = false;
    }

    /// <summary>Push the editor's current SFX edits into the live audio engine so previews reflect them.</summary>
    internal void SyncSfx(int index) => _sfxEngine.SetSfx(index, SfxSheet.ToSfxData(index));

    /// <summary>Push the editor's current music-pattern edits into the live audio engine.</summary>
    internal void SyncMusic(int index) => _sfxEngine.SetMusic(index, MusicSheet.ToMusicData(index));

    /// <summary>Note the engine is currently playing for <paramref name="index"/> (-1 if not playing); drives the editor playhead.</summary>
    internal int CurrentSfxNote(int index) => _sfxEngine.CurrentNote(index);

    /// <summary>Music pattern the engine is currently playing (-1 if none); drives the Music editor's playing indicator.</summary>
    internal int CurrentMusicPattern() => _sfxEngine.CurrentMusicPattern;

    public void Update(GameTime gameTime)
    {
        if (ErrorHandler.HasError()) return;

        // A host cart Save/Load dialog is open: pause all editor/game logic until it is dismissed.
        // Any heavy cart work was deferred to here so the busy overlay is drawn (last tick) before we
        // block on it; run it once, then keep pausing until the completion callback clears the message.
        if (_busyMessage != null)
        {
            var work = _pendingBusyWork;
            _pendingBusyWork = null;
            work?.Invoke();
            return;
        }

        try
        {
            Editors.EnsureActiveInitialized();

            _sfxEngine.UpdateMusic();
            if (!Menu.IsPaused())
            {
                if (_playingGame)
                {
#if !BLAZORGL
                    // Esc toggles editor <-> game. On the web head the Lua code editor is a third
                    // state in this cycle, so the browser drives the whole cycle from JS (see
                    // index.html) and the engine tick doesn't handle Esc there.
                    if (KeybrdInput.IsEscJustPressed())
                        StopGame();
                    else
#endif
                        _game.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
                }
                else
                {
#if !BLAZORGL
                    if (KeybrdInput.IsEscJustPressed())
                        RunGame();
                    else
#endif
                    {
                        _menuBar.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
                        Editors.Active.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
                    }
                }
            }
        }
        catch (Exception ex) { ErrorHandler.SetError(ex); }
    }

    public void Draw()
    {
        if (ErrorHandler.HasError())
        {
            ErrorHandler.Draw();
            return;
        }

        try
        {
            if (_busyMessage != null)
            {
                DrawBusyOverlay(_busyMessage);
                return;
            }

            if (_playingGame)
            {
                _game.Draw();
            }
            else
            {
                Editors.Active.Draw();
                _menuBar.Draw();
            }

            camera(0, 0);
            Menu.Draw();
        }
        catch (Exception ex) { ErrorHandler.SetError(ex); }
    }

    // Fill the screen dark grey and center a status message, shown while a host cart dialog is open.
    private void DrawBusyOverlay(string message)
    {
        camera(0, 0);
        rectfill(0, 0, Constants.Screen.ResolutionX, Constants.Screen.ResolutionY, Constants.Colors.DarkGray);

        // Each glyph advances 4px (5px wide, 1px overlap) and is 7px tall (see Text.DrawText), so
        // center the message on those metrics.
        int width = message.Length * 4;
        int x = (Constants.Screen.ResolutionX - width) / 2;
        int y = (Constants.Screen.ResolutionY - 7) / 2;
        print(message, x, y, Constants.Colors.White);
    }

    public void StopSounds() => _sfxEngine.Sfx(-1);

    public void Unload()
    {
        StopSounds();
        _sfxEngine.Dispose();
    }

    public bool btn(int button) => ButtonInput.Pressed(button);
    public bool btn(int button, int player) => ButtonInput.Pressed(player * 8 + button);
    public bool btnp(int button) => ButtonInput.JustPressed(button);
    public bool btnp(int button, int player) => ButtonInput.JustPressed(player * 8 + button);
    public bool btnr(int button) => ButtonInput.Released(button);
    public bool mouseup() => MouseInputBinding.ScrollUp();
    public bool mousedown() => MouseInputBinding.ScrollDown();
    public bool mouselp() => MouseInputBinding.LeftJustPressed();
    public bool mouselr() => MouseInputBinding.LeftReleased();
    public bool mousel() => MouseInputBinding.LeftPressed();
    public bool mouserp() => MouseInputBinding.RightJustPressed();
    public bool mouserr() => MouseInputBinding.RightReleased();
    public bool mouser() => MouseInputBinding.RightPressed();
    public (int x, int y) mousexy() => MouseInputBinding.PosXY();

    public void camera(float x = 0, float y = 0)
    {
        Mono8Game.SpriteBatch.End();
        Camera2D.Camera((int)x, (int)y);
        Mono8Game.SpriteBatch.Begin();
    }

    public void print(string text, int x, int y, int color = 7, float colorOpaqueness = 1f)
    {
        // offset 1 pixel up
        Text.DrawText(text, new Vector2(x,y-1), color, colorOpaqueness: colorOpaqueness);
    }

    public void icon(int n, int x, int y)
    {
        IconSheet.Draw(n, x, y);
    }

    public void SetPixel(int x, int y, int colorIndex) => SpriteSheet.SetPixel(x, y, colorIndex);

    public void SetRectFill(int x, int y, int w, int h, int colorIndex) => SpriteSheet.SetRectFill(x, y, w, h, colorIndex);

    public void SetRect(int x, int y, int w, int h, int colorIndex) => SpriteSheet.SetRect(x, y, w, h, colorIndex);

    public void SetOval(int x0, int y0, int x1, int y1, int colorIndex) => SpriteSheet.SetOval(x0, y0, x1, y1, colorIndex);

    public void SetOvalFill(int x0, int y0, int x1, int y1, int colorIndex) => SpriteSheet.SetOvalFill(x0, y0, x1, y1, colorIndex);

    public void SetPaintBucket(int x, int y, int regionX, int regionY, int regionW, int regionH, int colorIndex)
        => SpriteSheet.PaintBucket(x, y, regionX, regionY, regionW, regionH, colorIndex);

    public void sfx(int sfxId, int channel = -1, int offset = 0, int length = -1) 
        => _sfxEngine.Sfx(sfxId, channel, offset, length);

    public void spr(int spriteId, int x, int y, int width = 1, int height = 1,
        float scale = 1f, bool flipX = false, bool flipY = false, float colorOpaqueness = 1f)
    {
        SpriteSheet.Draw(false, spriteId, x, y, width, height, scale, flipX, flipY, colorOpaqueness);
    }

    public void sspr(int sx, int sy, int sw, int sh, int dx, int dy,
        int dw = -1, int dh = -1, bool flipX = false, bool flipY = false, float colorOpaqueness = 1f)
    {
        SpriteSheet.DrawSub(false, sx, sy, sw, sh, dx, dy, dw < 0 ? sw : dw, dh < 0 ? sh : dh, flipX, flipY, colorOpaqueness);
    }

    public void sprr(int spriteId, int x, int y, int width = 1, int height = 1,
        float scale = 1f, bool flipX = false, bool flipY = false, float colorOpaqueness = 1f)
    {
        SpriteSheet.Draw(true, spriteId, x, y, width, height, scale, flipX, flipY, colorOpaqueness);
    }

    public void ssprr(int sx, int sy, int sw, int sh, int dx, int dy,
        int dw = -1, int dh = -1, bool flipX = false, bool flipY = false, float colorOpaqueness = 1f)
    {
        SpriteSheet.DrawSub(true, sx, sy, sw, sh, dx, dy, dw < 0 ? sw : dw, dh < 0 ? sh : dh, flipX, flipY, colorOpaqueness);
    }

    public void cls(int colorIndex = 0)
    {
        Mono8Game.SpriteBatch.DrawBaseBox(colorIndex);
    }

    public int stat(int id)
    {
        switch (id)
        {
            case 7:
                return Mono8Game.DisplayFps;
        }

        return 0;
    }

    public void pixel(int x, int y, int color, float colorOpaqueness = 1f)
    {
        Mono8Game.SpriteBatch.DrawPixel(x, y, color, colorOpaqueness);
    }

    public void line(int x0, int y0, int x1, int y1, int color)
    {
        Mono8Game.SpriteBatch.DrawLine(x0, y0, x1, y1, color);
    }

    public void rect(int x0, int y0, int x1, int y1, int color, float colorOpaqueness = 1f)
    {
        (int x, int y, int w, int h) = ToRect(x0, y0, x1, y1);
        Mono8Game.SpriteBatch.DrawRect(x, y, w, h, color, colorOpaqueness);
    }

    public void rectfill(int x0, int y0, int x1, int y1, int color, float colorOpaqueness = 1f)
    {
        (int x, int y, int w, int h) = ToRect(x0, y0, x1, y1);
        Mono8Game.SpriteBatch.DrawRectFill(x, y, w, h, color, colorOpaqueness);
    }

    public (int x, int y, int w, int h) ToRect(int x0, int y0,int x1, int y1)
    {
        return (Math.Min(x0, x1), Math.Min(y0, y1), Math.Abs(x1 - x0) + 1, Math.Abs(y1 - y0) + 1);
    }

    public void circ(int x, int y, int radius, int color, float colorOpaqueness = 1f)
    {
        Mono8Game.SpriteBatch.DrawCirc(x, y, radius, color, colorOpaqueness);
    }

    public void circfill(int x, int y, int radius, int color, float colorOpaqueness = 1f)
    {
        Mono8Game.SpriteBatch.DrawCircFill(x, y, radius, color, colorOpaqueness);
    }

    public void oval(int x0, int y0, int x1, int y1, int color, float colorOpaqueness = 1f)
    {
        Mono8Game.SpriteBatch.DrawOval(x0, y0, x1, y1, color, colorOpaqueness);
    }

    public void ovalfill(int x0, int y0, int x1, int y1, int color, float colorOpaqueness = 1f)
    {
        Mono8Game.SpriteBatch.DrawOvalFill(x0, y0, x1, y1, color, colorOpaqueness);
    }

    public void palt()
    {
        ColorPalette.PaltReset();
    }

    public void palt(int colorIndex)
    {
        ColorPalette.Palt(colorIndex, true);
    }

    public void palt(int colorIndex, bool transparent)
    {
        ColorPalette.Palt(colorIndex, transparent);
    }

    public void pal()
    {
        ColorPalette.Pal();
    }

    public void pal(int c0, int c1)
    {
        ColorPalette.Pal(c0, c1);
    }

    public int mget(int cellX, int cellY)
    {
        return MapSheet.GetTile(cellX, cellY);
    }

    public void mset(int cellX, int cellY, int spriteId)
    {
        MapSheet.SetTile(cellX, cellY, spriteId);
    }

    private static readonly float[] MapScales = { 0.5f, 1f, 2f };

    // Unlike spr, map only supports these three scales; anything else snaps to the
    // nearest one rather than drawing at an unsupported size.
    private static float SnapMapScale(float scale)
    {
        float nearest = MapScales[0];
        foreach (float candidate in MapScales)
        {
            if (Math.Abs(scale - candidate) < Math.Abs(scale - nearest)) nearest = candidate;
        }
        return nearest;
    }

    public void map(int cellX, int cellY, int screenX, int screenY, int cellWidth = 40, int cellHeight = 23,
        float scale = 1f, float colorOpaqueness = 1f, int layerMax = 0)
    {
        MapSheet.DrawMap(cellX, cellY, screenX, screenY, cellWidth, cellHeight,
            SnapMapScale(scale), colorOpaqueness, layerMax);
    }

    public int fget(int spriteId) => SpriteSheet.GetFlags(spriteId);

    public bool fget(int spriteId, int flag) => SpriteSheet.GetFlag(spriteId, flag);

    public void fset(int spriteId, int flag, bool value) => SpriteSheet.SetFlag(spriteId, flag, value);

    public void fset(int spriteId, int value) => SpriteSheet.SetFlags(spriteId, value);

    public void music(int musicId, int fadeLength = 0, int channelMask = 0)
        => _sfxEngine.Music(musicId, fadeLength, channelMask);

    private static Random _rng = new Random();

    public float rnd(float max = 1f) => (float)_rng.NextDouble() * max;

    public double rnd(double max) => _rng.NextDouble() * max;

    public int rnd(int max) => max <= 0 ? 0 : _rng.Next(0, max);

    public void srand(int seed) => _rng = new Random(seed);

    public double time() => (double)DateTime.Now.TimeOfDay.TotalSeconds;

    public double abs(double value) => Math.Abs(value);

    public double atan2(double dy, double dx) => Math.Atan2(dy, dx) / (2 * Math.PI);

    public double cos(double angle) => Math.Cos(angle * 2 * Math.PI);

    // PICO-8 sin is negated (y-axis flipped)
    public double sin(double angle) => -Math.Sin(angle * 2 * Math.PI);

    public double sqrt(double value) => Math.Sqrt(value);

    public double min(double a, double b) => Math.Min(a, b);

    public double max(double a, double b) => Math.Max(a, b);

    public double mid(double a, double b, double c) => Math.Max(Math.Min(Math.Max(a, b), c), Math.Min(a, b));

    public double flr(double value) => Math.Floor(value);

    public double ceil(double value) => Math.Ceiling(value);

    public double round(double value) => Math.Round(value, MidpointRounding.AwayFromZero);

    public int sgn(double value) => value > 0 ? 1 : value < 0 ? -1 : 0;

    public int dget(int index) => SaveData.Get(index);

    public void dset(int index, int value) => SaveData.Set(index, value);

    public void menuitem(int index, string label, Action callback)
        => Menu.SetItem(index, label, callback);

    public void menuitem(int index)
        => Menu.ClearItem(index);
}
