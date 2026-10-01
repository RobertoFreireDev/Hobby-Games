using GameEngine.Elements.Managers;
using GameEngine.Enums;
using GameEngine.Utils;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Graphics;

namespace GameEngine.GameObjects.Managers;

public class StartManager : ISceneManager
{
    private SoundEffect _introSfx;
    private bool _isIntroSfxPlaying = false;
    private float _introSfxtimer = 2f;
    private float _timer;
    private TweenUtils _fadeOutTween;
    private const float _opaqueDefault = 1f;
    private float _opaque = _opaqueDefault;
    private float _freezeTime = 3f;
    private float _fadeoutTime = 3f;
    private int _imageNumber = 1;
    private Texture2D _textureSource;
    private Vector2 _screenPosition;
    private Rectangle _sourceRectangle;

    public StartManager()
    {
        _fadeOutTween = new TweenUtils(_opaqueDefault, 0f, _fadeoutTime, EasingFunctions.EaseInQuad);
    }

    public void LoadContent()
    {
        _introSfx = GlobalManager.Content.Load<SoundEffect>("Audio/intro");
        var texture = new GameEngine.Elements.Texture("intro", 40, 10, 10, 160, 80);
        _sourceRectangle = texture.GetRectangle(1);
        _textureSource = TextureManager.Texture2D[texture.TextureKey];    
        _screenPosition = new Vector2(GlobalManager.GraphicsDeviceManager.PreferredBackBufferWidth / 2 - 160, GlobalManager.GraphicsDeviceManager.PreferredBackBufferHeight / 2 - 80);
    }

    public void Update()
    {
        _timer += GlobalManager.DeltaTime;

        if (_imageNumber == 1)
        {
            firstImage();
        }
        else if (_imageNumber == 2)
        {
            LastImage();
        }
    }

    private void firstImage()
    {
        if (_timer > _introSfxtimer && !_isIntroSfxPlaying)
        {
            _introSfx.Play();
            _isIntroSfxPlaying = true;
        }

        if (_timer > _freezeTime)
        {
            if (_fadeOutTween.Active)
            {
                _opaque = _fadeOutTween.Update();
            }
        }

        if (_timer > _freezeTime + _fadeoutTime)
        {
            _timer = 0f;
            _imageNumber = 2; 
            _opaque = _opaqueDefault;
            _fadeOutTween.Reset();
        }
    }

    private void LastImage()
    {
        if (_timer > _freezeTime)
        {
            if (_fadeOutTween.Active)
            {
                _opaque = _fadeOutTween.Update();
            }
        }

        if (_fadeOutTween.IsComplete())
        {
            NextScreen();
        }
    }

    private void NextScreen()
    {
        GlobalManager.Scene = SceneEnum.MENU;
        _timer = 0f;
        _opaque = _opaqueDefault;
    }

    public void Draw()
    {
        var color = new Color(255, 0, 0, 255) * _opaque;
        var batch = SpriteManager.SpriteBatch;
        batch.Begin(samplerState: SamplerState.PointClamp);

        if (_imageNumber == 1)
        {
            DrawFirstImage(batch, color);
        }
        else if (_imageNumber == 2)
        {
            DrawLastImage(batch, color);
        }

        batch.End();
    }

    private void DrawFirstImage(SpriteBatch batch, Color color)
    {
        batch.Draw(
            _textureSource,
            _screenPosition,
            _sourceRectangle,
            color,
            0,
            new Vector2(1, 1),
            new Vector2(2, 2),
            SpriteEffects.None,
            0f
        );
    }

    private void DrawLastImage(SpriteBatch batch, Color color)
    {
        batch.DrawString(SpriteManager.Font, "PRIEST VS DEMONS", new Vector2(GlobalManager.GraphicsDeviceManager.PreferredBackBufferWidth / 2 - 50, GlobalManager.GraphicsDeviceManager.PreferredBackBufferHeight / 2 - 50), color);
        batch.DrawString(SpriteManager.Font, "BY ROBERTO FREIRE", new Vector2(GlobalManager.GraphicsDeviceManager.PreferredBackBufferWidth / 2 - 50, GlobalManager.GraphicsDeviceManager.PreferredBackBufferHeight / 2), color);
    }
}
