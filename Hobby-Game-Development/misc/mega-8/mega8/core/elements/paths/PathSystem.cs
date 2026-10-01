namespace mega8.core.elements.paths;

/// <summary>
/// Owns and updates every active <see cref="PathObj"/>.
/// Updated once per frame by <c>LuaBinding.UpdateObjects</c>.
/// </summary>
public class PathSystem
{
    private readonly Dictionary<int, PathObj> _paths = new();

    // ── Lifecycle ────────────────────────────────────────────────────────

    public void Update(float dt)
    {
        foreach (var id in _paths.Keys.ToList())
        {
            var p = _paths[id];
            p.Update(dt);
            _paths[id] = p;
        }
    }

    public void Clear() => _paths.Clear();

    // ── CRUD ─────────────────────────────────────────────────────────────

    public void Set(int id, PathObj path) => _paths[id] = path;

    public bool TryGet(int id, out PathObj path) => _paths.TryGetValue(id, out path);

    public bool Contains(int id) => _paths.ContainsKey(id);

    // ── Controls ─────────────────────────────────────────────────────────

    public void Pause(int id)
    {
        if (!_paths.TryGetValue(id, out var p)) return;
        p.Paused = true;
        _paths[id] = p;
    }

    public void Resume(int id)
    {
        if (!_paths.TryGetValue(id, out var p)) return;
        p.Paused = false;
        _paths[id] = p;
    }

    public void Restart(int id)
    {
        if (!_paths.TryGetValue(id, out var p)) return;
        p.Elapsed = 0f;
        p.Direction = 1;
        p.IsComplete = false;
        p.Paused = false;
        p.Evaluate();
        _paths[id] = p;
    }

    /// <param name="normalized">Progress in [0, 1].</param>
    public void SetPosition(int id, float normalized)
    {
        if (!_paths.TryGetValue(id, out var p)) return;
        p.Elapsed = Math.Clamp(normalized, 0f, 1f) * p.Duration;
        p.IsComplete = false;
        p.Evaluate();
        _paths[id] = p;
    }

    public float GetProgress(int id)
    {
        if (!_paths.TryGetValue(id, out var p) || p.Duration <= 0f) return 0f;
        return Math.Clamp(p.Elapsed / p.Duration, 0f, 1f);
    }
}