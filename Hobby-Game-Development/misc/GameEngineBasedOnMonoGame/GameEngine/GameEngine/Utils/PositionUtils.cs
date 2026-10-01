using Microsoft.Xna.Framework;
using System.Collections.Generic;

namespace GameEngine.Utils;

public static class PositionUtils
{
    public static List<Vector2> GetPointsAlongLine(Vector2 start, Vector2 end, int stepSize)
    {
        var points = new List<Vector2>();

        var direction = end - start;
        float length = direction.Length();
        direction.Normalize();

        for (float distance = 0; distance <= length; distance += stepSize)
        {
            Vector2 currentPoint = start + direction * distance;
            points.Add(currentPoint);
        }

        return points;
    }
}
