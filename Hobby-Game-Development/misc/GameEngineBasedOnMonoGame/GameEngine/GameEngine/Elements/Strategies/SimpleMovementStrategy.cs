using GameEngine.Elements.Managers;
using GameEngine.GameConstants;
using GameEngine.Utils;
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;

namespace GameEngine.Elements.Strategies;

public class SimpleMovementStrategy : IMovementStrategy
{
    public SpriteObject ThisObject;

    private int _currentState; // 0- far 1- tilemap obstacle  2- found 3 - reached

    public Vector2 _originalPosition;

    public Vector2 _targetPosition;

    private float _minDist;

    private float _maxDist;

    private float _timer;

    public SimpleMovementStrategy(SpriteObject thisObject, float minDist, float maxDist)
    {
        ThisObject = thisObject;
        _originalPosition = thisObject.GetBox().Center.ToVector2();
        _minDist = minDist;
        _maxDist = maxDist;
    }

    public void Update(SpriteObject target, List<SpriteObject> allies, Action action)
    {
        var deltaTime = GlobalManager.DeltaTime;

        if (_currentState == 0)
        {
            _timer += deltaTime;
            _targetPosition = _originalPosition;
            MoveToTarget(deltaTime, target, allies);
        }

        if (_currentState == 2)
        {
            _timer += deltaTime;
            MoveToTarget(deltaTime, target, allies);
            return;
        }

        if (_currentState == 3)
        {
            _timer += deltaTime;
            if (_timer > 0.2f)
            {
                _currentState = 0;
            }
            action();
            return;
        }

        _timer = 0f;
        _currentState = FindTarget(target);
    }

    private bool IsObstacleBetween(Vector2 start, Vector2 end, int stepSize, Func<Vector2, bool> obstacleCheck)
    {
        var positionsToTarget = PositionUtils.GetPointsAlongLine(start, end, stepSize);
        foreach (var point in positionsToTarget)
        {
            if (obstacleCheck(point))
            {
                return true;
            }
        }

        return false;
    }

    private int FindTarget(SpriteObject target, Vector2? positionToCompare = null)
    {
        var targetCenter = target.GetBox().Center.ToVector2();
        var thisObjectCenter = ThisObject.GetBox().Center.ToVector2();
        var distance = Vector2.Distance(targetCenter, thisObjectCenter);

        if (distance < _minDist)
        {
            return 3;
        }

        if (distance > _maxDist)
        {
            return 0;
        }

        if (IsObstacleBetween(thisObjectCenter, targetCenter, 4, CheckForObstacle))
        {
            return 1;
        }

        if (positionToCompare is not null)
        {
            var distanceToNewPosition = Vector2.Distance(targetCenter, (Vector2)positionToCompare);
            if (distanceToNewPosition < 40f)
            {
                return 2;
            }
        }

        _targetPosition = targetCenter;
        return 2;
    }

    private bool CheckForObstacle(Vector2 position)
    {
        return TileMapManager.IsCollidingWith(position);
    }

    private void MoveToTarget(float elapsedTime, SpriteObject target, List<SpriteObject> allies)
    {
        if (_timer > 0.5f)
        {
            _timer = 0f;

            if (FindTarget(target, _targetPosition) == 3)
            {
                _currentState = 3;
                return;
            }
        }
        UpdatePosition(elapsedTime, target, allies);
    }


    private void UpdatePosition(float elapsedTime, SpriteObject target, List<SpriteObject> allies)
    {
        var direction = _targetPosition - ThisObject.GetBox().Center.ToVector2();
        direction.Normalize();
        direction = direction * ThisObject.Speed * elapsedTime * Constants.Config.SixtyFrames;

        if (direction.X is float.NaN || direction.Y is float.NaN)
        {
            _timer = 0f;
            _currentState = 0;
            return;
        }

        var tempX = ThisObject.Position.X;
        var tempY = ThisObject.Position.Y;

        ThisObject.Position.X += direction.X;

        if (DetectCollisionWithTarget(target) || TileMapManager.IsCollidingWith(ThisObject.GetBox()) || DetectCollisionWithAllies(allies))
        {
            ThisObject.Position.X = tempX;
        }

        ThisObject.Position.Y += direction.Y;

        if (DetectCollisionWithTarget(target) || TileMapManager.IsCollidingWith(ThisObject.GetBox()) || DetectCollisionWithAllies(allies))
        {
            ThisObject.Position.Y = tempY;
        }

        if (tempX == ThisObject.Position.X && tempY == ThisObject.Position.Y)
        {
            _currentState = 0;
            return;
        }
    }

    private bool DetectCollisionWithTarget(SpriteObject target)
    {
        return ThisObject.GetBox().Intersects(target.GetBox());
    }

    private bool DetectCollisionWithAllies(List<SpriteObject> allies)
    {
        foreach (var ally in allies)
        {
            if (ally != ThisObject && ThisObject.GetBox().Intersects(ally.GetBox()))
            {
                return true;
            }
        }

        return false;
    }
}
