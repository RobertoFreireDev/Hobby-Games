# Publishing Mono8 Web to itch.io

How to turn the [`web/`](web/) head into a zip itch.io can run as an HTML5 game in the browser.

Everything below is already wired in the repo — no code changes are needed to publish. The steps are
just: **publish → prune → zip → upload → configure the itch page**.

---

## 1. Publish a Release build

From the repository root:

```powershell
dotnet publish web/web.csproj -c Release -o publish
```

The uploadable site is **`publish/wwwroot/`** — *not* `publish/`. The extra files next to it
(`web.config`, `emcc-props.json`, `web.staticwebassets.endpoints.json`) are host/server metadata that
itch.io ignores; do not put them in the zip.

`publish/wwwroot/` looks like this:

```
index.html          <- must end up at the ROOT of the zip
favicon.ico
kni.png
web.styles.css
_framework/         <- .NET runtime + all assemblies (~19 MB, the bulk of the download)
_content/           <- nkast.Wasm JS interop scripts
lib/                <- vendored Ace editor + DepartureMono font
css/  js/  Content/
```

The cartridge is **not** a loose file here. `data.mono8`, `data.icons` and `data.save` are embedded as
resources into the assembly at build time (see `<EmbeddedResource>` in
[web/web.csproj](web/web.csproj)) and seeded into the WASM in-memory filesystem on boot. So the
version of the cart you publish is whatever is in [src/data/](src/data/) **at the moment you run
`dotnet publish`** — save your work from the editor into `src/data/data.mono8` first.

## 2. Prune what itch.io can't use

The publish output ships three copies of every assembly: the raw file plus `.br` (Brotli) and `.gz`
precompressed siblings, for servers that can do content negotiation. itch.io can't, and the Blazor
boot loader in [web/wwwroot/index.html](web/wwwroot/index.html) requests the **uncompressed** files
(`enableBrotliDecompression` is `false`), so the compressed copies are pure dead weight:

| | size |
|---|---|
| `publish/wwwroot` as published | ~20 MB |
| after deleting `*.br` and `*.gz` | **~12 MB** |

```powershell
Get-ChildItem publish/wwwroot -Recurse -Include *.br,*.gz | Remove-Item
```

Optional extra trim (safe, saves ~0.5 MB): delete `css/bootstrap/*.map` — source maps for a
stylesheet no gameplay code uses.

> **Don't** set `enableBrotliDecompression = true` to shrink it further. It would fetch `.br` files
> and decode them in JS, trading ~7 MB of download for a slower, single-threaded startup — and it is
> disabled on `localhost`, so you'd never catch a mistake while testing locally.

## 3. Zip it

Two things must be true: **`index.html` sits at the zip root** (not inside a `wwwroot/` folder), and
**every entry path uses forward slashes**.

> ### ⚠️ Do not use `Compress-Archive` on Windows PowerShell 5.1
>
> It writes entry names with **backslashes** (`css\app.css`), which the ZIP spec forbids — paths must
> use `/`. Local tools tolerate it, but itch.io's extractor reads `css\app.css` as one flat filename,
> so no subdirectory is ever created and **every asset 404s** while `index.html` itself (no separator
> in its name) loads fine. The symptom is a hung loading screen with a console full of
> `GET .../css/app.css 404`, `.../_framework/blazor.webassembly.js 404`, and so on.
>
> `[IO.Compression.ZipFile]::CreateFromDirectory` has the same bug on .NET Framework — it is **not** a
> workaround.

Use the built-in `tar.exe` (bsdtar, shipped with Windows 10/11), which writes spec-correct forward
slashes:

```powershell
Push-Location publish/wwwroot
tar -a -c -f ../../mono8-web.zip *
Pop-Location
```

`-a` picks the format from the `.zip` extension; `*` is expanded by tar itself, so the archive
contains the *contents* of `wwwroot` rather than the folder. Other tools that produce correct zips:
7-Zip, Windows Explorer's "Send to → Compressed (zipped) folder", or `Compress-Archive` under
**PowerShell 7** (`pwsh`) — the bug is specific to the 5.1 build.

Verify before uploading — this is the check that would have caught the problem:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead((Resolve-Path mono8-web.zip))
"backslash entries: " + ($z.Entries.FullName | Where-Object { $_ -like '*\*' }).Count  # must be 0
$z.Entries.FullName -match '^index\.html$'                                             # must match
$z.Dispose()
```

A correct archive of a pruned publish has ~175 file entries, zero backslash entries, and paths that
read `css/app.css`, `lib/ace/ace.js`, `_framework/dotnet.native.wasm`.

## 4. Test the zip locally

itch.io serves the game from a subdirectory of a random `*.ssl.hwcdn.net` origin inside an iframe, so
absolute paths break there but work at `http://localhost:5259/`. Mono8 already uses
`<base href="./" />` in [index.html](web/wwwroot/index.html), which makes every asset request
relative — but verify the actual zip contents, not the dev server, before you upload:

```powershell
Expand-Archive mono8-web.zip -DestinationPath ziptest -Force
dotnet serve -d ziptest      # or: python -m http.server 8080 --directory ziptest
```

Open it and confirm: the engine boots, the menu bar responds to clicks, `Esc` cycles
editor → game → Lua editor, and audio plays after the first click.

## 5. Upload and configure the itch.io page

Create the project (Dashboard → **Create new project**) and set:

| Field | Value |
|---|---|
| **Kind of project** | **HTML** |
| Upload | `mono8-web.zip`, then tick **"This file will be played in the browser"** |
| **Viewport dimensions** | **1280 × 720** (Mono8 is 256×144 — 16:9, so any 16:9 size scales cleanly) |
| **Fullscreen button** | ✅ enable |
| **Mobile friendly** | ❌ leave off — the editors are mouse + keyboard only |
| **Embed options** | "Click to launch in fullscreen" is a good default (see the audio note below) |
| Frame options | leave "Automatically start on page load" off if you prefer the launch button |

Then **Save & view page**.

### Why these settings

- **Fullscreen / launch button.** Browsers create every `AudioContext` suspended and only resume it
  from a user gesture. The engine handles this — [index.html](web/wwwroot/index.html) wraps the
  `AudioContext` constructor and resumes on the first `pointerdown`/`keydown`/`touchstart` — but a
  launch button guarantees that gesture happens before anyone expects sound.
- **Keyboard capture.** Arrow keys, `Space` and the mouse wheel are already `preventDefault`ed in
  [index.html](web/wwwroot/index.html) so they don't scroll the itch page behind the iframe. The
  player still has to **click the canvas once** to give the iframe focus before keys reach the game.
- **16:9 viewport.** [Screen.cs](src/core/graphics/Screen.cs) aspect-fits the 256×144 target with a
  float scale on the browser head and letterboxes the remainder, so a non-16:9 viewport just adds
  black bars — nothing breaks, it's only wasted page space.

## 6. Updating a published game

Re-run steps 1–3 and upload the new zip over the old one on the itch page.

**Gotcha:** on boot the web head restores any `data.*` file the player previously saved from
`localStorage` *in preference to* the embedded default ([Index.razor.cs](web/Pages/Index.razor.cs)
`SeedData`). That's what makes editor edits survive a reload — but it also means a returning player
who ever saved in the editor keeps their old cartridge after you ship an update. `localStorage` is
keyed per origin, and itch's game CDN origin is shared, so you can't clear it for them from the page.
If shipping a new cart matters, tell players to use the menu bar's **Load** button to import the new
`data.mono8`, or reset via their browser's site-data settings.

## Troubleshooting

| Symptom | Cause |
|---|---|
| itch shows "Index file not found" | `index.html` isn't at the zip root — you zipped the `wwwroot` folder instead of its contents. |
| **`index.html` loads but *every* subfolder request 404s** (`css/app.css`, `_framework/blazor.webassembly.js`, `_content/...`, `lib/ace/ace.js`) | The zip has backslash entry paths — made with `Compress-Archive` on PowerShell 5.1. Rebuild the zip with `tar -a -c -f` (see step 3). Nothing is wrong with the build. |
| Blank page, 404s on `_framework/*.wasm` only | `<base href>` was changed away from `./`, or `_framework/` was left out of the zip. |
| Game renders but clicks miss the buttons | The canvas backbuffer and the 256×144 render target are out of sync — check `OnCanvasResized` is still firing (resize the window and watch the console). |
| No sound | The player hasn't clicked/typed inside the iframe yet; the `AudioContext` is still suspended. |
| Very slow first load | Expected: ~12 MB of .NET runtime + assemblies, cached by the browser afterwards. |
| Editor edits vanish on reload | `localStorage` is blocked — some browsers deny storage to third-party iframes. Use the "click to launch in fullscreen" embed, which itch opens as a top-level context. |
