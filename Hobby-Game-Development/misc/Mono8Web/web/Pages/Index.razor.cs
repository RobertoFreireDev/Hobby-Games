using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.JSInterop;
using Microsoft.Xna.Framework;

namespace web.Pages
{
    public partial class Index
    {
        // Data files the Mono8 editor/engine reads (and writes back) via FileIO, which resolves
        // paths against Directory.GetCurrentDirectory()/data. data.mono8 is the whole cartridge
        // (gfx/gff/atl/map/sfx/music) in one sectioned file; data.icons (built-in) and data.save
        // (dget/dset store) stay separate.
        static readonly string[] DataFiles =
        {
            "data.mono8", "data.icons", "data.save",
        };

        mono8.Mono8Game _game;
        bool _dataReady;

        // True while the JS Ace overlay is editing the Lua source. The engine tick is paused so
        // keystrokes typed into Ace don't leak into the engine's global keyboard shortcuts (KNI
        // listens for keys window-wide).
        bool _aceOpen;

        // Set while a cartridge file picker is open; invoked with the file's text once JS reads it.
        Action<string> _pendingImport;

        // Invoked once a cart Save/Load dialog is dismissed (saved, loaded, or cancelled) so the engine
        // can lift its "busy" overlay and resume. See ExportCart/ImportCart and the OnCart* callbacks.
        Action _pendingExportDone;
        Action _pendingImportDone;

        protected override async Task OnAfterRenderAsync(bool firstRender)
        {
            await base.OnAfterRenderAsync(firstRender);

            if (!firstRender)
                return;

            // Mirror every engine write into localStorage so edits survive a page reload (MEMFS is
            // wiped on reload). Wire this before seeding so the game's own writes are captured too.
            mono8.core.common.FileIO.OnWrite = Persist;

            // Wire the menu-bar Save/Load buttons to the browser's file dialogs (download for save,
            // file picker for load). Desktop leaves these null; the buttons no-op there.
            mono8.core.common.CartIO.OnExport = ExportCart;
            mono8.core.common.CartIO.OnImport = ImportCart;

            // Seed the WASM in-memory filesystem before the game reads it.
            SeedData();

            // Match the engine's output rate to the browser's AudioContext rate, which
            // KNI's BlazorGL audio backend requires (it rejects a mismatched rate).
            try
            {
                var rate = await JsRuntime.InvokeAsync<int>("getAudioSampleRate");
                if (rate > 0)
                    mono8.core.sfx.AudioSettings.SampleRate = rate;
            }
            catch
            {
                // Fall back to the engine default if the query fails.
            }

            _dataReady = true;

            await JsRuntime.InvokeAsync<object>("initRenderJS", DotNetObjectReference.Create(this));
        }

        // Unpack the data files into the working directory the game reads from. A file previously
        // saved by the user (persisted to localStorage) wins over the embedded default, so edits
        // survive reloads; otherwise fall back to the embedded resource. MEMFS supports synchronous
        // file IO, so FileIO.Read/Write just work afterwards.
        void SeedData()
        {
            var asm = typeof(mono8.Mono8Game).Assembly;
            var dir = Path.Combine(Directory.GetCurrentDirectory(), "data");
            Directory.CreateDirectory(dir);

            foreach (var file in DataFiles)
            {
                var dstPath = Path.Combine(dir, file);

                var saved = Load(file);
                if (saved != null)
                {
                    File.WriteAllText(dstPath, saved);
                    continue;
                }

                using var src = asm.GetManifestResourceStream(file);
                if (src == null)
                    continue; // engine treats absent data as empty

                using var dst = File.Create(dstPath);
                src.CopyTo(dst);
            }
        }

        // Synchronous localStorage bridge (WASM is single-threaded, so IJSInProcessRuntime is safe).
        void Persist(string name, string content)
        {
            if (JsRuntime is IJSInProcessRuntime js)
                js.InvokeVoid("mono8Persist", name, content);
        }

        string Load(string name)
        {
            if (JsRuntime is IJSInProcessRuntime js)
                return js.Invoke<string>("mono8Load", name);
            return null;
        }

        // Menu-bar Save: offer the cartridge text to the browser's "save as" dialog / download. JS calls
        // OnCartSaved back once the dialog is dismissed (saved or cancelled) so the busy overlay clears.
        void ExportCart(string fileName, string content, Action onDone)
        {
            _pendingExportDone = onDone;
            if (JsRuntime is IJSInProcessRuntime js)
                js.InvokeVoid("mono8SaveFile", fileName, content);
        }

        // Menu-bar Load: open the browser file picker; JS calls OnCartLoaded with the file text (or
        // OnCartImportCancelled if dismissed). Either way onDone runs, clearing the busy overlay.
        void ImportCart(Action<string> apply, Action onDone)
        {
            _pendingImport = apply;
            _pendingImportDone = onDone;
            if (JsRuntime is IJSInProcessRuntime js)
                js.InvokeVoid("mono8OpenFile");
        }

        [JSInvokable]
        public void OnCartSaved()
        {
            var done = _pendingExportDone;
            _pendingExportDone = null;
            done?.Invoke();
        }

        [JSInvokable]
        public void OnCartLoaded(string content)
        {
            var apply = _pendingImport;
            _pendingImport = null;
            apply?.Invoke(content);
            FinishImport();
        }

        [JSInvokable]
        public void OnCartImportCancelled()
        {
            _pendingImport = null;
            FinishImport();
        }

        void FinishImport()
        {
            var done = _pendingImportDone;
            _pendingImportDone = null;
            done?.Invoke();
        }

        // The Ace overlay reads the current Lua source, commits edits back, and reports its open
        // state through these. LuaSheet is the same model the editors already use, so a commit here
        // is picked up by a subsequent run (Ctrl+R) and by the menu-bar Save button.
        [JSInvokable]
        public string GetLuaCode() => mono8.Mono8API.LuaSheet.Code;

        [JSInvokable]
        public void CommitLuaCode(string code) => mono8.Mono8API.LuaSheet.SetCode(code ?? string.Empty);

        [JSInvokable]
        public void SetAceOpen(bool open) => _aceOpen = open;

        // The Esc state cycle (editor -> game -> Lua code editor) is driven from JS on the web head,
        // because while Ace is open the engine tick is paused and can't see Esc, and the browser's
        // window-wide keydown listener owns the key. JS calls these to run and stop the game (the
        // Lua-editor step is the Ace overlay itself). See the Esc handler in index.html.
        [JSInvokable]
        public void RunGame() => mono8.Mono8Game.GameAPI?.RunGame();

        [JSInvokable]
        public void StopGame() => mono8.Mono8Game.GameAPI?.StopGame();

        [JSInvokable]
        public void TickDotNet()
        {
            if (!_dataReady)
                return;

            // init game
            if (_game == null)
            {
                try
                {
                    _game = new mono8.Mono8Game();
                    _game.Run();
                }
                catch (Exception ex)
                {
                    // Surface the real (inner) cause in the browser console instead of the
                    // opaque "type initializer threw" wrapper.
                    Console.WriteLine("Mono8 init failed: " + ex);
                    throw;
                }
            }

            // Pause the engine while the Lua code editor is open so typed keys don't trigger engine
            // shortcuts underneath. The overlay covers the (frozen) canvas, so this is invisible.
            if (_aceOpen)
                return;

            // run gameloop
            _game.Tick();
        }

        // The JS resize handler already resized the canvas backbuffer; ask the engine to re-derive
        // its render resolution and letterbox from the new canvas size. The dimensions come from JS
        // (in CSS pixels) because KNI's GL viewport does not update when JS sets canvas.width/height,
        // so reading it back here would give a stale size and the resize would be a no-op.
        [JSInvokable]
        public void OnCanvasResized(int width, int height)
        {
            _game?.RecomputeScreen(width, height);
        }
    }
}
