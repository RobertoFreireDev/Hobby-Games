namespace mega8.core.elements;

internal class Scene
{
    private HashSet<string> EntitiesId = new HashSet<string>();
    public bool Paused = false;
    private Counter Counter = new Counter();

    public void Pause()
    {
        Paused = true;
    }

    public void Resume()
    {
        Paused = false;
    }

    public void Update(GameTime game)
    {
        if (Paused) return;

        Counter.Update(game);
    }

    internal void AttachEntity(string entityId)
    {
        EntitiesId.Add(entityId);
    }

    internal void DetachEntity(string entityId)
    {
        EntitiesId.Remove(entityId);
    }

    internal void Draw()
    {
        ColorPalette.BackUpColorSwap();
        var allEntities = LuaBinding.Entities
            .Where(e => EntitiesId.Contains(e.Key))
            .OrderBy(e => e.Value.ZIndex)
            .ToList();

        for (int z = Constants.Scene.ZindexMin; z <= Constants.Scene.ZindexMax; z++)
        {

            foreach (var entity in allEntities)
            {
                if (entity.Value.ZIndex == z)
                {
                    entity.Value.Draw();
                }
            }
            LuaBinding.ParticleSystem.DrawBucket(z);
        }
    }
}
