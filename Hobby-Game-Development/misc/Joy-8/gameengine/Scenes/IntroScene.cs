using gameengine.Data;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;
using System;
using Microsoft.Xna.Framework;
using System.Linq;
using gameengine.Utils;
using gameengine.Utils.Objects;

namespace gameengine.Scenes;

internal class IntroScene : Scene
{
    private Timer _startTimer = new Timer(0.5f);
    private float transparency = 0.0f;
    private float duration = 1.0f;
    private Timer _endTimer = new Timer(3f);

    public IntroScene(SceneManager sceneManager) : base(sceneManager)
    {
    }

    public override void Update()
    {
        _startTimer.Update();
        _endTimer.Update();

        if (!_endTimer.IsActive())
        {
            _sceneManager.ChangeScene(_sceneManager.MenuScene);
        }

        if (!_startTimer.IsActive())
        {
            transparency += FrameworkData.DeltaTime;
            transparency = Math.Clamp(transparency / duration, 0f, 1f);
        }
    }

    public override void Draw()
    {
        if (_startTimer.IsActive())
        {
            return;   
        }

        var spriteBatch = FrameworkData.SpriteBatch;
        var center = GameEngineData.BaseBoxCenter;
        int cellSize = 20;
        int startX = center.X - cellSize*2;
        int startY = center.Y - cellSize * 2;

        int colorIndex = 1;

        for (int row = 0; row < 4; row++)
        {
            for (int col = 0; col < 4; col++)
            {
                Rectangle rect = new Rectangle(
                    startX + col * (cellSize),
                    startY + row * (cellSize),
                    cellSize,
                    cellSize
                );

                spriteBatch.DrawRectangle(rect, colorIndex, transparency);
                colorIndex++;
            }
        }
    }

    public override void Exit()
    {
    }

    public override void Enter()
    {
        _endTimer.Enable();
        _startTimer.Enable();
    }
}