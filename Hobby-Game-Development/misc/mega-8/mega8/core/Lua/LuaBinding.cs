namespace mega8.core.lua;

internal class LuaBinding
{
    private static NLua.Lua _lua;
    private static SfxEngine _sfxEngine = new SfxEngine();
    public static SpriteSheet SpriteSheet = new SpriteSheet();
    public static ParticleSystem ParticleSystem = new ParticleSystem();
    private static Dictionary<int, Tween> _tweens = new();
    private static PathSystem _pathSystem = new();
    private static Dictionary<string, Scene> _scenes = new Dictionary<string, Scene>();
    public static Dictionary<string, Entity> Entities = new Dictionary<string, Entity>();
    private static string _currentScene = string.Empty;

    public LuaBinding()
    {
        _sfxEngine.LoadSfxs(FileIO.SplitData(FileIO.Read(Constants.File.Name, Constants.File.Extensions.Sfx)));
        SpriteSheet.LoadSprites(FileIO.SplitData(FileIO.Read(Constants.File.Name, Constants.File.Extensions.SpriteSheet)));
        _lua = new NLua.Lua();

        // sfx
        _lua.RegisterFunction("sfx", this, GetType().GetMethod(nameof(Sfx)));

        // input
        _lua.RegisterFunction("btn", this, GetType().GetMethod(nameof(LuaBtn)));
        _lua.RegisterFunction("btnp", this, GetType().GetMethod(nameof(LuaBtnp)));
        _lua.RegisterFunction("btnr", this, GetType().GetMethod(nameof(LuaBtnr)));

        // Mouse
        _lua.RegisterFunction("mouseup", this, GetType().GetMethod(nameof(LuaMouseScrollUp)));
        _lua.RegisterFunction("mousedown", this, GetType().GetMethod(nameof(LuaMouseScrollDown)));
        _lua.RegisterFunction("mouselp", this, GetType().GetMethod(nameof(LuaMouseLeftJustPressed)));
        _lua.RegisterFunction("mouselr", this, GetType().GetMethod(nameof(LuaMouseLeftReleased)));
        _lua.RegisterFunction("mousel", this, GetType().GetMethod(nameof(LuaMouseLeftPressed)));
        _lua.RegisterFunction("mouserp", this, GetType().GetMethod(nameof(LuaMouseRightJustPressed)));
        _lua.RegisterFunction("mouserr", this, GetType().GetMethod(nameof(LuaMouseRightReleased)));
        _lua.RegisterFunction("mouser", this, GetType().GetMethod(nameof(LuaMouseRightPressed)));
        _lua.RegisterFunction("mousexy", this, GetType().GetMethod(nameof(LuaMousePos)));

        // Scenes
        _lua.RegisterFunction("scene_exists", this, GetType().GetMethod(nameof(SceneExists)));
        _lua.RegisterFunction("scene_create", this, GetType().GetMethod(nameof(SceneCreate)));
        _lua.RegisterFunction("scene_destroy", this, GetType().GetMethod(nameof(SceneDestroy)));
        _lua.RegisterFunction("scene_set", this, GetType().GetMethod(nameof(SceneSet)));
        _lua.RegisterFunction("scene_current", this, GetType().GetMethod(nameof(SceneCurrent)));

        // Entities
        _lua.RegisterFunction("entity_exists", this, GetType().GetMethod(nameof(EntityExists)));
        _lua.RegisterFunction("entity_create", this, GetType().GetMethod(nameof(EntityCreate)));
        _lua.RegisterFunction("entity_change_color", this, GetType().GetMethod(nameof(EntityChangeColor)));
        _lua.RegisterFunction("entity_destroy", this, GetType().GetMethod(nameof(EntityDestroy)));

        // Scene Entities
        _lua.RegisterFunction("scene_attach_entity", this, GetType().GetMethod(nameof(SceneAttachEntity)));
        _lua.RegisterFunction("scene_detach_entity", this, GetType().GetMethod(nameof(SceneDetachEntity)));

        // Entity Elements
        _lua.RegisterFunction("entity_set_activeelements", this, GetType().GetMethod(nameof(SetActiveElements)));
        _lua.RegisterFunction("entity_set_pixel", this, GetType().GetMethod(nameof(EntitySetPixel)));
        _lua.RegisterFunction("entity_set_sprite", this, GetType().GetMethod(nameof(EntitySetSprite)));
        _lua.RegisterFunction("entity_remove_element", this, GetType().GetMethod(nameof(EntityRemoveElement)));

        // Entity Animations
        _lua.RegisterFunction("entity_create_anim", this, GetType().GetMethod(nameof(EntityCreateAnimation)));
        _lua.RegisterFunction("entity_set_rectanim", this, GetType().GetMethod(nameof(EntitySetRectAnimation)));

        // Particles
        _lua.RegisterFunction("part", this, GetType().GetMethod(nameof(Part)));

        // Tweens
        _lua.RegisterFunction("tween", this, GetType().GetMethod(nameof(LuaTween)));

        // Paths
        _lua.RegisterFunction("path",          this, GetType().GetMethod(nameof(LuaPath)));
        _lua.RegisterFunction("path_pause",    this, GetType().GetMethod(nameof(LuaPathPause)));
        _lua.RegisterFunction("path_resume",   this, GetType().GetMethod(nameof(LuaPathResume)));
        _lua.RegisterFunction("path_restart",  this, GetType().GetMethod(nameof(LuaPathRestart)));
        _lua.RegisterFunction("path_position", this, GetType().GetMethod(nameof(LuaPathSetPosition)));
        _lua.RegisterFunction("path_progress", this, GetType().GetMethod(nameof(LuaPathProgress)));

        // Palette
        _lua.RegisterFunction("pal", this, GetType().GetMethod(nameof(SetColorSwap)));

        try
        {
            _lua.DoFile(FileIO.BuildPath(Constants.File.Main, Constants.File.Extensions.Lua, string.Empty));
        }
        catch (NLua.Exceptions.LuaScriptException ex) { LuaError.SetError(ex); }
        catch (Exception) { LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE); }

        if (LuaError.HasError()) return;

        try
        {
            _lua.GetFunction("_init")?.Call();
        }
        catch (NLua.Exceptions.LuaScriptException ex) { LuaError.SetError(ex); }
        catch (Exception) { LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE); }
    }

    public void Update(GameTime gameTime)
    {
        if (LuaError.HasError()) return;

        try
        {
            _lua.GetFunction("_update")?.Call();
            UpdateObjects(gameTime);
        }
        catch (NLua.Exceptions.LuaScriptException ex) { LuaError.SetError(ex); }
        catch (Exception) { LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE); }
    }

    private static void UpdateObjects(GameTime gameTime)
    {
        float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        foreach (var id in _tweens.Keys.ToList())          
        {
            var tw = _tweens[id];
            if (!tw.IsComplete)
            {
                tw.Update(dt);
                _tweens[id] = tw;
            }            
        }

        _pathSystem.Update(dt);
        ParticleSystem.Update(dt);

        foreach (var scene in _scenes.Values)
            scene.Update(gameTime);

        foreach (var entity in Entities.Values)
        {
            foreach (var element in entity.Elements)
            {
                if (element != null && element.IsAnimation)
                    element.Update(gameTime);
            }
        }
    }

    public void Draw()
    {
        if (LuaError.HasError())
        {
            LuaError.Draw();
            return;
        }

        try
        {
            if (_scenes.TryGetValue(_currentScene, out var scene))
                scene.Draw();
        }
        catch (Exception ex) { 
            LuaError.SetError(Constants.Error.UNKWONERRORMESSAGE);
        }
    }

    #region sfx
    public static void Sfx(int index, int channel = -1, int offset = 0, int length = -1)
        => _sfxEngine.Sfx(index, channel, offset, length);
    #endregion

    #region input
    public static bool LuaBtn(int index) => ButtonInput.Pressed(index);
    public static bool LuaBtnp(int index) => ButtonInput.JustPressed(index);
    public static bool LuaBtnr(int index) => ButtonInput.Released(index);

    // Mouse
    public static bool LuaMouseScrollUp() => MouseInputBinding.ScrollUp();
    public static bool LuaMouseScrollDown() => MouseInputBinding.ScrollDown();
    public static bool LuaMouseLeftJustPressed() => MouseInputBinding.LeftJustPressed();
    public static bool LuaMouseLeftReleased() => MouseInputBinding.LeftReleased();
    public static bool LuaMouseLeftPressed() => MouseInputBinding.LeftPressed();
    public static bool LuaMouseRightJustPressed() => MouseInputBinding.RightJustPressed();
    public static bool LuaMouseRightReleased() => MouseInputBinding.RightReleased();
    public static bool LuaMouseRightPressed() => MouseInputBinding.RightPressed();

    public static LuaTable LuaMousePos()
    {
        var mousepos = MouseInputBinding.PosXY();
        LuaTable table = _lua.DoString("return {}")[0] as LuaTable;
        table["x"] = mousepos.X;
        table["y"] = mousepos.Y;

        return table;
    }
    #endregion

    #region Scenes
    public static bool SceneExists(string name) => _scenes.ContainsKey(name);

    public static void SceneCreate(string name)
    {
        if (!string.IsNullOrWhiteSpace(name) && !_scenes.ContainsKey(name))
            _scenes[name] = new Scene();
    }

    public static void SceneDestroy(string name)
    {
        if (string.IsNullOrWhiteSpace(name)) return;
        _scenes.Remove(name);
        if (_currentScene == name) _currentScene = string.Empty;
    }

    public static void SceneSet(string name)
    {
        if (_currentScene != name)
        {
            ClearElements();
        }

        if (_scenes.ContainsKey(_currentScene))
        {
            _scenes[_currentScene]?.Pause();
        }

        if (_scenes.ContainsKey(name))
        {
            _currentScene = name;
            _scenes[_currentScene].Resume();
        }
    }

    public static string SceneCurrent() => _currentScene;
    #endregion

    #region Entities
    public static bool EntityExists(string id)
        => !string.IsNullOrWhiteSpace(id) && Entities.ContainsKey(id);

    public void SetActiveElements(string id, int activeElements)
    {
        if (!string.IsNullOrWhiteSpace(id)) Entities[id].SetActiveElements(activeElements);
    }

    public void SetFlags(string id, int flags)
    {
        if (!string.IsNullOrWhiteSpace(id)) Entities[id].SetFlags(flags);
    }

    public void SetCollisionFlags(string id, int collideWithFlags)
    {
        if (!string.IsNullOrWhiteSpace(id)) Entities[id].SetCollisionFlags(collideWithFlags);
    }

    public static void EntityCreate(string id, int x, int y, int zIndex = 0)
    {
        if (!string.IsNullOrWhiteSpace(id) && !Entities.ContainsKey(id))
            Entities[id] = new Entity(x, y, zIndex);
    }

    public static void EntityChangeColor(string id, int ci, int cj)
    {
        if (EntityExists(id)) Entities[id].SwapColorIndex(ci, cj);
    }    

    public static void EntityDestroy(string id)
    {
        if (EntityExists(id)) Entities.Remove(id);
    }
    #endregion

    #region Scene Entities
    public static void SceneAttachEntity(string sceneName, string entityId)
    {
        if (_scenes.TryGetValue(sceneName, out var scene) && Entities.ContainsKey(entityId))
            scene.AttachEntity(entityId);
    }

    public static void SceneDetachEntity(string sceneName, string entityId)
    {
        if (_scenes.TryGetValue(sceneName, out var scene) && Entities.ContainsKey(entityId))
            scene.DetachEntity(entityId);
    }
    #endregion

    #region Entity Elements
    public static bool ElementExists(string entityId, int elementId)
        => EntityExists(entityId) && Entities[entityId].Elements[elementId] != null;

    public static void EntitySetPixel(string entityId, int elementId,
        int x, int y, int colorIndex = 1, int zIndex = 0)
    {
        if (EntityExists(entityId))
            Entities[entityId].SetElement(elementId, new PixelElement(x, y, colorIndex, zIndex));
    }

    public static void EntitySetSprite(string entityId, int elementId,
        int spriteIndex, int x, int y, int zIndex, int scale = 1, int w = 1, int h = 1, bool flipX = false, bool flipY = false)
    {
        if (EntityExists(entityId))
            Entities[entityId].SetElement(elementId, new SpriteElement(spriteIndex, x, y, zIndex, scale, w, h, flipX, flipY));
    }    

    public static void EntityRemoveElement(string entityId, int elementId)
    {
        if (EntityExists(entityId)) Entities[entityId].RemoveElement(elementId);
    }

    public static void EntityCreateAnimation(string entityId, int elementId,
        int zIndex = 0, bool paused = false, float speed = 8f)
    {
        if (EntityExists(entityId))
            Entities[entityId].SetElement(elementId, new AnimationElement(zIndex, paused, speed));
    }

    public static void EntitySetRectAnimation(string entityId, int elementId,
        bool fill, int x, int y, int w, int h, int colorIndex = 1)
    {
        if (!ElementExists(entityId, elementId)) return;

        var element = Entities[entityId].Elements[elementId];
        if (element.IsAnimation)
            ((AnimationElement)element).AddRectFrame(fill, x, y, w, h, colorIndex);
    }
    #endregion

    #region Palette
    public static void SetColorSwap(string colorSwap = "")
    {
        ColorPalette.SetColorSwap(colorSwap);
    }
    #endregion

    #region Particles

    /// <summary>
    /// Lua: part(x, y, ttl, sprIdx, sprSize, zIndex [, anim] [, movement] [, rotation])
    ///
    /// anim     = { sprIdxs={...}, sprSize={...} }
    /// movement = { vx=0, vy=0, ax=0, ay=0, maxX=0, maxY=0 }
    /// rotation = { angle=0, cx=0, cy=0, av=0, aa=0, maxAv=0 }
    /// </summary>
    public static void Part(
    float x, float y, float ttl,
    int sprIdx, int sprSize,
    int zIndex = 0,
    NLua.LuaTable? anim = null,
    NLua.LuaTable? movement = null,
    NLua.LuaTable? rotation = null)
    {
        if (ttl <= 0f) return;

        var p = new Particle
        {
            X = x,
            Y = y,
            TTL = ttl,
            Age = 0f,
            SprIdx = sprIdx,
            SprSize = sprSize
        };

        if (anim != null)
        {
            p.SprIdxs = ReadIntArray(anim, "sprIdxs", 8);
            p.SprSizeIdxs = ReadIntArray(anim, "sprSizes", 8);
        }

        if (movement != null)
        {
            // Detect array-of-tables: key 1 is a LuaTable
            if (movement[1] is NLua.LuaTable)
            {
                p.VelocityXs = new float[8];
                p.VelocityYs = new float[8];
                p.AccelerationXs = new float[8];
                p.AccelerationYs = new float[8];
                p.MaxSpeedXs = new float[8];
                p.MaxSpeedYs = new float[8];

                for (int i = 0; i < 8; i++)
                {
                    var m = movement[i + 1] as NLua.LuaTable;
                    if (m == null) continue;
                    p.VelocityXs[i] = ReadFloat(m, "vx");
                    p.VelocityYs[i] = ReadFloat(m, "vy");
                    p.AccelerationXs[i] = ReadFloat(m, "ax");
                    p.AccelerationYs[i] = ReadFloat(m, "ay");
                    p.MaxSpeedXs[i] = ReadFloat(m, "maxX");
                    p.MaxSpeedYs[i] = ReadFloat(m, "maxY");
                }

                // seed scalar from frame 0 so movement starts correctly
                p.VelocityX = p.VelocityXs[0];
                p.VelocityY = p.VelocityYs[0];
            }
            else
            {
                p.VelocityX = ReadFloat(movement, "vx");
                p.VelocityY = ReadFloat(movement, "vy");
                p.AccelerationX = ReadFloat(movement, "ax");
                p.AccelerationY = ReadFloat(movement, "ay");
                p.MaxSpeedX = ReadFloat(movement, "maxX");
                p.MaxSpeedY = ReadFloat(movement, "maxY");
            }
        }

        if (rotation != null)
        {
            if (rotation[1] is NLua.LuaTable)
            {
                p.Angles = new float[8];
                p.RotationCenterXs = new float[8];
                p.RotationCenterYs = new float[8];
                p.AngularVelocities = new float[8];
                p.AngularAccelerations = new float[8];
                p.MaxAngularSpeeds = new float[8];

                for (int i = 0; i < 8; i++)
                {
                    var r = rotation[i + 1] as NLua.LuaTable;
                    if (r == null) continue;
                    p.Angles[i] = ReadFloat(r, "angle");
                    p.RotationCenterXs[i] = ReadFloat(r, "cx");
                    p.RotationCenterYs[i] = ReadFloat(r, "cy");
                    p.AngularVelocities[i] = ReadFloat(r, "av");
                    p.AngularAccelerations[i] = ReadFloat(r, "aa");
                    p.MaxAngularSpeeds[i] = ReadFloat(r, "maxAv");
                }

                p.Angle = p.Angles[0];
                p.AngularVelocity = p.AngularVelocities[0];
            }
            else
            {
                p.Angle = ReadFloat(rotation, "angle");
                p.RotationCenterX = ReadFloat(rotation, "cx");
                p.RotationCenterY = ReadFloat(rotation, "cy");
                p.AngularVelocity = ReadFloat(rotation, "av");
                p.AngularAcceleration = ReadFloat(rotation, "aa");
                p.MaxAngularSpeed = ReadFloat(rotation, "maxAv");
            }
        }

        ParticleSystem.Emit(in p, zIndex);
    }

    // ── Lua table helpers ────────────────────────────────────────────────

    private static float ReadFloat(NLua.LuaTable t, string key, float fallback = 0f)
    {
        var v = t[key];
        return v is double d ? (float)d
             : v is float f ? f
             : v is long l ? (float)l
             : fallback;
    }

    private static int[] ReadIntArray(NLua.LuaTable t, string key, int expectedLen)
    {
        var result = new int[expectedLen];
        if (t[key] is not NLua.LuaTable sub) return result;

        for (int i = 0; i < expectedLen; i++)
        {
            var v = sub[i + 1]; // Lua is 1-indexed
            result[i] = v is double d ? (int)d
                       : v is long l ? (int)l
                       : 0;
        }

        return result;
    }

    #endregion

    #region Tweens

    /// <summary>
    /// Lua: tween(id)                              → returns current value (no-op if missing)
    /// Lua: tween(id, value, target, duration, easing) → creates/resets tween, returns current value
    /// </summary>
    public static LuaTable LuaTween(
        int id,
        object? from = null,
        object? to = null,
        object? duration = null,
        object? easing = null)
    {
        LuaTable table = _lua.DoString("return {}")[0] as LuaTable;
        // Read-only call: tween(id)
        if (from == null)
        {
            if (_tweens.ContainsKey(id))
            {
                table["value"] = _tweens[id].Value;
                table["complete"] = _tweens[id].IsComplete;
                return table;
            }            

            table["value"] = 0f;
            table["complete"] = false;
            return table;
        }

        // Create / reset call: tween(id, value, target, duration, easing)
        float f = ToFloat(from);
        float t = ToFloat(to);
        float dur = ToFloat(duration);
        int eas = ToInt(easing);

        var tw = new Tween
        {
            From = f,
            To = t,
            Duration = dur,
            Elapsed = 0f,
            Easing = eas,
            Value = f          // start at From immediately
        };

        if (_tweens.ContainsKey(id))
        {
            _tweens[id] = tw;
        }
        else
        {
            _tweens.Add(id,tw);
        }

        table["value"] = _tweens[id].Value;
        table["complete"] = _tweens[id].IsComplete;
        return table;
    }

    // Helpers for nullable object → numeric (NLua passes numbers as double/long)
    private static float ToFloat(object? v) => v switch
    {
        double d => (float)d,
        float f => f,
        long l => (float)l,
        int i => (float)i,
        _ => 0f
    };

    private static int ToInt(object? v) => v switch
    {
        double d => (int)d,
        long l => (int)l,
        int i => i,
        _ => 0
    };
    #endregion

    #region Paths

    /// <summary>
    /// Lua: path(pathid)                                      → {x, y}   read-only
    /// Lua: path(pathid, points, duration, easing, loop, pingpong, shape) → {x, y}   create/update
    ///
    /// points = { {x=0,y=0}, {x=50,y=0}, ... }
    /// </summary>
    public static LuaTable LuaPath(
        int id,
        NLua.LuaTable? points = null,
        object? duration = null,
        object? easing = null,
        object? loop = null,
        object? pingpong = null,
        object? shape = null)
    {
        // ── Read-only call: path(id) ─────────────────────────────────────
        if (points == null)
        {
            LuaTable tbl = MakeLuaTable();
            if (_pathSystem.TryGet(id, out var existing))
            {
                tbl["x"] = existing.X;
                tbl["y"] = existing.Y;
                tbl["complete"] = existing.IsComplete;
            }
            else
            {
                tbl["x"] = 0f;
                tbl["y"] = 0f;
                tbl["complete"] = false;
            }
            return tbl;
        }

        // ── Create / update call ─────────────────────────────────────────
        var pts = ReadPointsArray(points);
        if (pts.Length < 2)
        {
            LuaTable tbl = MakeLuaTable();
            tbl["x"] = pts.Length == 1 ? pts[0].X : 0f;
            tbl["y"] = pts.Length == 1 ? pts[0].Y : 0f;
            tbl["complete"] = true;
            return tbl;
        }

        // Preserve state if path already exists (keep elapsed/direction)
        PathObj p;
        bool isNew = !_pathSystem.TryGet(id, out p);

        p.Points = pts;
        p.Duration = ToFloat(duration);
        p.Easing = ToInt(easing);
        p.Loop = ToBool(loop);
        p.PingPong = ToBool(pingpong);
        p.Shape = ToInt(shape);

        if (isNew)
        {
            p.Elapsed = 0f;
            p.Direction = 1;
            p.IsComplete = false;
            p.Paused = false;
        }

        p.Evaluate();
        _pathSystem.Set(id, p);

        LuaTable result = MakeLuaTable();
        result["x"] = p.X;
        result["y"] = p.Y;
        result["complete"] = p.IsComplete;
        return result;
    }

    public static void LuaPathPause(int id) => _pathSystem.Pause(id);
    public static void LuaPathResume(int id) => _pathSystem.Resume(id);
    public static void LuaPathRestart(int id) => _pathSystem.Restart(id);

    public static void LuaPathSetPosition(int id, object? normalized)
        => _pathSystem.SetPosition(id, ToFloat(normalized));

    public static LuaTable LuaPathProgress(int id)
    {
        LuaTable tbl = MakeLuaTable();
        tbl["progress"] = _pathSystem.GetProgress(id);
        return tbl;
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private static LuaTable MakeLuaTable()
        => _lua.DoString("return {}")[0] as LuaTable;

    private static bool ToBool(object? v) => v switch
    {
        bool b => b,
        double d => d != 0,
        long l => l != 0,
        _ => false
    };

    private static (float X, float Y)[] ReadPointsArray(NLua.LuaTable t)
    {
        var list = new System.Collections.Generic.List<(float, float)>();
        for (int i = 1; ; i++)
        {
            if (t[i] is not NLua.LuaTable pt) break;
            list.Add((ReadFloat(pt, "x"), ReadFloat(pt, "y")));
        }
        return list.ToArray();
    }
    #endregion

    public void StopSounds() => _sfxEngine.Sfx(-1);

    public void Unload()
    {
        StopSounds();
        _sfxEngine.Dispose();
        ClearElements();
    }

    private static void ClearElements()
    {
        ParticleSystem.Clear();
        _pathSystem.Clear();
    }
}