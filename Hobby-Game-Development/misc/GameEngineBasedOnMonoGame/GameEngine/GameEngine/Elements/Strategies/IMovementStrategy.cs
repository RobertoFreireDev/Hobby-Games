using System;
using System.Collections.Generic;

namespace GameEngine.Elements.Strategies;

public interface IMovementStrategy
{
    public void Update(SpriteObject target, List<SpriteObject> allies, Action action);
}
